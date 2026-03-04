# =============================================================
# GTVET-IDMS  Module M2 — Staff & HR
# Maps to: Staff (Teaching) and Staff (Non-Teaching) sheets
# =============================================================

# ------ UI ---------------------------------------------------

m2UI <- function(id) {
  ns <- NS(id)
  tagList(
    h2("Module M2 — Staff & HR"),
    p(class = "text-muted",
      "Enter teaching and non-teaching staff details. Save draft at any time."),

    fluidRow(
      column(3, selectInput(ns("sel_semester"), "Semester",
                            choices = c("Semester 1" = 1, "Semester 2" = 2))),
      column(3, uiOutput(ns("academic_year_display"))),
      column(6, uiOutput(ns("submission_status_banner")))
    ),

    tabsetPanel(
      id = ns("m2_tabs"),

      # ---- Tab 1: Teaching Staff ----------------------------
      tabPanel("Teaching Staff",
        br(),
        p("Enter one row per teaching staff member.",
          class = "text-muted"),
        fluidRow(
          column(3,
            actionButton(ns("teach_add_row"), "Add Staff Row",
                         icon = icon("plus"), class = "btn-info btn-sm")
          )
        ),
        br(),
        uiOutput(ns("teaching_rows_ui")),
        br(),
        uiOutput(ns("teaching_summary"))
      ),

      # ---- Tab 2: Non-Teaching Staff -------------------------
      tabPanel("Non-Teaching Staff",
        br(),
        p("Enter one row per non-teaching staff member.",
          class = "text-muted"),
        fluidRow(
          column(3,
            actionButton(ns("nonteach_add_row"), "Add Staff Row",
                         icon = icon("plus"), class = "btn-info btn-sm")
          )
        ),
        br(),
        uiOutput(ns("nonteaching_rows_ui")),
        br(),
        uiOutput(ns("nonteaching_summary"))
      )
    ),

    hr(),
    fluidRow(
      column(12,
        uiOutput(ns("validation_messages")),
        div(
          style = "display:flex; gap:10px;",
          actionButton(ns("btn_save_draft"), "Save Draft",
                       icon = icon("save"), class = "btn btn-default"),
          actionButton(ns("btn_submit"),     "Submit for Review",
                       icon = icon("paper-plane"), class = "btn btn-success"),
          uiOutput(ns("save_feedback"))
        )
      )
    )
  )
}

# ------ Server -----------------------------------------------

m2Server <- function(id, pool, auth) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    current_submission <- reactiveVal(NULL)
    teaching_rows    <- reactiveVal(1L)
    nonteaching_rows <- reactiveVal(1L)

    # ---- Academic year display --------------------------------
    output$academic_year_display <- renderUI({
      div(class = "form-group",
        tags$label("Academic Year"),
        div(class = "form-control-static", strong(APP_CONFIG$current_ay))
      )
    })

    # ---- Submission status banner -----------------------------
    output$submission_status_banner <- renderUI({
      sub <- current_submission()
      if (is.null(sub)) {
        div(class = "alert alert-info",
            icon("info-circle"),
            " No submission yet for this period.")
      } else {
        status_class <- switch(sub$status,
          Draft="info", Submitted="warning",
          `Under Review`="warning", Approved="success", Returned="danger", "info")
        div(class = paste0("alert alert-", status_class),
            icon("circle"), " Status: ", strong(sub$status),
            if (!is.null(sub$version) && sub$version > 1)
              span(class = "badge", paste("v", sub$version)))
      }
    })

    observeEvent(list(input$sel_semester, auth$institution_id), {
      req(auth$logged_in, auth$institution_id)
      sub <- get_active_submission(
        pool, auth$institution_id, "M2",
        APP_CONFIG$current_ay, input$sel_semester)
      current_submission(sub)
      if (!is.null(sub)) load_m2_data(sub$submission_id)
    })

    # ---- Teaching staff rows ---------------------------------
    output$teaching_rows_ui <- renderUI({
      n <- teaching_rows()
      inst_progs <- load_institution_programmes(pool, auth$institution_id)
      prog_choices_inst <- c("Other" = 0,
        setNames(inst_progs$programme_id,
                 paste0("[", inst_progs$programme_code, "] ", inst_progs$programme_name)))

      header <- fluidRow(
        column(2, tags$b("Full Name")),
        column(1, tags$b("Staff ID")),
        column(1, tags$b("Gender")),
        column(2, tags$b("Programme")),
        column(2, tags$b("Rank")),
        column(1, tags$b("Yr. Employed")),
        column(2, tags$b("Academic Qual.")),
        column(1, tags$b("Study Leave?"))
      )

      rows <- lapply(seq_len(n), function(i) {
        fluidRow(class = "staff-row",
          column(2, textInput(  ns(paste0("t_name_",  i)), NULL, placeholder="Full name",  width="100%")),
          column(1, textInput(  ns(paste0("t_id_",    i)), NULL, placeholder="Staff ID",   width="100%")),
          column(1, selectInput(ns(paste0("t_gender_",i)), NULL,
                                choices = c("","Male","Female"),                             width="100%")),
          column(2, selectInput(ns(paste0("t_prog_",  i)), NULL,
                                choices = prog_choices_inst,                                 width="100%")),
          column(2, textInput(  ns(paste0("t_rank_",  i)), NULL, placeholder="e.g. Senior Instructor", width="100%")),
          column(1, numericInput(ns(paste0("t_yr_",   i)), NULL, value=NULL,
                                 min=1960, max=as.integer(format(Sys.Date(),"%Y")),          width="100%")),
          column(2, textInput(  ns(paste0("t_aqal_",  i)), NULL, placeholder="e.g. BSc Education",    width="100%")),
          column(1, div(
            checkboxInput(ns(paste0("t_sl_",   i)), "On study leave", value=FALSE),
            conditionalPanel(
              paste0("input['", ns(paste0("t_sl_", i)), "']"),
              textInput(ns(paste0("t_sl_prog_", i)), NULL, placeholder="Programme studying",
                        width="100%")
            )
          ))
        )
      })
      tagList(header, rows)
    })

    observeEvent(input$teach_add_row, { teaching_rows(teaching_rows() + 1L) })

    # ---- Teaching summary counts -----------------------------
    output$teaching_summary <- renderUI({
      n <- teaching_rows()
      total <- sum(vapply(seq_len(n), function(i) {
        nm <- trimws(input[[paste0("t_name_", i)]] %||% "")
        if (nchar(nm) > 0) 1L else 0L
      }, integer(1)))
      male   <- sum(vapply(seq_len(n), function(i) {
        if ((input[[paste0("t_gender_", i)]] %||% "") == "Male") 1L else 0L
      }, integer(1)))
      female <- total - male
      div(class = "well",
        fluidRow(
          column(3, div(class="kpi-box", strong(total),  br(), "Total Teaching Staff")),
          column(3, div(class="kpi-box", strong(male),   br(), "Male")),
          column(3, div(class="kpi-box", strong(female), br(), "Female")),
          column(3, div(class="kpi-box",
            strong(sum(vapply(seq_len(n), function(i) {
              if (isTRUE(input[[paste0("t_sl_", i)]])) 1L else 0L
            }, integer(1)))),
            br(), "On Study Leave"))
        )
      )
    })

    # ---- Non-teaching staff rows -----------------------------
    output$nonteaching_rows_ui <- renderUI({
      n <- nonteaching_rows()
      header <- fluidRow(
        column(2, tags$b("Full Name")),
        column(1, tags$b("Staff ID")),
        column(1, tags$b("Gender")),
        column(2, tags$b("Role")),
        column(2, tags$b("Rank")),
        column(1, tags$b("Yr. Employed")),
        column(2, tags$b("Academic Qual.")),
        column(1, tags$b("Study Leave?"))
      )
      rows <- lapply(seq_len(n), function(i) {
        fluidRow(class = "staff-row",
          column(2, textInput(  ns(paste0("nt_name_",  i)), NULL, placeholder="Full name",  width="100%")),
          column(1, textInput(  ns(paste0("nt_id_",    i)), NULL, placeholder="Staff ID",   width="100%")),
          column(1, selectInput(ns(paste0("nt_gender_",i)), NULL,
                                choices = c("","Male","Female"),                             width="100%")),
          column(2, textInput(  ns(paste0("nt_role_",  i)), NULL,
                                placeholder="e.g. Principal, Secretary",                    width="100%")),
          column(2, textInput(  ns(paste0("nt_rank_",  i)), NULL, placeholder="Rank",       width="100%")),
          column(1, numericInput(ns(paste0("nt_yr_",   i)), NULL, value=NULL,
                                 min=1960, max=as.integer(format(Sys.Date(),"%Y")),          width="100%")),
          column(2, textInput(  ns(paste0("nt_aqal_",  i)), NULL, placeholder="Qualification", width="100%")),
          column(1, checkboxInput(ns(paste0("nt_sl_",  i)), "Study leave", value=FALSE))
        )
      })
      tagList(header, rows)
    })

    observeEvent(input$nonteach_add_row, { nonteaching_rows(nonteaching_rows() + 1L) })

    output$nonteaching_summary <- renderUI({
      n <- nonteaching_rows()
      total <- sum(vapply(seq_len(n), function(i) {
        if (nchar(trimws(input[[paste0("nt_name_", i)]] %||% "")) > 0) 1L else 0L
      }, integer(1)))
      div(class = "well",
        fluidRow(
          column(4, div(class="kpi-box", strong(total), br(), "Total Non-Teaching Staff"))
        )
      )
    })

    # ---- Validate -------------------------------------------
    run_m2_validation <- function() {
      errors <- character(0)
      n <- teaching_rows()
      # At least one teaching staff
      names_filled <- sum(vapply(seq_len(n), function(i) {
        if (nchar(trimws(input[[paste0("t_name_", i)]] %||% "")) > 0) 1L else 0L
      }, integer(1)))
      if (names_filled == 0)
        errors <- c(errors, "At least one teaching staff member must be entered.")
      errors
    }

    # ---- Save draft -----------------------------------------
    observeEvent(input$btn_save_draft, {
      req(auth$logged_in, auth$institution_id)
      errors <- run_m2_validation()
      if (length(errors) > 0) {
        output$validation_messages <- renderUI({
          div(class = "alert alert-warning",
              h5(icon("exclamation-triangle"), " Please fix:"),
              tags$ul(lapply(errors, tags$li)))
        })
        return()
      }
      withProgress(message = "Saving M2 draft...", {
        sub_id <- save_m2_draft(pool, auth, input, current_submission(),
                                teaching_rows(), nonteaching_rows())
        if (!is.na(sub_id)) {
          current_submission(list(submission_id=sub_id, status="Draft", version=1))
          output$save_feedback <- renderUI(
            div(class="alert alert-success", icon("check"), " M2 draft saved."))
          output$validation_messages <- renderUI(NULL)
          log_action(pool, auth$user_id, "M2_SAVE_DRAFT", "submissions", sub_id)
        } else {
          output$save_feedback <- renderUI(
            div(class="alert alert-danger", icon("times"), " Save failed."))
        }
      })
    })

    # ---- Submit ---------------------------------------------
    observeEvent(input$btn_submit, {
      req(auth$logged_in, auth$institution_id)
      errors <- run_m2_validation()
      if (!is_window_open(pool, "M2", APP_CONFIG$current_ay, as.integer(input$sel_semester)))
        errors <- c(errors, "The M2 submission window is not currently open.")
      if (length(errors) > 0) {
        output$validation_messages <- renderUI({
          div(class="alert alert-danger",
              tags$ul(lapply(errors, tags$li)))
        })
        return()
      }
      withProgress(message = "Submitting M2...", {
        sub_id <- save_m2_draft(pool, auth, input, current_submission(),
                                teaching_rows(), nonteaching_rows())
        if (!is.na(sub_id)) {
          db_execute(pool,
            "UPDATE submissions SET status='Submitted',submitted_by=$1,submitted_at=NOW()
             WHERE submission_id=$2",
            list(auth$user_id, sub_id))
          current_submission(list(submission_id=sub_id, status="Submitted", version=1))
          output$save_feedback <- renderUI(
            div(class="alert alert-success", icon("check-circle"), " M2 submitted."))
          log_action(pool, auth$user_id, "M2_SUBMIT", "submissions", sub_id)
        }
      })
    })

    # ---- Persist to DB --------------------------------------
    save_m2_draft <- function(pool, auth, input, existing_sub, n_teach, n_nonteach) {
      tryCatch({
        con <- pool::poolCheckout(pool)
        on.exit(pool::poolReturn(con))
        DBI::dbBegin(con)

        semester <- as.integer(input$sel_semester)

        if (is.null(existing_sub)) {
          sub_id <- DBI::dbGetQuery(con,
            "INSERT INTO submissions
               (institution_id,module_code,academic_year,semester,status)
             VALUES ($1,'M2',$2,$3,'Draft') RETURNING submission_id",
            params = list(auth$institution_id, APP_CONFIG$current_ay, semester))[[1]]
        } else {
          sub_id <- existing_sub$submission_id
          DBI::dbExecute(con,
            "UPDATE submissions SET updated_at=NOW() WHERE submission_id=$1",
            params = list(sub_id))
        }

        # Teaching staff: delete + re-insert
        DBI::dbExecute(con,
          "DELETE FROM m2_staff_teaching WHERE submission_id=$1", list(sub_id))
        for (i in seq_len(n_teach)) {
          nm <- trimws(input[[paste0("t_name_", i)]] %||% "")
          if (nchar(nm) == 0) next
          prog_id <- as.integer(input[[paste0("t_prog_", i)]])
          DBI::dbExecute(con,
            "INSERT INTO m2_staff_teaching
               (submission_id,full_name,staff_number,gender,programme_id,
                current_rank,year_employed,academic_qualification,
                on_study_leave,study_leave_programme)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)",
            params = list(
              sub_id, nm,
              input[[paste0("t_id_",    i)]] %||% NA_character_,
              input[[paste0("t_gender_",i)]] %||% NA_character_,
              if (prog_id == 0) NA_integer_ else prog_id,
              input[[paste0("t_rank_",  i)]] %||% NA_character_,
              as.integer(input[[paste0("t_yr_",  i)]]) %||% NA_integer_,
              input[[paste0("t_aqal_",  i)]] %||% NA_character_,
              isTRUE(input[[paste0("t_sl_",    i)]]),
              input[[paste0("t_sl_prog_",i)]] %||% NA_character_
            ))
        }

        # Non-teaching staff: delete + re-insert
        DBI::dbExecute(con,
          "DELETE FROM m2_staff_nonteaching WHERE submission_id=$1", list(sub_id))
        for (i in seq_len(n_nonteach)) {
          nm <- trimws(input[[paste0("nt_name_", i)]] %||% "")
          if (nchar(nm) == 0) next
          DBI::dbExecute(con,
            "INSERT INTO m2_staff_nonteaching
               (submission_id,full_name,staff_number,gender,assigned_role,
                current_rank,year_employed,academic_qualification,
                on_study_leave)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)",
            params = list(
              sub_id, nm,
              input[[paste0("nt_id_",    i)]] %||% NA_character_,
              input[[paste0("nt_gender_",i)]] %||% NA_character_,
              input[[paste0("nt_role_",  i)]] %||% NA_character_,
              input[[paste0("nt_rank_",  i)]] %||% NA_character_,
              as.integer(input[[paste0("nt_yr_", i)]]) %||% NA_integer_,
              input[[paste0("nt_aqal_",  i)]] %||% NA_character_,
              isTRUE(input[[paste0("nt_sl_", i)]])
            ))
        }

        DBI::dbCommit(con)
        sub_id

      }, error = function(e) {
        tryCatch(DBI::dbRollback(con), error=function(e2) NULL)
        message("[save_m2_draft] ERROR: ", conditionMessage(e))
        NA_integer_
      })
    }

    # ---- Load saved data ------------------------------------
    load_m2_data <- function(sub_id) {
      teach <- db_query(pool,
        "SELECT * FROM m2_staff_teaching WHERE submission_id=$1 ORDER BY staff_id",
        list(sub_id))
      if (nrow(teach) > 0) {
        teaching_rows(nrow(teach))
        # Individual field updates triggered by re-render
      }
      nonteach <- db_query(pool,
        "SELECT * FROM m2_staff_nonteaching WHERE submission_id=$1 ORDER BY staff_id",
        list(sub_id))
      if (nrow(nonteach) > 0) nonteaching_rows(nrow(nonteach))
    }

  })  # moduleServer
}
