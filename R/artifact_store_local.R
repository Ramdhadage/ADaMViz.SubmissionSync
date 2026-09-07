local_artifact_store <- function(root) {
  checkmate::assert_string(root, min.chars = 1)
  fs::dir_create(root, recurse = TRUE)
  root <- fs::path_abs(root)

  artifact_path <- function(hash) {
    .validate_artifact_hash(hash)
    fs::path(root, substr(hash, 1L, 2L), hash)
  }

  put <- function(bytes) {
    if (!is.raw(bytes)) {
      cli::cli_abort("Artifact content must be a raw vector")
    }
    hash <- digest::digest(bytes, algo = "sha256", serialize = FALSE)
    path <- artifact_path(hash)
    if (fs::file_exists(path)) {
      verify(hash)
    } else {
      fs::dir_create(fs::path_dir(path), recurse = TRUE)
      temporary <- fs::file_temp(tmp_dir = fs::path_dir(path), pattern = "artifact-")
      writeBin(bytes, temporary)
      if (!identical(digest::digest(file = temporary, algo = "sha256"), hash)) {
        fs::file_delete(temporary)
        cli::cli_abort("Artifact hash verification failed before publication")
      }
      if (!fs::file_exists(path)) {
        fs::file_move(temporary, path)
      } else {
        fs::file_delete(temporary)
      }
    }
    hash
  }

  get <- function(hash) {
    path <- artifact_path(hash)
    if (!fs::file_exists(path)) {
      cli::cli_abort("Artifact {.val {hash}} does not exist")
    }
    verify(hash)
    readBin(path, what = "raw", n = fs::file_size(path))
  }

  verify <- function(hash) {
    path <- artifact_path(hash)
    if (!fs::file_exists(path) ||
        !identical(digest::digest(file = path, algo = "sha256"), hash)) {
      cli::cli_abort("Artifact hash verification failed for {.val {hash}}")
    }
    TRUE
  }

  exists <- function(hash) unname(fs::file_exists(artifact_path(hash)))

  cleanup_orphans <- function(referenced_hashes, minimum_age_seconds) {
    if (!is.character(referenced_hashes)) {
      cli::cli_abort("Referenced artifact hashes must be a character vector")
    }
    if (length(referenced_hashes)) {
      invisible(lapply(referenced_hashes, .validate_artifact_hash))
    }
    files <- fs::dir_ls(root, recurse = TRUE, type = "file", fail = FALSE)
    relative <- fs::path_rel(files, start = root)
    components <- strsplit(relative, "[/\\\\]")
    is_artifact <- vapply(components, function(parts) {
      length(parts) == 2L &&
        grepl("^[0-9a-f]{2}$", parts[[1]]) &&
        grepl("^[0-9a-f]{64}$", parts[[2]]) &&
        identical(parts[[1]], substr(parts[[2]], 1L, 2L))
    }, logical(1))
    artifact_paths <- files[is_artifact]
    orphan_paths <- artifact_paths[
      !fs::path_file(artifact_paths) %in% referenced_hashes
    ]
    if (length(orphan_paths)) {
      age_seconds <- as.numeric(
        difftime(
          Sys.time(),
          fs::file_info(orphan_paths)$modification_time,
          units = "secs"
        )
      )
      orphan_paths <- orphan_paths[age_seconds >= minimum_age_seconds]
    }
    orphan_hashes <- fs::path_file(orphan_paths)
    if (length(orphan_paths)) fs::file_delete(orphan_paths)
    orphan_hashes
  }

  structure(
    list(
      root = fs::path_abs(root), put = put, get = get, verify = verify,
      exists = exists, path = artifact_path, .cleanup_orphans = cleanup_orphans
    ),
    class = "local_artifact_store"
  )
}
