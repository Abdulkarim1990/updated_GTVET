# Ghana TVET Service — Integrated Data Management System (GTVET-IDMS)

**Version:** 1.0 — Phase 1 Foundation
**Stack:** R Shiny · PostgreSQL · Plumber (Phase 2+)

---

## Phase 1 Contents

| Component | Location | Status |
|-----------|----------|--------|
| PostgreSQL schema | `db/schema.sql` | ✅ Ready |
| Reference data seeds | `db/seed/` | ✅ Ready |
| R Shiny app | `app/` | ✅ Ready |
| Auth module | `app/modules/auth/` | ✅ Ready |
| M1 Bio-Data & Enrolment | `app/modules/m1_biodata/` | ✅ Ready |
| M2 Staff & HR | `app/modules/m2_staff/` | ✅ Ready |
| Submission workflow | `app/server.R` | ✅ Ready |

---

## Quick Start

### 1. Database Setup

```bash
# Set your PostgreSQL credentials
export GTVET_DB_HOST=localhost
export GTVET_DB_PORT=5432
export GTVET_DB_NAME=gtvet
export GTVET_DB_USER=postgres
export GTVET_DB_PASSWORD=tvet_ghana

# Run the initialisation script
bash db/seed/00_run_all.sh
```

This creates the `gtvet` database, runs the schema, and loads:
- 16 regions
- 170 districts
- 46 programmes (with codes 601–903)
- 233 institutions
- 1,424 institution-programme links
- Exam types, impairment categories, challenge types
- Submission windows for 2025/2026 (Semesters 1 & 2)
- Default admin user: `admin` / `Admin@GTVET2025`

### 2. Install R Packages

```r
source("app/dependencies.R")
```

### 3. Configure Database Connection

Set environment variables before launching (or edit `app/config.R`):

```bash
export GTVET_DB_PASSWORD=your_password
```

### 4. Run the App

```r
shiny::runApp("app", port = 3838, launch.browser = TRUE)
```

---

## User Roles

| Role | Can do |
|------|--------|
| `school_user` | Submit M1, M2 for own institution |
| `regional_officer` | Approve/return submissions for own region |
| `qa_officer` | QA checklists (Phase 2) |
| `national_viewer` | Read-only national dashboard (Phase 3) |
| `admin` | Full access: user management, windows, audit log |

### Creating School User Accounts

```sql
INSERT INTO users (username, email, password_hash, full_name, role, institution_id)
VALUES (
  'school_user_001',
  'principal@myschool.edu.gh',
  crypt('TempPass@123', gen_salt('bf',12)),
  'Principal Name',
  'school_user',
  (SELECT institution_id FROM institutions WHERE cssps_code = '9050101')
);
```

---

## Roadmap

| Phase | Modules | Timeline |
|-------|---------|----------|
| **Phase 1** (current) | M1, M2, Auth, Submission workflow | Months 1–3 |
| Phase 2 | M3 WEL, M4 WEL Assessment, M5 Industry Partners, QA1–QA4 | Months 4–6 |
| Phase 3 | M6 Learner Registry, M7 G&C | Months 7–9 |
| Phase 4 | M8 Informal, M9 Special, M10 Regional Reporting, National Dashboard | Months 10–12 |
| Phase 5 | Bulk upload, historical migration, mobile optimisation | Month 13+ |

---

## Key Design Decisions (to be confirmed)

1. **Submission calendar** — currently set to 2 semesters. Update `submission_windows` table as needed.
2. **Learner ID** — M6 schema deferred to Phase 3. Will use institution Student ID as interim key.
3. **Offline fallback** — Excel bulk upload parser deferred to Phase 5.
4. **QA Officer assignment** — roving pool assumed; fixed assignments can be added via `users.institution_id`.
5. **Document uploads** — deferred; PostgreSQL `bytea` columns can be added to relevant tables.
