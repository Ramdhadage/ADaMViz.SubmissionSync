local_workspace_provider <- function(destinations) {
  if (is.character(destinations)) {
    roots <- as.list(destinations)
  } else if (is.list(destinations)) {
    roots <- destinations
  } else {
    cli::cli_abort("{.arg destinations} must be a named character vector or list")
  }
  destination_ids <- names(roots)
  if (!length(destination_ids) ||
      any(!nzchar(destination_ids)) ||
      anyDuplicated(destination_ids)) {
    cli::cli_abort("Workspace destinations must have unique logical identifiers")
  }
  lapply(destination_ids, .validate_workspace_token, name = "destination_id")
  roots <- lapply(roots, function(root) {
    checkmate::assert_string(root, min.chars = 1L)
    if (!fs::dir_exists(root)) {
      cli::cli_abort("Workspace root {.path {root}} must already exist")
    }
    fs::path_abs(normalizePath(root, winslash = "/", mustWork = TRUE))
  })

  destination_root <- function(destination_id) {
    .validate_workspace_token(destination_id, "destination_id")
    root <- roots[[destination_id]]
    if (is.null(root)) {
      cli::cli_abort("Workspace destination {.val {destination_id}} is not registered")
    }
    .assert_supported_workspace_root(root)
    root
  }

  export_paths <- function(destination_id, export_id) {
    root <- destination_root(destination_id)
    .validate_workspace_token(export_id, "export_id")
    list(
      root = root,
      staging = fs::path(root, ".staging", export_id),
      final = fs::path(root, export_id),
      quarantine = fs::path(root, ".quarantine")
    )
  }

  stage_bundle <- function(destination_id, export_id, code_bytes, image_bytes) {
    if (!is.raw(code_bytes) || !is.raw(image_bytes)) {
      cli::cli_abort("Workspace bundles must be supplied as raw vectors")
    }
    paths <- export_paths(destination_id, export_id)
    if (fs::dir_exists(paths$staging) || fs::dir_exists(paths$final)) {
      cli::cli_abort("Workspace export {.val {export_id}} already exists")
    }
    fs::dir_create(paths$staging, recurse = TRUE)
    writeBin(code_bytes, fs::path(paths$staging, "script.R"))
    writeBin(image_bytes, fs::path(paths$staging, "plot.png"))
    hashes <- .workspace_pair_hashes(paths$staging)
    writeLines(
      canonical_serialize(list(
        destination_id = destination_id,
        export_id = export_id,
        code_hash = hashes$code_hash,
        image_hash = hashes$image_hash,
        staged_at = .utc_timestamp()
      )),
      fs::path(paths$staging, "manifest.json"),
      useBytes = TRUE
    )
    structure(
      c(paths, hashes, list(destination_id = destination_id, export_id = export_id)),
      class = "workspace_staged_export"
    )
  }

  publish_staged <- function(stage) {
    if (!inherits(stage, "workspace_staged_export")) {
      cli::cli_abort("{.arg stage} must be a staged workspace export")
    }
    paths <- export_paths(stage$destination_id, stage$export_id)
    if (!fs::dir_exists(paths$staging)) {
      cli::cli_abort("Staged workspace export {.val {stage$export_id}} is missing")
    }
    if (fs::dir_exists(paths$final)) {
      cli::cli_abort("Workspace export {.val {stage$export_id}} already exists")
    }
    hashes <- .workspace_pair_hashes(paths$staging)
    if (is.null(hashes) ||
        !identical(hashes$code_hash, stage$code_hash) ||
        !identical(hashes$image_hash, stage$image_hash)) {
      quarantine_staged(stage, "hash-mismatch")
      cli::cli_abort("Staged workspace export hashes changed before publication")
    }
    fs::file_delete(fs::path(paths$staging, "manifest.json"))
    fs::file_move(paths$staging, paths$final)
    published <- inspect_published(stage$destination_id, stage$export_id)
    if (is.null(published) ||
        !identical(published$code_hash, stage$code_hash) ||
        !identical(published$image_hash, stage$image_hash)) {
      cli::cli_abort("Published workspace export hashes do not match the staged bundle")
    }
    invisible(published)
  }

  inspect_published <- function(destination_id, export_id) {
    paths <- export_paths(destination_id, export_id)
    hashes <- .workspace_pair_hashes(paths$final)
    if (is.null(hashes)) return(NULL)
    c(
      list(
        destination_id = destination_id,
        export_id = export_id,
        path = paths$final,
        code_path = fs::path(paths$final, "script.R"),
        image_path = fs::path(paths$final, "plot.png")
      ),
      hashes
    )
  }

  quarantine_staged <- function(stage, reason = "orphaned") {
    if (!inherits(stage, "workspace_staged_export")) {
      cli::cli_abort("{.arg stage} must be a staged workspace export")
    }
    paths <- export_paths(stage$destination_id, stage$export_id)
    if (!fs::dir_exists(paths$staging)) return(invisible(NULL))
    fs::dir_create(paths$quarantine, recurse = TRUE)
    target <- fs::path(
      paths$quarantine,
      paste(
        stage$export_id,
        substr(canonical_hash(list(reason, .utc_timestamp())), 1L, 12L),
        sep = "-"
      )
    )
    fs::file_move(paths$staging, target)
    invisible(target)
  }

  reconcile <- function(destination_id) {
    root <- destination_root(destination_id)
    staging_root <- fs::path(root, ".staging")
    if (!fs::dir_exists(staging_root)) {
      return(data.frame(
        destination_id = character(),
        export_id = character(),
        action = character(),
        path = character()
      ))
    }
    staged <- fs::dir_ls(staging_root, type = "directory", fail = FALSE)
    results <- lapply(staged, function(path) {
      export_id <- fs::path_file(path)
      .validate_workspace_token(export_id, "export_id")
      stage <- structure(
        c(
          export_paths(destination_id, export_id),
          .workspace_pair_hashes(path) %||% list(code_hash = NA_character_, image_hash = NA_character_),
          list(destination_id = destination_id, export_id = export_id)
        ),
        class = "workspace_staged_export"
      )
      quarantine <- quarantine_staged(stage, "reconciled-orphan")
      data.frame(
        destination_id = destination_id,
        export_id = export_id,
        action = "quarantined",
        path = quarantine,
        stringsAsFactors = FALSE
      )
    })
    if (!length(results)) {
      return(data.frame(
        destination_id = character(),
        export_id = character(),
        action = character(),
        path = character()
      ))
    }
    do.call(rbind, results)
  }

  structure(
    list(
      destinations = roots,
      list_destinations = function() names(roots),
      stage_bundle = stage_bundle,
      publish_staged = publish_staged,
      inspect_published = inspect_published,
      quarantine_staged = quarantine_staged,
      reconcile = reconcile
    ),
    class = "local_workspace_provider"
  )
}

.assert_supported_workspace_root <- function(root) {
  if (isTRUE(fs::is_link(root))) {
    cli::cli_abort("Workspace roots cannot be symbolic links or reparse points")
  }
  invisible(root)
}
