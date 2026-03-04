# =============================================================
# GTVET-IDMS  Database helpers
# =============================================================

library(RPostgres)
library(DBI)
library(pool)

# ------ Connection pool (shared across sessions) ---------------

make_pool <- function(cfg = DB_CONFIG) {
  pool::dbPool(
    drv      = RPostgres::Postgres(),
    host     = cfg$host,
    port     = cfg$port,
    dbname   = cfg$dbname,
    user     = cfg$user,
    password = cfg$password,
    minSize  = 2,
    maxSize  = 10,
    idleTimeout = 600
  )
}

# Call once at app startup (in global.R): pool <- make_pool()

# ------ Safe query helpers ------------------------------------

#' Execute a parameterised query and return a data.frame
db_query <- function(con, sql, params = NULL) {
  tryCatch({
    if (is.null(params) || length(params) == 0) {
      DBI::dbGetQuery(con, sql)
    } else {
      DBI::dbGetQuery(con, sql, params = params)
    }
  }, error = function(e) {
    message("[db_query] ERROR: ", conditionMessage(e))
    NULL
  })
}

#' Execute a write statement (INSERT / UPDATE / DELETE)
#' Returns number of rows affected, or -1 on error
db_execute <- function(pool, sql, params = list()) {
  con <- pool::poolCheckout(pool)
  on.exit(pool::poolReturn(con))
  tryCatch({
    res <- dbSendStatement(con, sql, params = params)
    n   <- dbGetRowsAffected(res)
    dbClearResult(res)
    n
  }, error = function(e) {
    message("[db_execute] ERROR: ", conditionMessage(e))
    -1L
  })
}

#' Insert a single row and return the generated id
db_insert_returning <- function(pool, sql, params = list()) {
  con <- pool::poolCheckout(pool)
  on.exit(pool::poolReturn(con))
  tryCatch(
    dbGetQuery(con, sql, params = params)[[1]],
    error = function(e) {
      message("[db_insert_returning] ERROR: ", conditionMessage(e))
      NA_integer_
    }
  )
}

# ------ Reference data loaders (cached) ----------------------

load_regions <- function(pool) {
  db_query(pool, "SELECT region_id, region_name FROM regions ORDER BY region_name")
}

load_districts <- function(pool, region_id = NULL) {
  if (is.null(region_id)) {
    db_query(pool, "SELECT district_id, district_name, region_id FROM districts ORDER BY district_name")
  } else {
    db_query(pool,
      "SELECT district_id, district_name FROM districts WHERE region_id = $1 ORDER BY district_name",
      list(region_id))
  }
}

load_programmes <- function(pool) {
  db_query(pool,
    "SELECT programme_id, programme_code, programme_name, trade_category, is_cbt_option, girls_only
     FROM programmes WHERE is_active = TRUE ORDER BY programme_code")
}

load_institutions <- function(pool, region_id = NULL) {
  if (is.null(region_id)) {
    db_query(pool,
      "SELECT i.institution_id, i.institution_name, i.cssps_code, i.region_id,
              r.region_name, i.district_id, i.location, i.institution_type, i.gender_type
       FROM institutions i JOIN regions r ON r.region_id = i.region_id
       WHERE i.is_active = TRUE ORDER BY i.institution_name")
  } else {
    db_query(pool,
      "SELECT i.institution_id, i.institution_name, i.cssps_code, i.region_id,
              r.region_name, i.district_id, i.location, i.institution_type, i.gender_type
       FROM institutions i JOIN regions r ON r.region_id = i.region_id
       WHERE i.is_active = TRUE AND i.region_id = $1 ORDER BY i.institution_name",
      list(region_id))
  }
}

load_exam_types <- function(pool) {
  db_query(pool, "SELECT exam_type_id, exam_type_name FROM exam_types ORDER BY exam_type_name")
}

load_impairments <- function(pool) {
  db_query(pool, "SELECT impairment_id, impairment_name FROM impairment_categories ORDER BY impairment_name")
}

load_challenges <- function(pool) {
  db_query(pool, "SELECT challenge_id, challenge_name FROM challenge_types ORDER BY challenge_name")
}

load_institution_programmes <- function(pool, institution_id) {
  db_query(pool,
    "SELECT p.programme_id, p.programme_code, p.programme_name
     FROM institution_programmes ip
     JOIN programmes p ON p.programme_id = ip.programme_id
     WHERE ip.institution_id = $1 ORDER BY p.programme_code",
    list(institution_id))
}

# ------ Audit logger -----------------------------------------

log_action <- function(pool, user_id, action, target_table = NULL,
                        target_id = NULL, detail = NULL, ip = NULL) {
  db_execute(pool,
    "INSERT INTO audit_log (user_id, action, target_table, target_id, detail, ip_address)
     VALUES ($1,$2,$3,$4,$5,$6)",
    list(user_id, action, target_table, target_id, detail, ip)
  )
}
