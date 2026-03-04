# =============================================================
# GTVET-IDMS  Validation helpers
# All business rules from Section 5.1 of the System Design
# =============================================================

#' Return character(0) (no errors) or a character vector of error messages
validate_enrolment_row <- function(male, female, pwsn_male, pwsn_female) {
  errors <- character(0)
  total <- male + female
  if (total < 0)             errors <- c(errors, "Enrolment cannot be negative.")
  if (pwsn_male + pwsn_female > total)
    errors <- c(errors, "PWSN count cannot exceed total enrolment.")
  errors
}

validate_exam_row <- function(registered_m, registered_f,
                               present_m, present_f,
                               passed_m, passed_f) {
  errors <- character(0)
  reg   <- registered_m + registered_f
  pres  <- present_m    + present_f
  pass  <- passed_m     + passed_f
  if (pres > reg)  errors <- c(errors, "Students present cannot exceed registered.")
  if (pass > pres) errors <- c(errors, "Students passed cannot exceed those present.")
  errors
}

validate_wel_summary <- function(due_m, due_f, placed_m, placed_f) {
  errors <- character(0)
  if ((placed_m + placed_f) > (due_m + due_f + 2))
    errors <- c(errors, "WEL placed count exceeds due count (tolerance ±2).")
  errors
}

validate_date_in_window <- function(report_date, window_open, window_close) {
  if (is.na(report_date)) return("Reporting date is required.")
  if (report_date < window_open || report_date > window_close)
    return(sprintf("Reporting date must be between %s and %s.",
                   format(window_open, "%d %b %Y"),
                   format(window_close, "%d %b %Y")))
  character(0)
}

validate_percentage <- function(value, field_name = "Value") {
  if (is.na(value) || !is.numeric(value)) return(paste(field_name, "must be a number."))
  if (value < 0 || value > 100)           return(paste(field_name, "must be between 0 and 100."))
  character(0)
}

#' Check whether a submission window is currently open for a given module/year/semester
is_window_open <- function(pool, module_code, academic_year, semester) {
  today <- Sys.Date()
  res <- db_query(pool,
    "SELECT window_id FROM submission_windows
     WHERE module_code = $1 AND academic_year = $2 AND semester = $3
       AND is_active = TRUE AND open_date <= $4 AND close_date >= $4",
    list(module_code, academic_year, as.integer(semester), today))
  nrow(res) > 0
}

#' Return existing draft/returned submission id for a school-module-period, or NA
get_active_submission <- function(pool, institution_id, module_code, academic_year, semester) {
  res <- db_query(pool,
    "SELECT submission_id, status, version FROM submissions
     WHERE institution_id = $1 AND module_code = $2
       AND academic_year = $3 AND semester = $4
       AND status IN ('Draft','Returned')
     ORDER BY version DESC LIMIT 1",
    list(institution_id, module_code, academic_year, as.integer(semester)))
  if (nrow(res) == 0) return(NULL)
  as.list(res[1, ])
}
