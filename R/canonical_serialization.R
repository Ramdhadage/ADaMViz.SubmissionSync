.canonicalize_value <- function(value) {
  if (is.list(value)) {
    value <- lapply(value, .canonicalize_value)
    if (!is.null(names(value))) {
      value <- value[order(names(value), method = "radix")]
    }
  }
  value
}

canonical_serialize <- function(value) {
  jsonlite::toJSON(
    .canonicalize_value(value),
    auto_unbox = TRUE,
    null = "null",
    digits = NA,
    pretty = FALSE
  )
}

canonical_hash <- function(value, algorithm = "sha256") {
  digest::digest(canonical_serialize(value), algo = algorithm, serialize = FALSE)
}
