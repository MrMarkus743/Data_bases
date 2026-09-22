-- Удаляем таблицы в правильном порядке (сначала зависимые, чтобы не было конфликтов ключей)
DROP TABLE IF EXISTS comment CASCADE;
DROP TABLE IF EXISTS assignment CASCADE;
DROP TABLE IF EXISTS task CASCADE;
DROP TABLE IF EXISTS status CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS project CASCADE;

-- 1. Таблица проектов
CREATE TABLE project (
    project_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    deadline DATE NOT NULL,
    CHECK (deadline >= start_date) -- Проверка, что дедлайн не раньше даты начала
);

-- 2. Таблица сотрудников
CREATE TABLE employee (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- 3. Справочник статусов задач
CREATE TABLE status (
    status_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- 4. Таблица задач (связана с проектом и статусом)
CREATE TABLE task (
    task_id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    estimated_hours DECIMAL(5,2) CHECK (estimated_hours > 0),
    FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES status(status_id) ON DELETE RESTRICT
);

-- 5. Промежуточная таблица для связи «многие ко многим» (задачи и сотрудники)
CREATE TABLE assignment (
    assignment_id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    FOREIGN KEY (task_id) REFERENCES task(task_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE CASCADE
);

-- 6. Таблица комментариев к задачам
CREATE TABLE comment (
    comment_id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES task(task_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE CASCADE
);

-- Создаем индексы на внешние ключи для ускорения работы запросов
CREATE INDEX idx_task_project_id ON task(project_id);
CREATE INDEX idx_task_status_id ON task(status_id);
CREATE INDEX idx_assignment_task_id ON assignment(task_id);
CREATE INDEX idx_assignment_employee_id ON assignment(employee_id);
CREATE INDEX idx_comment_task_id ON comment(task_id);