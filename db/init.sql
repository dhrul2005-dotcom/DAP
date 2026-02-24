-- =========================================
-- Enable UUID support
-- =========================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================================
-- USERS
-- =========================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT now()
);

-- =========================================
-- DATASETS
-- =========================================
CREATE TABLE IF NOT EXISTS datasets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size_bytes BIGINT,
    row_count BIGINT,
    column_count INT,
    status VARCHAR(30) DEFAULT 'UPLOADED',
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- =========================================
-- DATASET COLUMNS
-- =========================================
CREATE TABLE IF NOT EXISTS dataset_columns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    column_name VARCHAR(255) NOT NULL,
    inferred_type VARCHAR(50) NOT NULL,
    sample_values JSONB,
    null_ratio FLOAT,
    unique_ratio FLOAT,
    created_at TIMESTAMP DEFAULT now(),
    UNIQUE (dataset_id, column_name)
);

-- =========================================
-- PII DETECTION RESULTS
-- =========================================
CREATE TABLE IF NOT EXISTS pii_detection_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    column_id UUID NOT NULL REFERENCES dataset_columns(id) ON DELETE CASCADE,
    pii_label VARCHAR(50) NOT NULL,
    confidence INT CHECK (confidence BETWEEN 0 AND 100),
    detection_method VARCHAR(100),
    created_at TIMESTAMP DEFAULT now(),
    UNIQUE (dataset_id, column_id)
);

-- =========================================
-- ANONYMIZATION JOBS
-- =========================================
CREATE TABLE IF NOT EXISTS anonymization_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    status VARCHAR(30) DEFAULT 'PENDING',
    rules JSONB NOT NULL,
    output_file_path TEXT,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT now(),
    completed_at TIMESTAMP
);

-- =========================================
-- RISK REPORTS
-- =========================================
CREATE TABLE IF NOT EXISTS risk_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    job_id UUID REFERENCES anonymization_jobs(id) ON DELETE SET NULL,
    risk_level VARCHAR(20) NOT NULL,
    risk_score INT CHECK (risk_score BETWEEN 0 AND 100),
    metrics JSONB NOT NULL,
    attacker_view JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

-- =========================================
-- REPORTS
-- =========================================
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    job_id UUID REFERENCES anonymization_jobs(id) ON DELETE SET NULL,
    risk_report_id UUID REFERENCES risk_reports(id) ON DELETE SET NULL,
    report_type VARCHAR(50) DEFAULT 'PDF',
    file_path TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

-- =========================================
-- AUDIT LOGS
-- =========================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES datasets(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB,
    created_at TIMESTAMP DEFAULT now()
);

-- =========================================
-- SAMPLE DATA (≈50 USERS)
-- =========================================
INSERT INTO users (email, full_name)
SELECT
    'user' || g || '@example.com',
    'User ' || g
FROM generate_series(1, 50) g;

-- =========================================
-- SAMPLE DATASETS (≈50)
-- =========================================
INSERT INTO datasets (
    owner_id, name, original_filename, file_path,
    file_size_bytes, row_count, column_count, status
)
SELECT
    u.id,
    'Dataset ' || g,
    'dataset_' || g || '.csv',
    '/uploads/dataset_' || g || '.csv',
    100000 + g * 1000,
    500 + g * 10,
    6,
    'UPLOADED'
FROM users u
JOIN generate_series(1, 50) g
ON u.email = 'user' || g || '@example.com';

-- =========================================
-- DATASET COLUMNS
-- =========================================
INSERT INTO dataset_columns (
    dataset_id, column_name, inferred_type,
    sample_values, null_ratio, unique_ratio
)
SELECT
    d.id,
    col.column_name,
    col.inferred_type,
    col.sample_values,
    col.null_ratio,
    col.unique_ratio
FROM datasets d,
LATERAL (
    VALUES
    ('name', 'TEXT', '["Alice","Bob"]'::jsonb, 0.0, 0.95),
    ('email', 'TEXT', '["x@mail.com"]'::jsonb, 0.0, 1.0),
    ('age', 'INT', '[20,30]'::jsonb, 0.05, 0.60),
    ('city', 'TEXT', '["Delhi","Mumbai"]'::jsonb, 0.02, 0.40),
    ('salary', 'INT', '[40000]'::jsonb, 0.1, 0.80)
) AS col(column_name, inferred_type, sample_values, null_ratio, unique_ratio);

-- =========================================
-- PII DETECTION RESULTS
-- =========================================
INSERT INTO pii_detection_results (
    dataset_id, column_id, pii_label, confidence, detection_method
)
SELECT
    dc.dataset_id,
    dc.id,
    CASE
        WHEN dc.column_name IN ('name','email') THEN 'PII'
        WHEN dc.column_name IN ('age','city') THEN 'QUASI'
        ELSE 'SAFE'
    END,
    90,
    'rule_based'
FROM dataset_columns dc;

-- =========================================
-- ANONYMIZATION JOBS
-- =========================================
INSERT INTO anonymization_jobs (
    dataset_id, status, rules, output_file_path
)
SELECT
    id,
    'COMPLETED',
    '{"email":"MASK","age":"GENERALIZE"}'::jsonb,
    '/outputs/anonymized_' || id || '.csv'
FROM datasets;

-- =========================================
-- RISK REPORTS (≈50)
-- =========================================
INSERT INTO risk_reports (
    dataset_id, job_id, risk_level, risk_score, metrics, attacker_view
)
SELECT
    d.id,
    j.id,
    CASE
        WHEN random() < 0.33 THEN 'LOW'
        WHEN random() < 0.66 THEN 'MEDIUM'
        ELSE 'HIGH'
    END,
    (40 + random() * 60)::INT,
    jsonb_build_object('k_anonymity',(3+random()*5)::INT),
    jsonb_build_object('quasi_identifiers',ARRAY['age','city'])
FROM datasets d
JOIN anonymization_jobs j ON j.dataset_id = d.id;

-- =========================================
-- AUDIT LOGS
-- =========================================
INSERT INTO audit_logs (
    dataset_id, user_id, action, details
)
SELECT
    d.id,
    d.owner_id,
    'DATASET_PROCESSED',
    '{"status":"COMPLETED"}'::jsonb
FROM datasets d;