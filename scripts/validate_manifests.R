script_argument <- grep(
  "^--file=",
  commandArgs(trailingOnly = FALSE),
  value = TRUE
)
script_path <- if (length(script_argument) == 1) {
  sub("^--file=", "", script_argument)
} else {
  file.path("scripts", "validate_manifests.R")
}
example_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)

if (!file.exists(file.path(example_root, "README.md"))) {
  example_root <- normalizePath(".", mustWork = TRUE)
}

assessment_years_root <- file.path(example_root, "assessment-years")
year_names <- list.files(assessment_years_root, pattern = "^[0-9]{4}$")
manifest_dirs <- file.path(assessment_years_root, year_names)
manifest_specs <- list(
  "data-manifest.csv" = c("data_id", "data_stream", "provenance_status", "source_link"),
  "run-manifest.csv" = c("run_id", "role", "author_status", "source_link"),
  "review-decisions.csv" = c("decision_id", "stage", "decision", "status"),
  "deliverables.csv" = c("deliverable_id", "description", "validation", "status")
)

failures <- character()

if (length(manifest_dirs) == 0) {
  failures <- c(failures, "No assessment-year directories found")
}

for (manifest_dir in manifest_dirs) {
  year_name <- basename(manifest_dir)
  for (manifest_name in names(manifest_specs)) {
    manifest_path <- file.path(manifest_dir, manifest_name)
    if (!file.exists(manifest_path)) {
      failures <- c(failures, paste(year_name, "missing", manifest_name))
      next
    }

    manifest <- read.csv(manifest_path, check.names = FALSE, na.strings = "")
    missing_columns <- setdiff(manifest_specs[[manifest_name]], names(manifest))
    if (length(missing_columns) > 0) {
      failures <- c(
        failures,
        paste(
          year_name,
          manifest_name,
          "missing columns",
          paste(missing_columns, collapse = ", ")
        )
      )
    }

    first_column <- names(manifest)[1]
    if (anyNA(manifest[[first_column]]) || any(manifest[[first_column]] == "")) {
      failures <- c(failures, paste(year_name, manifest_name, "has a blank identifier"))
    }
    if (anyDuplicated(manifest[[first_column]]) > 0) {
      failures <- c(failures, paste(year_name, manifest_name, "has duplicate identifiers"))
    }
  }

  assessment_path <- file.path(manifest_dir, "assessment.yml")
  if (!file.exists(assessment_path)) {
    failures <- c(failures, paste(year_name, "missing assessment.yml"))
  }
}

if (length(failures) > 0) {
  stop(paste(failures, collapse = "\n"), call. = FALSE)
}

message("Manifest structure is valid for: ", paste(year_names, collapse = ", "), ".")
message("Note: TO_CONFIRM and incomplete entries are intentional succession gaps.")
