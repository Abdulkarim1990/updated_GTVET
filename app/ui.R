# =============================================================
# GTVET-IDMS  ui.R
# =============================================================

# ------ Helper: Coming Soon panel ----------------------------
coming_soon_ui <- function(module_name) {
  fluidRow(
    column(12,
           div(class = "coming-soon-box",
               icon("clock", class = "coming-soon-icon"),
               h3(module_name),
               p("This module will be available in Phase 2."),
               p(class = "text-muted", "Pilot release: Months 4–6")
           )
    )
  )
}

# ------ Helper: Home tab ------------------------------------
homeUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(12,
           div(class = "home-welcome",
               uiOutput(ns("welcome_msg"))
           )
    ),
    column(3, uiOutput(ns("box_m1_status"))),
    column(3, uiOutput(ns("box_m2_status"))),
    column(6, uiOutput(ns("box_window_status")))
  )
}

# ------ Helper: My Submissions tab ---------------------------
mySubmissionsUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(12,
           h3("My Submissions"),
           DTOutput(ns("submissions_table"))
    )
  )
}

# ------ Main UI ----------------------------------------------
ui <- fluidPage(
  title = APP_CONFIG$app_title,
  
  tags$head(
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
  ),
  
  useShinyjs(),
  
  div(id = "app_login",
      loginUI("auth")
  ),

  shinyjs::hidden(
    div(id = "app_main",
        shinydashboard::dashboardPage(
          skin = "green",
          
          shinydashboard::dashboardHeader(
            title = tags$span(
              tags$img(src = "gtvet_logo.png", height = "30px"),
              " GTVET-IDMS"
            ),
            tags$li(class = "dropdown", uiOutput("header_user_info")),
            tags$li(
              class = "dropdown",
              actionLink("btn_logout", label = tagList(icon("sign-out-alt"), " Logout"),
                         style = "padding:15px 10px; color:#fff;")
            )
          ),
          
          shinydashboard::dashboardSidebar(
            shinydashboard::sidebarMenu(
              id = "sidebar_menu",
              shinydashboard::menuItem("Home", tabName = "home", icon = icon("home")),
              shinydashboard::menuItem("Module M1 — Enrolment", tabName = "m1", icon = icon("users"),
                                       badgeLabel = "Phase 1", badgeColor = "green"),
              shinydashboard::menuItem("Module M2 — Staff & HR", tabName = "m2", icon = icon("chalkboard-teacher"),
                                       badgeLabel = "Phase 1", badgeColor = "green"),
              shinydashboard::menuItem("Module M3 — WEL", tabName = "m3", icon = icon("briefcase"),
                                       badgeLabel = "Phase 2", badgeColor = "yellow"),
              shinydashboard::menuItem("Module M4 — WEL Assessment", tabName = "m4", icon = icon("clipboard-check"),
                                       badgeLabel = "Phase 2", badgeColor = "yellow"),
              hr(),
              shinydashboard::menuItem("My Submissions", tabName = "my_submissions", icon = icon("list-check")),
              uiOutput("sidebar_admin_menu")
            )
          ),
          
          shinydashboard::dashboardBody(
            shinydashboard::tabItems(
              shinydashboard::tabItem(tabName = "home", homeUI("home_panel")),
              shinydashboard::tabItem(tabName = "m1", m1UI("m1_module")),
              shinydashboard::tabItem(tabName = "m2", m2UI("m2_module")),
              shinydashboard::tabItem(tabName = "my_submissions", mySubmissionsUI("my_subs")),
              shinydashboard::tabItem(tabName = "m3", coming_soon_ui("M3 — WEL Placement & Tracking")),
              shinydashboard::tabItem(tabName = "m4", coming_soon_ui("M4 — WEL Assessment & Employer Feedback"))
            )
          )
        )
    )
  )
)