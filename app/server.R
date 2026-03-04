# =============================================================
# GTVET-IDMS  server.R
# =============================================================

server <- function(input, output, session) {

  # ------ DB availability check ----------------------------
  if (is.null(pool)) {
    showModal(modalDialog(
      title = "Database Unavailable",
      "The application cannot connect to the database. Please contact your system administrator.",
      easyClose = FALSE,
      footer = NULL
    ))
    return()
  }

  # ------ Authentication -----------------------------------
  auth <- loginServer("auth", pool)

  # Show/hide app panels based on auth state
  observe({
    if (isTRUE(auth$logged_in)) {
      shinyjs::hide("app_login")
      shinyjs::show("app_main")
    } else {
      shinyjs::show("app_login")
      shinyjs::hide("app_main")
    }
  })

  # ------ Logout -------------------------------------------
  observeEvent(input$btn_logout, {
    log_action(pool, auth$user_id, "LOGOUT")
    auth$logged_in      <- FALSE
    auth$user_id        <- NA
    auth$username       <- NA
    auth$full_name      <- NA
    auth$role           <- NA
    auth$institution_id <- NA
    auth$region_id      <- NA
    # Clear all inputs so next user sees a clean form
    session$reload()
  })

  # ------ Header user info ----------------------------------
  output$header_user_info <- renderUI({
    req(auth$logged_in)
    role_label <- switch(auth$role,
      school_user       = "School User",
      regional_officer  = "Regional Officer",
      qa_officer        = "QA Officer",
      national_viewer   = "National Viewer",
      admin             = "Administrator",
      auth$role)
    tags$li(
      class = "dropdown",
      style = "padding:12px 15px; color:#fff;",
      icon("user-circle"),
      " ", strong(auth$full_name %||% auth$username),
      tags$small(paste0(" (", role_label, ")"))
    )
  })

  # ------ Admin sidebar items (role-gated) -----------------
  output$sidebar_admin_menu <- renderUI({
    req(auth$logged_in)
    if (auth$role != "admin") return(NULL)
    tagList(
      hr(),
      shinydashboard::menuItem("Admin — Users",
        tabName = "admin_users",  icon = icon("users-cog")),
      shinydashboard::menuItem("Admin — Windows",
        tabName = "admin_windows", icon = icon("calendar-alt")),
      shinydashboard::menuItem("Audit Log",
        tabName = "audit_log",    icon = icon("history"))
    )
  })

  # ------ Module servers -----------------------------------
  m1Server("m1_module", pool, auth)
  m2Server("m2_module", pool, auth)

  # ------ Home panel ---------------------------------------
  homeServer("home_panel", pool, auth)

  # ------ My Submissions panel -----------------------------
  mySubmissionsServer("my_subs", pool, auth)

}

# ------ Home server helpers ----------------------------------

homeServer <- function(id, pool, auth) {
  moduleServer(id, function(input, output, session) {

    output$welcome_msg <- renderUI({
      req(auth$logged_in)
      div(class = "page-header",
        h3(icon("home"), " Welcome, ", strong(auth$full_name %||% auth$username)),
        p(class = "text-muted",
          APP_CONFIG$app_title, " — Academic Year: ",
          strong(APP_CONFIG$current_ay))
      )
    })

    output$box_m1_status <- renderUI({
      req(auth$logged_in, auth$institution_id)
      sub <- db_query(pool,
        "SELECT status FROM submissions
         WHERE institution_id=$1 AND module_code='M1' AND academic_year=$2
         ORDER BY version DESC LIMIT 1",
        list(auth$institution_id, APP_CONFIG$current_ay))
      status <- if (nrow(sub) == 0) "Not started" else sub$status[1]
      colour <- switch(status,
        `Not started` = "yellow", Draft = "blue",
        Submitted = "orange", `Under Review` = "orange",
        Approved = "green", Returned = "red", "blue")
      shinydashboard::valueBox(
        value = status, subtitle = "M1 — Enrolment",
        icon = icon("users"), color = colour, width = 12)
    })

    output$box_m2_status <- renderUI({
      req(auth$logged_in, auth$institution_id)
      sub <- db_query(pool,
        "SELECT status FROM submissions
         WHERE institution_id=$1 AND module_code='M2' AND academic_year=$2
         ORDER BY version DESC LIMIT 1",
        list(auth$institution_id, APP_CONFIG$current_ay))
      status <- if (nrow(sub) == 0) "Not started" else sub$status[1]
      colour <- switch(status,
        `Not started`="yellow", Draft="blue",
        Submitted="orange", `Under Review`="orange",
        Approved="green", Returned="red", "blue")
      shinydashboard::valueBox(
        value = status, subtitle = "M2 — Staff & HR",
        icon = icon("chalkboard-teacher"), color = colour, width = 12)
    })

    output$box_window_status <- renderUI({
      today  <- Sys.Date()
      windows <- db_query(pool,
        "SELECT module_code, semester, open_date, close_date FROM submission_windows
         WHERE academic_year=$1 AND is_active=TRUE ORDER BY module_code, semester",
        list(APP_CONFIG$current_ay))
      if (nrow(windows) == 0) {
        return(div(class = "alert alert-warning",
                   "No submission windows are currently configured."))
      }
      rows <- lapply(seq_len(nrow(windows)), function(i) {
        w <- windows[i, ]
        is_open <- today >= w$open_date & today <= w$close_date
        tags$tr(
          tags$td(w$module_code),
          tags$td(paste("Semester", w$semester)),
          tags$td(format(w$open_date, "%d %b %Y")),
          tags$td(format(w$close_date, "%d %b %Y")),
          tags$td(
            if (is_open)
              span(class = "label label-success", "OPEN")
            else if (today < w$open_date)
              span(class = "label label-info", "Upcoming")
            else
              span(class = "label label-default", "Closed")
          )
        )
      })
      shinydashboard::box(
        title = "Submission Windows", status = "primary",
        solidHeader = TRUE, width = 12,
        tags$table(class = "table table-condensed table-striped",
          tags$thead(tags$tr(
            tags$th("Module"), tags$th("Period"),
            tags$th("Opens"), tags$th("Closes"), tags$th("Status")
          )),
          tags$tbody(rows)
        )
      )
    })
  })
}

# ------ My Submissions server --------------------------------

mySubmissionsServer <- function(id, pool, auth) {
  moduleServer(id, function(input, output, session) {

    output$submissions_table <- renderDT({
      req(auth$logged_in)

      query <- if (auth$role == "school_user") {
        list(
          "SELECT s.submission_id, s.module_code, s.academic_year, s.semester,
                  s.status, s.version,
                  TO_CHAR(s.submitted_at,'DD Mon YYYY HH24:MI') AS submitted_at,
                  TO_CHAR(s.approved_at, 'DD Mon YYYY HH24:MI') AS approved_at,
                  s.return_reason
           FROM submissions s
           WHERE s.institution_id=$1
           ORDER BY s.academic_year DESC, s.semester DESC, s.module_code",
          list(auth$institution_id))
      } else if (auth$role %in% c("regional_officer","qa_officer")) {
        list(
          "SELECT s.submission_id, i.institution_name, s.module_code,
                  s.academic_year, s.semester, s.status, s.version,
                  TO_CHAR(s.submitted_at,'DD Mon YYYY HH24:MI') AS submitted_at,
                  s.return_reason
           FROM submissions s
           JOIN institutions i ON i.institution_id = s.institution_id
           WHERE i.region_id=$1
           ORDER BY s.submitted_at DESC NULLS LAST",
          list(auth$region_id))
      } else {
        list(
          "SELECT s.submission_id, i.institution_name, r.region_name,
                  s.module_code, s.academic_year, s.semester,
                  s.status, s.version,
                  TO_CHAR(s.submitted_at,'DD Mon YYYY HH24:MI') AS submitted_at
           FROM submissions s
           JOIN institutions i ON i.institution_id = s.institution_id
           JOIN regions r ON r.region_id = i.region_id
           ORDER BY s.submitted_at DESC NULLS LAST LIMIT 500",
          list())
      }

      df <- db_query(pool, query[[1]], query[[2]])
      if (is.null(df) || nrow(df) == 0) {
        df <- data.frame(Message = "No submissions found.")
      }

      DT::datatable(
        df,
        rownames  = FALSE,
        selection = "single",
        options   = list(
          pageLength = 15,
          scrollX    = TRUE,
          dom        = "Bfrtip",
          buttons    = c("csv","excel")
        ),
        extensions = "Buttons",
        class = "table-striped table-hover"
      )
    }, server = FALSE)

    # ---- Regional officer: approve or return ----------------
    # (Shown only for regional/QA roles)
    observeEvent(input$submissions_table_rows_selected, {
      req(auth$role %in% c("regional_officer","qa_officer","admin"))
      # Future: open a modal with Approve / Return buttons
      # Deferred to workflow panel implementation
    })
  })
}
