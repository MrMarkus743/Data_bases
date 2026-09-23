-- ====================================================================
-- ДЗ №2. Часть 1: Дополнение схемы новыми сущностями и индексами
-- ====================================================================

-- 1. Промежуточная таблица M:N между Project и Employee
CREATE TABLE IF NOT EXISTS project_member (
    project_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'Developer',
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, employee_id),
    FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE CASCADE,
    CONSTRAINT chk_member_role CHECK (role IN ('Manager', 'Developer', 'QA', 'DevOps', 'Designer'))
);

-- 2. Таблица аудита и истории изменения статусов задач (под запрос №4 из ДЗ №1)
CREATE TABLE IF NOT EXISTS task_history (
    history_id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    changed_by_employee_id INTEGER NOT NULL,
    change_reason TEXT,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES task(task_id) ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES status(status_id) ON DELETE RESTRICT,
    FOREIGN KEY (changed_by_employee_id) REFERENCES employee(employee_id) ON DELETE RESTRICT
);

-- 3. Оптимизация индексов под частые запросы из ДЗ №1:
-- Для запроса №1 (задачи конкретного проекта с их статусами)
CREATE INDEX IF NOT EXISTS idx_task_project_status ON task(project_id, status_id);

-- Для запроса №4 (история изменения статуса задачи с сортировкой по времени)
CREATE INDEX IF NOT EXISTS idx_task_history_task_time ON task_history(task_id, changed_at DESC);

-- Для быстрого поиска проектов конкретного сотрудника через M:N таблицу
CREATE INDEX IF NOT EXISTS idx_project_member_employee ON project_member(employee_id);