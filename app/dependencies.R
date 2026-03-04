# =============================================================
# GTVET-IDMS  R Package Dependencies
# Run this script once to install all required packages.
# After installation, use renv::init() to lock versions.
# =============================================================

required_packages <- c(
  "shiny",           # Core web framework
  "shinydashboard",  # Dashboard layout
  "shinyjs",         # JavaScript helpers (show/hide, etc.)
  "DBI",             # Database interface
  "RPostgres",       # PostgreSQL driver
  "pool",            # Connection pooling
  "DT",              # Interactive data tables
  "dplyr",           # Data manipulation
  "plotly",          # Interactive charts (Phase 3 dashboard)
  "leaflet",         # Maps (Phase 3 dashboard)
  "echarts4r",       # ECharts visualisations (Phase 3)
  "openxlsx"         # Excel export
)

missing <- required_packages[!vapply(required_packages, requireNamespace,
                                     quietly = TRUE, FUN.VALUE = logical(1))]

if (length(missing) > 0) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}

message("Done. Run shiny::runApp('app') to start the application.")
