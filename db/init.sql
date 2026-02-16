-- Example matching your table structure:
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    password VARCHAR(100),
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100),
    description TEXT,
    created_by INT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    project_id INT,
    title VARCHAR(100),
    status VARCHAR(50),
    assigned_to INT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    task_id INT,
    user_id INT,
    comment TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- Sample data
INSERT INTO users(name, email, password) VALUES
('Dhruva', 'dhruva@example.com', '12345');

-- Insert sample projects
INSERT INTO projects(title, description, created_by) VALUES
('Project A', 'First project', 1),
('Project B', 'Second project', 1);

-- Insert sample tasks
INSERT INTO tasks(project_id, title, status, assigned_to) VALUES
(1, 'Task 1', 'Pending', 1),
(1, 'Task 2', 'Completed', 1),
(2, 'Task 3', 'Pending', 1);

-- Insert sample comments
INSERT INTO comments(task_id, user_id, comment) VALUES
(1, 1, 'Started working on Task 1'),
(2, 1, 'Task 2 completed successfully'),
(3, 1, 'Pending Task 3');
