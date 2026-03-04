# =============================================================
# GTVET-IDMS  Authentication Module
# =============================================================
# Provides: loginUI(), loginServer()
# loginServer returns a reactive list:
#   $user_id, $username, $full_name, $role,
#   $institution_id, $region_id, $logged_in (TRUE/FALSE)
# =============================================================

library(shiny)
library(shinyjs)

# ------ UI ---------------------------------------------------

loginUI <- function(id) {
  ns <- NS(id)
  tagList(
    useShinyjs(),
    div(
      id = ns("login_panel"),
      class = "login-container",
      div(
        class = "login-box",
        tags$img(
          src   = "gtvet_logo.png",
          alt   = "Ghana TVET Service",
          style = "max-width:180px; margin-bottom:20px;"
        ),
        h3("Ghana TVET Service", style = "margin-top:0;"),
        h5("Integrated Data Management System", class = "text-muted"),
        hr(),
        textInput(ns("username"), "Username", placeholder = "Enter your username"),
        passwordInput(ns("password"), "Password", placeholder = "Enter your password"),
        div(
          style = "display:flex; justify-content:space-between; align-items:center;",
          actionButton(ns("btn_login"), "Sign In",
                       class = "btn btn-primary btn-block",
                       style = "min-width:100px;")
        ),
        br(),
        uiOutput(ns("login_error"))
      )
    ),
    # Change password dialog (shown when must_change_pw = TRUE)
    shinyjs::hidden(
      div(
        id = ns("change_pw_panel"),
        class = "login-container",
        div(
          class = "login-box",
          h4("Change Your Password"),
          p("You must set a new password before continuing.", class = "text-muted"),
          passwordInput(ns("new_pw"),     "New Password"),
          passwordInput(ns("confirm_pw"), "Confirm New Password"),
          actionButton(ns("btn_change_pw"), "Update Password", class = "btn btn-success"),
          br(), br(),
          uiOutput(ns("change_pw_msg"))
        )
      )
    )
  )
}

# ------ Server -----------------------------------------------

loginServer <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values tracking session state
    auth <- reactiveValues(
      logged_in      = FALSE,
      user_id        = NA,
      username       = NA,
      full_name      = NA,
      role           = NA,
      institution_id = NA,
      region_id      = NA,
      must_change_pw = FALSE
    )

    # --- Login attempt ---
    observeEvent(input$btn_login, {
      req(input$username, input$password)
      uname <- trimws(input$username)
      pw    <- input$password

      user <- db_query(pool,
        "SELECT user_id, username, full_name, role, institution_id, region_id,
                must_change_pw, is_active,
                (password_hash = crypt($2, password_hash)) AS pw_ok
         FROM users WHERE username = $1",
        list(uname, pw))

      if (nrow(user) == 0 || !isTRUE(user$pw_ok[1])) {
        output$login_error <- renderUI(
          div(class = "alert alert-danger",
              icon("exclamation-circle"), " Invalid username or password.")
        )
        return()
      }
      if (!isTRUE(user$is_active[1])) {
        output$login_error <- renderUI(
          div(class = "alert alert-warning",
              icon("ban"), " This account is disabled. Contact your administrator.")
        )
        return()
      }

      # Successful auth — record last_login
      db_execute(pool,
        "UPDATE users SET last_login = NOW() WHERE user_id = $1",
        list(user$user_id[1]))

      log_action(pool, user$user_id[1], "LOGIN")

      auth$user_id        <- user$user_id[1]
      auth$username       <- user$username[1]
      auth$full_name      <- user$full_name[1]
      auth$role           <- user$role[1]
      auth$institution_id <- user$institution_id[1]
      auth$region_id      <- user$region_id[1]
      auth$must_change_pw <- isTRUE(user$must_change_pw[1])

      if (auth$must_change_pw) {
        shinyjs::hide(ns("login_panel"))
        shinyjs::show(ns("change_pw_panel"))
      } else {
        auth$logged_in <- TRUE
      }
    })

    # --- Password change ---
    observeEvent(input$btn_change_pw, {
      new_pw  <- input$new_pw
      conf_pw <- input$confirm_pw

      if (nchar(new_pw) < 8) {
        output$change_pw_msg <- renderUI(
          div(class = "alert alert-danger", "Password must be at least 8 characters.")
        )
        return()
      }
      if (new_pw != conf_pw) {
        output$change_pw_msg <- renderUI(
          div(class = "alert alert-danger", "Passwords do not match.")
        )
        return()
      }

      db_execute(pool,
        "UPDATE users SET password_hash = crypt($1, gen_salt('bf',12)),
                          must_change_pw = FALSE
         WHERE user_id = $2",
        list(new_pw, auth$user_id))

      log_action(pool, auth$user_id, "PASSWORD_CHANGE")

      auth$must_change_pw <- FALSE
      auth$logged_in      <- TRUE
      shinyjs::hide(ns("change_pw_panel"))
    })

    # Return reactive read-only view of auth state
    return(auth)
  })
}
