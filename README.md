# Database Course Project

![Database](https://img.shields.io/badge/database-PostgreSQL%2017%2B-336791.svg)
![Environment](https://img.shields.io/badge/environment-Docker%20Desktop-2496ED.svg)
![Client](https://img.shields.io/badge/client-DBeaver%20Community-382923.svg)

> Учебный проект по дисциплине «Базы данных». Проектирование реляционных схем, DDL-миграции, обеспечение ограничений целостности, профилирование планов выполнения (EXPLAIN) и контейнеризация PostgreSQL.

## О дисциплине
Курс посвящен практической работе с реляционными базами данных на примере PostgreSQL:
* Проектирование логических и физических схем данных (таблицы, связи, нормализация).
* Обеспечение целостности данных с помощью первичных/внешних ключей и ограничений `CHECK`.
* Изучение работы СУБД: физическое хранение страниц, индексы, блокировки, чтение планов запросов и оптимизация производительности.

## Tech Stack
* **Database:** PostgreSQL 17+
* **Containerization:** Docker & Docker Desktop
* **Client Tool:** DBeaver Community Edition
* **Version Control:** Git / GitHub

## Repository Structure

```text
Data_bases/
├── Docker/                         # Конфигурационные файлы Docker-окружения
├── homeworks/                      # Практические и домашние задания
│   ├── hw_01/                      # ДЗ №1: Моделирование предметной области (Project Management)
│   │   ├── 01_create_tables.sql    # Базовый DDL-скрипт создания 6 таблиц и индексов
│   │   └── README.md               # Отчет по концептуальной, логической и физической моделям
│   ├── hw_02/                      # ДЗ №2: Расширение схемы, M:N связи и валидация
│   │   ├── 01_add_tables.sql       # DDL добавления таблиц project_member и task_history
│   │   ├── 02_constraints_demo.sql # Скрипт демонстрации нарушений ограничений (PL/pgSQL)
│   │   └── README.md               # Отчет по ДЗ №2, анализ DROP CASCADE и сводная таблица
│   └── hw_04/                      # ДЗ №4: Сложные выборки, агрегация и профилирование (EXPLAIN)
│       ├── 01_queries.sql          # Решения 12 аналитических задач на учебной базе demo
│       └── README.md               # Отчет с профилями планов выполнения (ANALYZE, BUFFERS)
├── Materials/                      # Учебные материалы, лекции и конспекты семинаров
│   ├── sem_1/                      # Семинар 1: Основы реляционных моделей
│   ├── sem_2/                      # Семинар 2: Ограничения целостности и DDL
│   ├── sem_3/                      # Семинар 3: Дисковое хранение, MVCC, дамп demo
│   │   └── Конспект лекции №3.md   # Архитектура диск-ориентированных СУБД и slotted pages
│   └── sem_4/                      # Семинар 4: GROUP BY, JOIN, Окна, CTE, EXPLAIN
│       ├── sql_demo_setup.sql      # Скрипт создания учебной схемы sql_demo
│       ├── Семинар 4_3. CTE_LATERAL_EXPLAIN_оптимизация.md
│       ├── Теория_JOIN_и_оконные_функции.md
│       └── Теория_Оконные_функции_PostgreSQL.md
├── tasks/                          # Требования и методические указания
│   ├── ДЗ_1.md                     # Задание 1: Концептуальное и логическое проектирование
│   ├── ДЗ_2.md                     # Задание 2: Связи Many-to-Many и демонстрация ограничений
│   ├── ДЗ_3.md                     # Задание 3: Базовый SQL, DDL, блокировки и Edge Cases
│   └── ДЗ_4.md                     # Задание 4: Аналитические запросы, оконные функции и EXPLAIN
├── .gitignore                      # Список исключений для Git
└── README.md                       # Главная документация проекта
```

## Assignment Workflow & Engineering Standards

Каждое задание в репозитории выполняется по четкому инженерному регламенту:

1. **Schema Design & Normalization:** Выделение сущностей предметной области, связывание таблиц (1:N, M:N через junction tables) и приведение схемы к третьей нормальной форме (3НФ) без избыточности.
2. **Declarative Integrity:** Защита данных на уровне СУБД — строгие первичные (`PRIMARY KEY`) и внешние (`FOREIGN KEY`) ключи, правила удаления (`ON DELETE CASCADE` / `RESTRICT`), а также ограничения `CHECK`, `UNIQUE` и `NOT NULL`.
3. **Index Optimization & Execution Profiling:** Создание B-Tree индексов под частые запросы, оптимизация предикатов (Sargability) и профилирование планов запросов через `EXPLAIN (ANALYZE, BUFFERS)` с контролем обращений к дисковым страницам (`shared hit/read`).
4. **Validation & Exception Handling:** Проверка корректности ограничений через анонимные процедурные блоки `DO $$ ... EXCEPTION` (PL/pgSQL) с перехватом системных ошибок и выводом понятных бизнес-сообщений.
5. **Execution Reporting:** Составление отчета (`README.md` в папке задания) с описанием моделей, пошаговыми выводами планов и аналитическими резюме.
6. **Git Standards:** Фиксация каждого этапа работы осмысленными коммитами по стандарту Conventional Commits (`feat:`, `docs:`, `fix:`, `refactor:`).

## Getting Started

### 1. Запуск контейнера PostgreSQL в Docker

**Если контейнер запускается впервые на новой машине:**
```powershell
docker run -d --name hw01-modeling-db -p 6438:5432 -e POSTGRES_DB=project_db -e POSTGRES_USER=Mark_V -e POSTGRES_PASSWORD=12345 postgres:17
```

**Если контейнер уже был создан ранее:**
```powershell
docker start hw01-modeling-db
```

### 2. Параметры подключения через DBeaver
* **Host:** `localhost`
* **Port:** `6438`
* **Database:** `project_db` (для ДЗ №1 и №2) или `demo` (для ДЗ №3 и №4)
* **Username:** `Mark_V`
* **Password:** `12345`

### 3. Применение структуры и запуск запросов
* **Для ДЗ №1 и №2 (схема управления проектами):**
  1. `homeworks/hw_01/01_create_tables.sql` — базовые таблицы и связи.
  2. `homeworks/hw_02/01_add_tables.sql` — таблицы участников и истории задач.
  3. `homeworks/hw_02/02_constraints_demo.sql` — проверка работы ограничений.
* **Для ДЗ №4 (аналитика по авиаперевозкам):**
  1. Подключиться к