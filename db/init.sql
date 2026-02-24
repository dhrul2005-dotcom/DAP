CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150) UNIQUE,
    password_hash TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE datasets (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    name VARCHAR(150),
    file_path TEXT,
    total_rows INT,
    total_columns INT,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE dataset_columns (
    id SERIAL PRIMARY KEY,
    dataset_id INT REFERENCES datasets(id),
    column_name VARCHAR(100),
    data_type VARCHAR(50),
    pii_label VARCHAR(50),
    confidence FLOAT
);

CREATE TABLE anonymization_rules (
    id SERIAL PRIMARY KEY,
    dataset_id INT REFERENCES datasets(id),
    column_name VARCHAR(100),
    action VARCHAR(50),
    mode VARCHAR(50)
);

CREATE TABLE jobs (
    id SERIAL PRIMARY KEY,
    dataset_id INT REFERENCES datasets(id),
    status VARCHAR(50),
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE TABLE anonymized_outputs (
    id SERIAL PRIMARY KEY,
    job_id INT REFERENCES jobs(id),
    output_file_path TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE risk_reports (
    id SERIAL PRIMARY KEY,
    dataset_id INT REFERENCES datasets(id),
    job_id INT REFERENCES jobs(id),
    risk_score INT,
    risk_level VARCHAR(20),
    created_at TIMESTAMP DEFAULT now()
);