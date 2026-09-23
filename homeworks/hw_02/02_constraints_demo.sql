-- ====================================================================
-- ДЗ №2. Часть 2: Демонстрация нарушений ограничений целостности
-- ====================================================================

-- 1. Нарушение CHECK: попытка установить дедлайн раньше даты старта проекта
DO $$
BEGIN
    INSERT INTO project (name, start_date, deadline)
    VALUES ('Некорректный проект по датам', '2026-11-01', '2026-10-01');
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'Бизнес-ошибка: Дедлайн проекта не может быть раньше даты его начала. Техническая ошибка: %', SQLERRM;
END;
$$;

-- 2. Нарушение FOREIGN KEY: привязка задачи к несуществующему проекту
DO $$
BEGIN
    INSERT INTO task (project_id, status_id, title, estimated_hours)
    VALUES (999999, 1, 'Задача для несуществующего проекта', 8.0);
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Бизнес-ошибка: Нельзя создать задачу в несуществующем проекте. Техническая ошибка: %', SQLERRM;
END;
$$;

-- 3. Нарушение UNIQUE: попытка добавить дубликат почты сотрудника
DO $$
BEGIN
    -- Вставляем первого сотрудника
    INSERT INTO employee (first_name, last_name, email)
    VALUES ('Иван', 'Иванов', 'ivan.unique@example.com')
    ON CONFLICT (email) DO NOTHING;

    -- Попытка вставить второго сотрудника с тем же email
    INSERT INTO employee (first_name, last_name, email)
    VALUES ('Петр', 'Сидоров', 'ivan.unique@example.com');
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Бизнес-ошибка: Пользователь с таким адресом электронной почты уже зарегистрирован. Техническая ошибка: %', SQLERRM;
END;
$$;

-- 4. Нарушение NOT NULL: создание сотрудника без обязательной фамилии
DO $$
BEGIN
    INSERT INTO employee (first_name, last_name, email)
    VALUES ('Алексей', NULL, 'alex.noname@example.com');
EXCEPTION
    WHEN not_null_violation THEN
        RAISE NOTICE 'Бизнес-ошибка: Фамилия сотрудника является обязательным полем и не может оставаться пустой. Техническая ошибка: %', SQLERRM;
END;
$$;

-- 5. Нарушение PRIMARY KEY: повторное добавление сотрудника в тот же проект (составной PK в M:N)
DO $$
DECLARE
    v_project_id INT;
    v_employee_id INT;
BEGIN
    -- Подготовка тестовых данных
    INSERT INTO project (name, start_date, deadline)
    VALUES ('Демо Проект для PK', '2026-01-01', '2026-12-31')
    ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
    RETURNING project_id INTO v_project_id;

    INSERT INTO employee (first_name, last_name, email)
    VALUES ('Сергей', 'Павлов', 'sergey.pk@example.com')
    ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email
    RETURNING employee_id INTO v_employee_id;

    -- Первое добавление участника
    INSERT INTO project_member (project_id, employee_id, role)
    VALUES (v_project_id, v_employee_id, 'Developer')
    ON CONFLICT DO NOTHING;

    -- Попытка повторного добавления того же сотрудника в тот же проект
    INSERT INTO project_member (project_id, employee_id, role)
    VALUES (v_project_id, v_employee_id, 'QA');
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Бизнес-ошибка: Сотрудник уже назначен участником этого проекта (дублирование первичного ключа). Техническая ошибка: %', SQLERRM;
END;
$$;