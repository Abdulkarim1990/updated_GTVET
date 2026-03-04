-- =============================================================
-- Seed: Reference / lookup tables
-- Exam types, impairment categories, challenge types,
-- default submission windows, default admin user
-- =============================================================

-- ---------------------------------------------------------------
-- Exam types (from OFFICE USE sheet)
-- ---------------------------------------------------------------
INSERT INTO exam_types (exam_type_name) VALUES
  ('PROFICIENCY I - TEU'),
  ('PROFICIENCY II - TEU'),
  ('CERTIFICATE II - TEU'),
  ('PROFICIENCY I - NVTI'),
  ('PROFICIENCY II - NVTI'),
  ('CERTIFICATE I - NVTI'),
  ('CERTIFICATE II - NVTI'),
  ('CERTIFICATE II (CORE) - CTVET'),
  ('NATIONAL PROFICIENCY I - CTVET'),
  ('NATIONAL PROFICIENCY II - CTVET'),
  ('NATIONAL CERTIFICATE I - CTVET'),
  ('NATIONAL CERTIFICATE II - CTVET')
ON CONFLICT (exam_type_name) DO NOTHING;

-- ---------------------------------------------------------------
-- Impairment categories (from OFFICE USE sheet)
-- ---------------------------------------------------------------
INSERT INTO impairment_categories (impairment_name) VALUES
  ('Visual Impairment'),
  ('Hearing Impairment'),
  ('Autism'),
  ('Cerebral Palsy'),
  ('Down Syndrome'),
  ('Intellectual Disability'),
  ('Mental Disability'),
  ('Attention Deficit Disorders'),
  ('Physically Challenged')
ON CONFLICT (impairment_name) DO NOTHING;

-- ---------------------------------------------------------------
-- Challenge types (from OFFICE USE sheet)
-- ---------------------------------------------------------------
INSERT INTO challenge_types (challenge_name) VALUES
  ('Delay in release of subvention (Free TVET)'),
  ('Encroachment of Institute Land'),
  ('Inadequate Furniture'),
  ('Inadequate Instructors/Teacher (Core)'),
  ('Inadequate Instructors/Teacher (Technical)'),
  ('Inadequate Workshops'),
  ('Indequate Tools & Equipment'),
  ('Insufficient Funds for Training Materials (Free TVET)'),
  ('Lack of Assembly Hall'),
  ('Lack of Day to Day Running Vehicle for the Institute'),
  ('Lack of Dining Hall/Kitchen'),
  ('Lack of Sickbay'),
  ('No Training Textbooks'),
  ('Recreational Land'),
  ('Staff Accommodation'),
  ('Other (specify in other challenge column on same row)')
ON CONFLICT (challenge_name) DO NOTHING;

-- ---------------------------------------------------------------
-- Submission windows for 2025/2026 academic year
-- Semester 1: Sep 2025 – Jan 2026; Semester 2: Feb – Aug 2026
-- Windows open 3 weeks before semester end for data entry
-- ---------------------------------------------------------------
INSERT INTO submission_windows (module_code, academic_year, semester, open_date, close_date)
VALUES
  -- Semester 1 windows (reporting opens Jan 2026)
  ('M1', '2025/2026', 1, '2026-01-05', '2026-02-15'),
  ('M2', '2025/2026', 1, '2026-01-05', '2026-02-15'),
  -- Semester 2 windows (reporting opens Aug 2026)
  ('M1', '2025/2026', 2, '2026-07-01', '2026-08-31'),
  ('M2', '2025/2026', 2, '2026-07-01', '2026-08-31')
ON CONFLICT (module_code, academic_year, semester) DO NOTHING;

-- ---------------------------------------------------------------
-- Default admin user
-- Password: Admin@GTVET2025  (must be changed on first login)
-- Hash generated with: SELECT crypt('Admin@GTVET2025', gen_salt('bf', 12));
-- ---------------------------------------------------------------
INSERT INTO users (username, email, password_hash, full_name, role, is_active, must_change_pw)
VALUES (
  'admin',
  'admin@gtvet.edu.gh',
  crypt('Admin@GTVET2025', gen_salt('bf', 12)),
  'System Administrator',
  'admin',
  TRUE,
  TRUE
)
ON CONFLICT (username) DO NOTHING;
