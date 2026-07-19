required_packages <- c("shiny", "DT")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  message("Installing local data-entry dependencies: ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_argument) == 1L) {
  sub("^--file=", "", script_argument)
} else {
  file.path("tools", "data-entry", "run.R")
}
app_dir <- normalizePath(dirname(script_path), mustWork = TRUE)
shiny::runApp(app_dir, host = "127.0.0.1", launch.browser = TRUE)
