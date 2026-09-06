#' Return the application Bootstrap theme.
#'
#' Keeping the theme in one function makes the visual contract explicit and
#' gives later modules one stable place to extend application branding.
#'
#' @return A pinned Bootstrap 5 bslib theme.
#' @noRd
app_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = "#0B3C5D",
    secondary = "#5B6770",
    success = "#1B6E3A",
    base_font = bslib::font_collection(
      "Inter",
      "Segoe UI",
      "Arial",
      "sans-serif"
    ),
    heading_font = bslib::font_collection(
      "Inter",
      "Segoe UI",
      "Arial",
      "sans-serif"
    )
  )
}
