-- =============================================================
-- GTVET-IDMS  PostgreSQL Schema  v1.0
-- Ghana TVET Service Integrated Data Management System
-- Phase 1: Reference data + Auth + M1 (Bio-Data/Enrolment) + M2 (Staff)
-- =============================================================

-- Run as superuser or owner of the target database
-- psql -d gtvet -f schema.sql

-- ---------------------------------------------------------------
-- EXTENSIONS
-- ---------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid(), crypt()

-- ---------------------------------------------------------------
-- REFERENCE TABLES
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS regions (
    region_id   SERIAL      PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS districts (
    district_id   SERIAL      PRIMARY KEY,
    district_name VARCHAR(150) NOT NULL,
    region_id     INTEGER     NOT NULL REFERENCES regions(region_id),
    UNIQUE (district_name, region_id)
);

CREATE TABLE IF NOT EXISTS programmes (
    programme_id   SERIAL       PRIMARY KEY,
    programme_code VARCHAR(10)  NOT NULL UNIQUE,   -- e.g. '601', '802'
    programme_name VARCHAR(200) NOT NULL,
    trade_category VARCHAR(50)  NOT NULL,           -- Engineering / Building / Business / Core
    is_cbt_option  BOOLEAN      DEFAULT FALSE,
    girls_only     BOOLEAN      DEFAULT FALSE,
    is_active      BOOLEAN      DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS exam_types (
    exam_type_id   SERIAL      PRIMARY KEY,
    exam_type_name VARCHAR(100) NOT NULL UNIQUE    -- e.g. 'PROFICIENCY I - TEU'
);

CREATE TABLE IF NOT EXISTS impairment_categories (
    impairment_id   SERIAL      PRIMARY KEY,
    impairment_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS challenge_types (
    challenge_id   SERIAL      PRIMARY KEY,
    challenge_name VARCHAR(200) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------
-- INSTITUTIONS
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS institutions (
    institution_id   SERIAL       PRIMARY KEY,
    institution_name VARCHAR(250) NOT NULL,
    cssps_code       VARCHAR(20)  UNIQUE,           -- CSSPS / institution code
    region_id        INTEGER      NOT NULL REFERENCES regions(region_id),
    district_id      INTEGER      REFERENCES districts(district_id),
    location         VARCHAR(150),
    institution_type VARCHAR(10)  NOT NULL DEFAULT 'C'
                     CHECK (institution_type IN ('A','B','C','Private','PTIS')),
    gender_type      VARCHAR(10)  NOT NULL DEFAULT 'Mixed'
                     CHECK (gender_type IN ('Mixed','Girls','Boys')),
    email            VARCHAR(150),
    phone            VARCHAR(30),
    has_sickbay      BOOLEAN,
    has_library      BOOLEAN,
    library_stocked  BOOLEAN,
    has_ict_lab      BOOLEAN,
    ict_lab_equipped BOOLEAN,
    latitude         NUMERIC(9,6),
    longitude        NUMERIC(9,6),
    is_active        BOOLEAN      DEFAULT TRUE,
    created_at       TIMESTAMPTZ  DEFAULT NOW()
);

-- Which programmes each institution offers (from TVET 2025 Register)
CREATE TABLE IF NOT EXISTS institution_programmes (
    id             SERIAL  PRIMARY KEY,
    institution_id INTEGER NOT NULL REFERENCES institutions(institution_id) ON DELETE CASCADE,
    programme_id   INTEGER NOT NULL REFERENCES programmes(programme_id) ON DELETE CASCADE,
    UNIQUE (institution_id, programme_id)
);

-- ---------------------------------------------------------------
-- USERS & ACCESS CONTROL
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
    user_id        SERIAL       PRIMARY KEY,
    username       VARCHAR(100) NOT NULL UNIQUE,
    email          VARCHAR(200) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,           -- bcrypt via pgcrypto
    full_name      VARCHAR(200),
    role           VARCHAR(25)  NOT NULL
                   CHECK (role IN (
                       'school_user',
                       'regional_officer',
                       'qa_officer',
                       'national_viewer',
                       'admin'
                   )),
    institution_id INTEGER      REFERENCES institutions(institution_id),
    region_id      INTEGER      REFERENCES regions(region_id),
    is_active      BOOLEAN      DEFAULT TRUE,
    must_change_pw BOOLEAN      DEFAULT TRUE,       -- force PW change on first login
    last_login     TIMESTAMPTZ,
    created_at     TIMESTAMPTZ  DEFAULT NOW(),
    created_by     INTEGER      REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS audit_log (
    log_id         SERIAL      PRIMARY KEY,
    user_id        INTEGER     REFERENCES users(user_id),
    action         VARCHAR(100) NOT NULL,
    target_table   VARCHAR(100),
    target_id      INTEGER,
    detail         TEXT,
    ip_address     VARCHAR(45),
    logged_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- SUBMISSION CONTROL
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS submission_windows (
    window_id       SERIAL      PRIMARY KEY,
    module_code     VARCHAR(10) NOT NULL,           -- M1, M2, M3 … QA1–QA4
    academic_year   VARCHAR(9)  NOT NULL,           -- e.g. '2025/2026'
    semester        SMALLINT    NOT NULL CHECK (semester IN (1,2)),
    open_date       DATE        NOT NULL,
    close_date      DATE        NOT NULL,
    is_active       BOOLEAN     DEFAULT TRUE,
    created_by      INTEGER     REFERENCES users(user_id),
    UNIQUE (module_code, academic_year, semester)
);

CREATE TABLE IF NOT EXISTS submissions (
    submission_id   SERIAL       PRIMARY KEY,
    institution_id  INTEGER      NOT NULL REFERENCES institutions(institution_id),
    module_code     VARCHAR(10)  NOT NULL,
    academic_year   VARCHAR(9)   NOT NULL,
    semester        SMALLINT     NOT NULL CHECK (semester IN (1,2)),
    status          VARCHAR(20)  NOT NULL DEFAULT 'Draft'
                    CHECK (status IN (
                        'Draft','Submitted','Under Review','Approved','Returned'
                    )),
    submitted_by    INTEGER      REFERENCES users(user_id),
    submitted_at    TIMESTAMPTZ,
    reviewed_by     INTEGER      REFERENCES users(user_id),
    reviewed_at     TIMESTAMPTZ,
    approved_by     INTEGER      REFERENCES users(user_id),
    approved_at     TIMESTAMPTZ,
    return_reason   TEXT,
    version         SMALLINT     DEFAULT 1,
    created_at      TIMESTAMPTZ  DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  DEFAULT NOW(),
    UNIQUE (institution_id, module_code, academic_year, semester, version)
);

-- ---------------------------------------------------------------
-- MODULE M1 — BIO-DATA
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m1_biodata (
    biodata_id         SERIAL      PRIMARY KEY,
    submission_id      INTEGER     NOT NULL UNIQUE REFERENCES submissions(submission_id) ON DELETE CASCADE,
    reporting_semester SMALLINT    NOT NULL CHECK (reporting_semester IN (1,2)),
    reporting_month    VARCHAR(15),
    reporting_year     INTEGER     NOT NULL,
    academic_year      VARCHAR(9)  NOT NULL,
    -- Principal contact (as submitted — may differ from user account)
    principal_name     VARCHAR(200),
    principal_mobile   VARCHAR(30),
    principal_email    VARCHAR(150),
    -- Infrastructure flags
    has_sickbay        BOOLEAN,
    has_library        BOOLEAN,
    library_stocked    BOOLEAN,
    has_ict_lab        BOOLEAN,
    ict_lab_equipped   BOOLEAN,
    -- Enrolment summary (computed from enrolment_records but stored for quick access)
    day_enrolment_yr1  INTEGER     DEFAULT 0,
    boarding_enrolment_yr1 INTEGER DEFAULT 0,
    fee_paying_enrolment INTEGER   DEFAULT 0,
    total_enrolment    INTEGER     DEFAULT 0,    -- auto-updated by trigger
    total_placed_wel   INTEGER     DEFAULT 0,    -- cross-ref from M3
    -- Remarks
    additional_remarks TEXT,
    created_at         TIMESTAMPTZ DEFAULT NOW(),
    updated_at         TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- MODULE M1 — ENROLMENT RECORDS (per programme per year of study)
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m1_enrolment (
    enrolment_id       SERIAL   PRIMARY KEY,
    submission_id      INTEGER  NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    programme_id       INTEGER  REFERENCES programmes(programme_id),
    programme_free_text VARCHAR(200),             -- for programmes not in dropdown
    year_of_study      SMALLINT NOT NULL CHECK (year_of_study IN (1,2,3)),
    num_classrooms     SMALLINT,
    num_workshops      SMALLINT,
    tools_equipment_adequate BOOLEAN,
    tools_remarks      TEXT,
    enrolment_male     INTEGER  NOT NULL DEFAULT 0 CHECK (enrolment_male >= 0),
    enrolment_female   INTEGER  NOT NULL DEFAULT 0 CHECK (enrolment_female >= 0),
    enrolment_total    INTEGER  GENERATED ALWAYS AS (enrolment_male + enrolment_female) STORED,
    day_male           INTEGER  DEFAULT 0,
    day_female         INTEGER  DEFAULT 0,
    boarding_male      INTEGER  DEFAULT 0,
    boarding_female    INTEGER  DEFAULT 0,
    teaching_staff_male   SMALLINT DEFAULT 0,
    teaching_staff_female SMALLINT DEFAULT 0,
    created_at         TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- MODULE M1 — PWSN STUDENTS (per programme)
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m1_pwsn (
    pwsn_id            SERIAL   PRIMARY KEY,
    submission_id      INTEGER  NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    programme_id       INTEGER  REFERENCES programmes(programme_id),
    programme_free_text VARCHAR(200),
    year_of_study      SMALLINT NOT NULL CHECK (year_of_study IN (1,2,3)),
    impairment_id      INTEGER  REFERENCES impairment_categories(impairment_id),
    pwsn_male          INTEGER  NOT NULL DEFAULT 0 CHECK (pwsn_male >= 0),
    pwsn_female        INTEGER  NOT NULL DEFAULT 0 CHECK (pwsn_female >= 0),
    pwsn_total         INTEGER  GENERATED ALWAYS AS (pwsn_male + pwsn_female) STORED
);

-- ---------------------------------------------------------------
-- MODULE M1 — WEL SUMMARY (summary table on WEL sheet)
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m1_wel_summary (
    wel_summary_id   SERIAL   PRIMARY KEY,
    submission_id    INTEGER  NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    programme_id     INTEGER  REFERENCES programmes(programme_id),
    programme_free_text VARCHAR(200),
    year_of_study    SMALLINT NOT NULL CHECK (year_of_study IN (1,2,3)),
    num_due_male     INTEGER  DEFAULT 0,
    num_due_female   INTEGER  DEFAULT 0,
    num_placed_male  INTEGER  DEFAULT 0,
    num_placed_female INTEGER DEFAULT 0,
    CONSTRAINT wel_placed_le_due CHECK (
        (num_placed_male + num_placed_female) <= (num_due_male + num_due_female + 2)
    )
);

-- ---------------------------------------------------------------
-- MODULE M1 — EXAMINATION RECORDS
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m1_exam (
    exam_id            SERIAL   PRIMARY KEY,
    submission_id      INTEGER  NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    exam_year          INTEGER  NOT NULL,
    exam_month         VARCHAR(15),
    programme_id       INTEGER  REFERENCES programmes(programme_id),
    programme_free_text VARCHAR(200),
    exam_type_id       INTEGER  REFERENCES exam_types(exam_type_id),
    registered_male    INTEGER  DEFAULT 0,
    registered_female  INTEGER  DEFAULT 0,
    present_male       INTEGER  DEFAULT 0,
    present_female     INTEGER  DEFAULT 0,
    passed_male        INTEGER  DEFAULT 0,
    passed_female      INTEGER  DEFAULT 0,
    referred_male      INTEGER  DEFAULT 0,
    referred_female    INTEGER  DEFAULT 0,
    CONSTRAINT present_le_registered CHECK (
        (present_male + present_female) <= (registered_male + registered_female)
    ),
    CONSTRAINT passed_le_present CHECK (
        (passed_male + passed_female) <= (present_male + present_female)
    )
);

-- ---------------------------------------------------------------
-- MODULE M1 — GRADUATE LIST
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m1_graduates (
    graduate_id        SERIAL       PRIMARY KEY,
    submission_id      INTEGER      NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    full_name          VARCHAR(250) NOT NULL,
    programme_id       INTEGER      REFERENCES programmes(programme_id),
    programme_free_text VARCHAR(200),
    exam_type_id       INTEGER      REFERENCES exam_types(exam_type_id),
    graduating_year    INTEGER,
    contact_mobile     VARCHAR(30),
    created_at         TIMESTAMPTZ  DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- MODULE M1 — CHALLENGES & RECOMMENDATIONS
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m1_challenges (
    challenge_entry_id SERIAL   PRIMARY KEY,
    submission_id      INTEGER  NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    challenge_id       INTEGER  REFERENCES challenge_types(challenge_id),
    challenge_free_text TEXT,                  -- for 'Other' entries
    remarks            TEXT
);

CREATE TABLE IF NOT EXISTS m1_recommendations (
    recommendation_id  SERIAL  PRIMARY KEY,
    submission_id      INTEGER NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    recommendation_text TEXT   NOT NULL
);

-- ---------------------------------------------------------------
-- MODULE M1 — WEL INDUSTRY PARTNERS (from WEL sheet right side)
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m1_wel_industry (
    wel_industry_id  SERIAL       PRIMARY KEY,
    submission_id    INTEGER      NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    industry_name    VARCHAR(250) NOT NULL,
    signed_mou       BOOLEAN,
    mou_status       VARCHAR(50),
    industry_region_id INTEGER    REFERENCES regions(region_id),
    industry_mobile  VARCHAR(30)
);

-- ---------------------------------------------------------------
-- MODULE M2 — TEACHING STAFF
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m2_staff_teaching (
    staff_id          SERIAL       PRIMARY KEY,
    submission_id     INTEGER      NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    full_name         VARCHAR(250) NOT NULL,
    staff_number      VARCHAR(50),
    date_of_birth     DATE,
    gender            VARCHAR(10)  CHECK (gender IN ('Male','Female')),
    programme_id      INTEGER      REFERENCES programmes(programme_id),
    programme_free_text VARCHAR(200),
    current_rank      VARCHAR(100),
    year_employed     SMALLINT,
    years_on_rank     SMALLINT,
    academic_qualification  VARCHAR(150),
    professional_qualification VARCHAR(150),
    school_days_expected SMALLINT,
    days_absent_with_permission SMALLINT DEFAULT 0,
    days_absent_without_permission SMALLINT DEFAULT 0,
    on_study_leave    BOOLEAN DEFAULT FALSE,
    study_leave_programme VARCHAR(200),
    created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- MODULE M2 — NON-TEACHING STAFF
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS m2_staff_nonteaching (
    staff_id          SERIAL       PRIMARY KEY,
    submission_id     INTEGER      NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
    full_name         VARCHAR(250) NOT NULL,
    staff_number      VARCHAR(50),
    date_of_birth     DATE,
    gender            VARCHAR(10)  CHECK (gender IN ('Male','Female')),
    assigned_role     VARCHAR(150),               -- Principal, Accountant, Secretary, etc.
    current_rank      VARCHAR(100),
    year_employed     SMALLINT,
    years_on_rank     SMALLINT,
    academic_qualification  VARCHAR(150),
    professional_qualification VARCHAR(150),
    school_days_expected SMALLINT,
    days_absent_with_permission SMALLINT DEFAULT 0,
    days_absent_without_permission SMALLINT DEFAULT 0,
    on_study_leave    BOOLEAN DEFAULT FALSE,
    study_leave_programme VARCHAR(200),
    created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- INDEXES
-- ---------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_submissions_inst   ON submissions(institution_id);
CREATE INDEX IF NOT EXISTS idx_submissions_module ON submissions(module_code);
CREATE INDEX IF NOT EXISTS idx_submissions_year   ON submissions(academic_year, semester);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON submissions(status);
CREATE INDEX IF NOT EXISTS idx_m1_enrolment_sub   ON m1_enrolment(submission_id);
CREATE INDEX IF NOT EXISTS idx_m1_pwsn_sub        ON m1_pwsn(submission_id);
CREATE INDEX IF NOT EXISTS idx_m2_teaching_sub    ON m2_staff_teaching(submission_id);
CREATE INDEX IF NOT EXISTS idx_m2_nonteaching_sub ON m2_staff_nonteaching(submission_id);
CREATE INDEX IF NOT EXISTS idx_users_role         ON users(role);
CREATE INDEX IF NOT EXISTS idx_institutions_region ON institutions(region_id);
CREATE INDEX IF NOT EXISTS idx_institutions_code  ON institutions(cssps_code);

-- ---------------------------------------------------------------
-- UPDATED_AT TRIGGER
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['submissions','m1_biodata'] LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger
            WHERE tgname = 'trg_' || t || '_updated_at'
        ) THEN
            EXECUTE format(
                'CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %s
                 FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
                t, t
            );
        END IF;
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------
-- VIEWS — useful shortcuts for the Shiny app
-- ---------------------------------------------------------------

CREATE OR REPLACE VIEW v_submission_status AS
SELECT
    s.submission_id,
    i.institution_name,
    i.cssps_code,
    r.region_name,
    s.module_code,
    s.academic_year,
    s.semester,
    s.status,
    s.version,
    s.submitted_at,
    s.approved_at,
    u_sub.full_name  AS submitted_by_name,
    u_appr.full_name AS approved_by_name,
    s.return_reason
FROM submissions s
JOIN institutions i  ON i.institution_id  = s.institution_id
JOIN regions r       ON r.region_id       = i.region_id
LEFT JOIN users u_sub  ON u_sub.user_id   = s.submitted_by
LEFT JOIN users u_appr ON u_appr.user_id  = s.approved_by;

CREATE OR REPLACE VIEW v_enrolment_summary AS
SELECT
    s.academic_year,
    s.semester,
    i.institution_id,
    i.institution_name,
    r.region_name,
    p.programme_code,
    p.programme_name,
    e.year_of_study,
    e.enrolment_male,
    e.enrolment_female,
    e.enrolment_total
FROM m1_enrolment e
JOIN submissions s ON s.submission_id = e.submission_id
JOIN institutions i ON i.institution_id = s.institution_id
JOIN regions r ON r.region_id = i.region_id
LEFT JOIN programmes p ON p.programme_id = e.programme_id
WHERE s.status = 'Approved';
