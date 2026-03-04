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
pool <- make_pool(DB_CONFIG)

# Ensure pool is closed when the app shuts down
onStop(function() {
  pool::poolClose(pool)
})

# ------ Cached reference lookups (refreshed on app start) -----
REF <- list(
  regions    = load_regions(pool),
  programmes = load_programmes(pool),
  exam_types = load_exam_types(pool),
  impairments = load_impairments(pool),
  challenges  = load_challenges(pool)
)

# Named vectors for selectInput choices
region_choices <- setNames(REF$regions$region_id, REF$regions$region_name)

programme_choices <- setNames(
  REF$programmes$programme_id,
  paste0("[", REF$programmes$programme_code, "] ", REF$programmes$programme_name)
)

exam_type_choices <- setNames(
  REF$exam_types$exam_type_id,
  REF$exam_types$exam_type_name
)

impairment_choices <- setNames(
  REF$impairments$impairment_id,
  REF$impairments$impairment_name
)

challenge_choices <- setNames(
  REF$challenges$challenge_id,
  REF$challenges$challenge_name
)

month_choices <- c(
  "January","February","March","April","May","June",
  "July","August","September","October","November","December"
)
