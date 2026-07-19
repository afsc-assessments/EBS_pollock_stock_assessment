required_packages <- c("shiny", "DT")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop(
    "Install the local editor dependencies first: install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    "))",
    call. = FALSE
  )
}

library(shiny)

repo_root <- normalizePath(file.path(getwd(), "..", ".."), mustWork = TRUE)
year_dir <- file.path(repo_root, "assessment-years", "2026")
backup_root <- file.path(repo_root, "uncommitted", "data-entry-backups")

trackers <- list(
  schedule = list(
    label = "Schedule",
    file = "schedule.csv",
    id = "milestone",
    status = c("active", "planned", "complete")
  ),
  data = list(
    label = "Data readiness",
    file = "data-manifest.csv",
    id = "data_id",
    status = c(
      "pending", "candidate_available", "validated", "carried_forward",
      "excluded"
    )
  ),
  runs = list(
    label = "Model runs",
    file = "run-manifest.csv",
    id = "run_id",
    status = c("not_started", "planned", "working", "complete", "accepted")
  ),
  review = list(
    label = "Review decisions",
    file = "review-decisions.csv",
    id = "decision_id",
    status = c(
      "not_started", "planned", "incomplete", "working", "complete",
      "final", "ssc_accepted"
    )
  ),
  deliverables = list(
    label = "Deliverables",
    file = "deliverables.csv",
    id = "deliverable_id",
    status = c(
      "not_started", "planned", "incomplete", "working", "complete", "final"
    )
  )
)

tracker_path <- function(key) file.path(year_dir, trackers[[key]]$file)

read_tracker <- function(key) {
  read.csv(
    tracker_path(key),
    check.names = FALSE,
    stringsAsFactors = FALSE,
    na.strings = character()
  )
}

same_value <- function(x, y) {
  x <- ifelse(is.na(x), "", as.character(x))
  y <- ifelse(is.na(y), "", as.character(y))
  identical(x, y)
}

table_changed <- function(x, y) {
  !identical(names(x), names(y)) || nrow(x) != nrow(y) ||
    any(!vapply(seq_along(x), function(i) same_value(x[[i]], y[[i]]), logical(1)))
}

validate_tables <- function(values) {
  errors <- character()
  warnings <- character()

  for (key in names(trackers)) {
    x <- values[[key]]
    original_columns <- names(read_tracker(key))
    id_column <- trackers[[key]]$id

    if (!identical(names(x), original_columns)) {
      errors <- c(errors, paste(trackers[[key]]$label, "has changed columns."))
      next
    }
    ids <- trimws(ifelse(is.na(x[[id_column]]), "", as.character(x[[id_column]])))
    if (any(ids == "")) {
      errors <- c(errors, paste(trackers[[key]]$label, "has a blank identifier."))
    }
    if (anyDuplicated(ids)) {
      errors <- c(errors, paste(trackers[[key]]$label, "has duplicate identifiers."))
    }

    status_column <- if (key == "data") "availability_status" else
      if (key == "runs") "author_status" else "status"
    statuses <- trimws(ifelse(is.na(x[[status_column]]), "", x[[status_column]]))
    unexpected <- setdiff(unique(statuses[statuses != ""]), trackers[[key]]$status)
    if (length(unexpected) > 0) {
      warnings <- c(
        warnings,
        paste0(
          trackers[[key]]$label, " uses unrecognized status value(s): ",
          paste(unexpected, collapse = ", "), "."
        )
      )
    }
  }

  list(errors = errors, warnings = warnings)
}

tracker_panel <- function(key) {
  spec <- trackers[[key]]
  tabPanel(
    spec$label,
    fluidRow(
      column(
        12,
        wellPanel(
          tags$strong("Status values: "),
          paste(spec$status, collapse = ", "),
          tags$br(),
          tags$small("Double-click a cell to edit it. Changes stay in memory until Save all changes is pressed.")
        ),
        actionButton(paste0(key, "_add"), "Add row", icon = icon("plus")),
        actionButton(paste0(key, "_delete"), "Delete selected row", icon = icon("trash")),
        actionButton(paste0(key, "_reset"), "Reset this tab", icon = icon("rotate-left")),
        br(), br(),
        DT::DTOutput(paste0(key, "_table"))
      )
    )
  )
}

ui <- fluidPage(
  tags$head(
    tags$style(HTML(
      ".container-fluid { max-width: 1800px; } .btn { margin-right: 6px; }\n       .dataTables_wrapper { overflow-x: auto; } .status-box { margin-top: 12px; }"
    ))
  ),
  titlePanel("2026 EBS pollock assessment — local data entry"),
  p(
    class = "lead",
    "This app edits the CSV trackers in assessment-years/2026. It runs only on this computer; the GitHub Pages dashboard remains read-only."
  ),
  fluidRow(
    column(
      12,
      actionButton("validate", "Validate", class = "btn-info", icon = icon("check")),
      actionButton("save", "Save all changes", class = "btn-primary", icon = icon("floppy-disk")),
      actionButton("render", "Render local dashboard", class = "btn-success", icon = icon("chart-line")),
      tags$span(style = "margin-left: 12px;", textOutput("unsaved", inline = TRUE))
    )
  ),
  div(class = "status-box", uiOutput("message")),
  tabsetPanel(
    id = "tabs",
    tracker_panel("schedule"),
    tracker_panel("data"),
    tracker_panel("runs"),
    tracker_panel("review"),
    tracker_panel("deliverables"),
    tabPanel(
      "Changes",
      h3("Unsaved change summary"),
      DT::DTOutput("changes_table"),
      h3("Recent command output"),
      verbatimTextOutput("command_output")
    ),
    tabPanel(
      "Help",
      h3("Safe workflow"),
      tags$ol(
        tags$li("Edit cells or add and delete rows."),
        tags$li("Select Validate and resolve errors. New status words are shown as warnings."),
        tags$li("Select Save all changes. A timestamped backup is made under uncommitted/data-entry-backups/."),
        tags$li("Optionally render the local dashboard and inspect it."),
        tags$li("Review git diff, then commit and push when the records are ready to publish.")
      ),
      tags$p(
        tags$strong("Restricted information: "),
        "Do not enter confidential values or paths that should not become public. Saved tracker content is publishable if committed and pushed."
      )
    )
  )
)

server <- function(input, output, session) {
  values <- reactiveValues()
  originals <- reactiveValues()
  loaded_md5 <- reactiveValues()
  change_tick <- reactiveVal(0L)
  message_state <- reactiveVal(list(type = "info", text = "No files have been changed."))
  command_state <- reactiveVal("")

  for (key in names(trackers)) {
    loaded_table <- read_tracker(key)
    values[[key]] <- loaded_table
    originals[[key]] <- loaded_table
    loaded_md5[[key]] <- unname(tools::md5sum(tracker_path(key)))
  }

  current_values <- function() {
    setNames(lapply(names(trackers), function(key) values[[key]]), names(trackers))
  }

  change_summary <- reactive({
    change_tick()
    rows <- lapply(names(trackers), function(key) {
      old <- originals[[key]]
      new <- values[[key]]
      id <- trackers[[key]]$id
      old_ids <- if (id %in% names(old)) as.character(old[[id]]) else character()
      new_ids <- if (id %in% names(new)) as.character(new[[id]]) else character()
      common <- intersect(old_ids, new_ids)
      changed_cells <- 0L
      if (length(common) > 0 && identical(names(old), names(new))) {
        for (row_id in common) {
          old_row <- old[match(row_id, old_ids), , drop = FALSE]
          new_row <- new[match(row_id, new_ids), , drop = FALSE]
          changed_cells <- changed_cells + sum(vapply(
            names(old),
            function(column) !same_value(old_row[[column]], new_row[[column]]),
            logical(1)
          ))
        }
      }
      data.frame(
        Tracker = trackers[[key]]$label,
        Added = length(setdiff(new_ids, old_ids)),
        Deleted = length(setdiff(old_ids, new_ids)),
        `Edited cells` = changed_cells,
        check.names = FALSE
      )
    })
    do.call(rbind, rows)
  })

  has_changes <- reactive(any(rowSums(change_summary()[, -1, drop = FALSE]) > 0))

  output$unsaved <- renderText({
    if (has_changes()) "Unsaved changes are present." else "No unsaved changes."
  })

  output$changes_table <- DT::renderDT({
    DT::datatable(change_summary(), rownames = FALSE, options = list(dom = "t", paging = FALSE))
  })

  output$message <- renderUI({
    state <- message_state()
    class <- switch(
      state$type,
      success = "alert alert-success",
      warning = "alert alert-warning",
      danger = "alert alert-danger",
      "alert alert-info"
    )
    div(class = class, state$text)
  })

  output$command_output <- renderText(command_state())

  for (key in names(trackers)) {
    local({
      tracker_key <- key
      table_id <- paste0(tracker_key, "_table")

      output[[table_id]] <- DT::renderDT({
        change_tick()
        DT::datatable(
          values[[tracker_key]],
          rownames = FALSE,
          selection = "single",
          editable = "cell",
          options = list(pageLength = 15, scrollX = TRUE, autoWidth = TRUE)
        )
      }, server = FALSE)

      observeEvent(input[[paste0(table_id, "_cell_edit")]], {
        edit <- input[[paste0(table_id, "_cell_edit")]]
        values[[tracker_key]] <- DT::editData(
          values[[tracker_key]], edit, rownames = FALSE
        )
        change_tick(change_tick() + 1L)
      })

      observeEvent(input[[paste0(tracker_key, "_add")]], {
        x <- values[[tracker_key]]
        blank <- as.data.frame(
          setNames(lapply(x, function(column) if (is.numeric(column)) NA_real_ else ""), names(x)),
          stringsAsFactors = FALSE
        )
        values[[tracker_key]] <- rbind(x, blank)
        change_tick(change_tick() + 1L)
      })

      observeEvent(input[[paste0(tracker_key, "_delete")]], {
        selected <- input[[paste0(table_id, "_rows_selected")]]
        if (length(selected) != 1L) {
          showNotification("Select one row in the table first.", type = "warning")
          return()
        }
        values[[tracker_key]] <- values[[tracker_key]][-selected, , drop = FALSE]
        change_tick(change_tick() + 1L)
      })

      observeEvent(input[[paste0(tracker_key, "_reset")]], {
        values[[tracker_key]] <- originals[[tracker_key]]
        change_tick(change_tick() + 1L)
        message_state(list(type = "info", text = paste(trackers[[tracker_key]]$label, "was reset to its last saved state.")))
      })
    })
  }

  observeEvent(input$validate, {
    result <- validate_tables(current_values())
    if (length(result$errors) > 0) {
      message_state(list(type = "danger", text = paste(result$errors, collapse = " ")))
    } else if (length(result$warnings) > 0) {
      message_state(list(type = "warning", text = paste("Validation passed with warnings:", paste(result$warnings, collapse = " "))))
    } else {
      message_state(list(type = "success", text = "Validation passed. Identifiers, columns, and status values look consistent."))
    }
  })

  observeEvent(input$save, {
    if (!has_changes()) {
      message_state(list(type = "info", text = "There are no changes to save."))
      return()
    }

    result <- validate_tables(current_values())
    if (length(result$errors) > 0) {
      message_state(list(type = "danger", text = paste("Save stopped:", paste(result$errors, collapse = " "))))
      return()
    }

    externally_changed <- names(trackers)[vapply(names(trackers), function(key) {
      !identical(unname(tools::md5sum(tracker_path(key))), loaded_md5[[key]])
    }, logical(1))]
    if (length(externally_changed) > 0) {
      message_state(list(
        type = "danger",
        text = paste("Save stopped because files changed outside the app:", paste(externally_changed, collapse = ", "), ". Restart the app to reload them.")
      ))
      return()
    }

    changed_keys <- names(trackers)[vapply(names(trackers), function(key) {
      table_changed(originals[[key]], values[[key]])
    }, logical(1))]
    stamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
    backup_dir <- file.path(backup_root, stamp)
    dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(vapply(changed_keys, tracker_path, character(1)), backup_dir, overwrite = TRUE)

    for (key in changed_keys) {
      write.csv(values[[key]], tracker_path(key), row.names = FALSE, na = "", quote = TRUE)
    }

    validation_output <- system2(
      file.path(R.home("bin"), "Rscript"),
      file.path(repo_root, "scripts", "validate_manifests.R"),
      stdout = TRUE,
      stderr = TRUE
    )
    validation_status <- attr(validation_output, "status")
    if (is.null(validation_status)) validation_status <- 0L
    command_state(paste(validation_output, collapse = "\n"))

    if (validation_status != 0L) {
      file.copy(file.path(backup_dir, basename(vapply(changed_keys, tracker_path, character(1)))), year_dir, overwrite = TRUE)
      for (key in changed_keys) values[[key]] <- read_tracker(key)
      change_tick(change_tick() + 1L)
      message_state(list(type = "danger", text = "Repository validation failed. The original files were restored; see Changes for command output."))
      return()
    }

    for (key in changed_keys) {
      originals[[key]] <- values[[key]]
      loaded_md5[[key]] <- unname(tools::md5sum(tracker_path(key)))
    }
    change_tick(change_tick() + 1L)
    warning_text <- if (length(result$warnings) > 0) paste(" Warnings:", paste(result$warnings, collapse = " ")) else ""
    message_state(list(
      type = if (length(result$warnings) > 0) "warning" else "success",
      text = paste0("Saved ", length(changed_keys), " tracker(s). Backup: ", backup_dir, ".", warning_text)
    ))
  })

  observeEvent(input$render, {
    output_lines <- system2(
      "quarto",
      c("render", file.path(year_dir, "dashboard.qmd")),
      stdout = TRUE,
      stderr = TRUE
    )
    render_status <- attr(output_lines, "status")
    if (is.null(render_status)) render_status <- 0L
    command_state(paste(output_lines, collapse = "\n"))
    if (render_status == 0L) {
      message_state(list(type = "success", text = "Local dashboard rendered successfully under _site/assessment-years/2026/."))
    } else {
      message_state(list(type = "danger", text = "Dashboard render failed. See Changes for command output."))
    }
  })
}

shinyApp(ui, server)
