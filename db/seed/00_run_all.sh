#!/bin/bash
# =============================================================
# GTVET-IDMS  Database Initialisation Script
# Usage: DB_NAME=gtvet DB_USER=postgres bash 00_run_all.sh
# =============================================================

DB_NAME=${DB_NAME:-gtvet}
DB_USER=${DB_USER:-postgres}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$SCRIPT_DIR/../schema.sql"

echo "=== GTVET-IDMS Database Setup ==="
echo "  Host:     $DB_HOST:$DB_PORT"
echo "  Database: $DB_NAME"
echo "  User:     $DB_USER"
echo ""

# Create the database if it doesn't exist
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres \
  -c "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres \
  -c "CREATE DATABASE $DB_NAME WITH ENCODING 'UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8';"

echo "1/7  Running schema..."
$PSQL -f "$SCHEMA" && echo "     OK"

echo "2/7  Seeding regions..."
$PSQL -f "$SCRIPT_DIR/01_regions.sql" && echo "     OK"

echo "3/7  Seeding districts..."
$PSQL -f "$SCRIPT_DIR/02_districts.sql" && echo "     OK"

echo "4/7  Seeding programmes..."
$PSQL -f "$SCRIPT_DIR/03_programmes.sql" && echo "     OK"

echo "5/7  Seeding institutions..."
$PSQL -f "$SCRIPT_DIR/04_institutions.sql" && echo "     OK"

echo "6/7  Seeding institution-programme links..."
$PSQL -f "$SCRIPT_DIR/05_institution_programmes.sql" && echo "     OK"

echo "7/7  Seeding reference data & admin user..."
$PSQL -f "$SCRIPT_DIR/06_reference_data.sql" && echo "     OK"

echo ""
echo "=== Database initialised successfully ==="
echo "    Default admin login: admin / Admin@GTVET2025"
echo "    IMPORTANT: change the admin password immediately after first login."
