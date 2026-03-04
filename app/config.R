# =============================================================
# GTVET-IDMS  Database Configuration
# Copy this file and edit with your local credentials.
# Never commit real passwords to version control.
# =============================================================

DB_CONFIG <- list(
  host     = Sys.getenv("GTVET_DB_HOST",     "localhost"),
  port     = as.integer(Sys.getenv("GTVET_DB_PORT", "5432")),
  dbname   = Sys.getenv("GTVET_DB_NAME",     "gtvet"),
  user     = Sys.getenv("GTVET_DB_USER",     "postgres"),
  password = Sys.getenv("GTVET_DB_PASSWORD", "")
)

APP_CONFIG <- list(
  app_title     = "Ghana TVET Service — Integrated Data Management System",
  app_version   = "1.0 (Phase 1)",
  session_hours = 8,          # auto-logout after N hours of inactivity
  current_ay    = "2025/2026" # active academic year
)
