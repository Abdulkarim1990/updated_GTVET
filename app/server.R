# =============================================================
# GTVET-IDMS  server.R
# IMPORTANT: This file must define `server` as its last (and only
# top-level) assignment so that source("server.R")$value returns
# the correct function regardless of Shiny version.
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
