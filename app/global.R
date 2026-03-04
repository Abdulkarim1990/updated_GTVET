# =============================================================
# GTVET-IDMS  global.R
# Loaded once per R worker process
# =============================================================

library(shiny)
library(shinyjs)
library(shinydashboard)
library(DBI)
library(RPostgres)
library(pool)
library(DT)
library(dplyr)

# ------ Load config and helpers -------------------------------
source("config.R")
source("utils/db.R")
source("utils/validation.R")

# ------ Source all modules ------------------------------------
source("modules/auth/auth_module.R")
source("modules/m1_biodata/m1_module.R")
source("modules/m2_staff/m2_module.R")

# ------ Create shared DB connection pool ---------------------
pool <- tryCatch(
  make_pool(DB_CONFIG),
  error = function(e) {
    message("[global.R] Database connection failed: ", conditionMessage(e))
    message("[global.R] Check DB_CONFIG / environment variables and ensure PostgreSQL is running.")
    NULL
  }
)

# Ensure pool is closed when the app shuts down
onStop(function() {
  if (!is.null(pool)) pool::poolClose(pool)
})

# ------ Cached reference lookups (refreshed on app start) -----
if (!is.null(pool)) {
  REF <- tryCatch(
    list(
      regions     = load_regions(pool),
      programmes  = load_programmes(pool),
      exam_types  = load_exam_types(pool),
      impairments = load_impairments(pool),
      challenges  = load_challenges(pool)
    ),
    error = function(e) {
      message("[global.R] Failed to load reference data: ", conditionMessage(e))
      list(
        regions     = data.frame(region_id = integer(), region_name = character()),
        programmes  = data.frame(programme_id = integer(), programme_code = character(),
                                 programme_name = character()),
        exam_types  = data.frame(exam_type_id = integer(), exam_type_name = character()),
        impairments = data.frame(impairment_id = integer(), impairment_name = character()),
        challenges  = data.frame(challenge_id = integer(), challenge_name = character())
      )
    }
  )
} else {
  REF <- list(
    regions     = data.frame(region_id = integer(), region_name = character()),
    programmes  = data.frame(programme_id = integer(), programme_code = character(),
                             programme_name = character()),
    exam_types  = data.frame(exam_type_id = integer(), exam_type_name = character()),
    impairments = data.frame(impairment_id = integer(), impairment_name = character()),
    challenges  = data.frame(challenge_id = integer(), challenge_name = character())
  )
}

# Named vectors for selectInput choices
region_choices <- if (nrow(REF$regions) > 0)
  setNames(REF$regions$region_id, REF$regions$region_name)
else
  character(0)

programme_choices <- if (nrow(REF$programmes) > 0)
  setNames(
    REF$programmes$programme_id,
    paste0("[", REF$programmes$programme_code, "] ", REF$programmes$programme_name)
  )
else
  character(0)

exam_type_choices <- if (nrow(REF$exam_types) > 0)
  setNames(REF$exam_types$exam_type_id, REF$exam_types$exam_type_name)
else
  character(0)

impairment_choices <- if (nrow(REF$impairments) > 0)
  setNames(REF$impairments$impairment_id, REF$impairments$impairment_name)
else
  character(0)

challenge_choices <- if (nrow(REF$challenges) > 0)
  setNames(REF$challenges$challenge_id, REF$challenges$challenge_name)
else
  character(0)

month_choices <- c(
  "January","February","March","April","May","June",
  "July","August","September","October","November","December"
)
