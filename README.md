# Database Course Project

![Database](https://img.shields.io/badge/database-PostgreSQL%2017%2B-336791.svg)
![Environment](https://img.shields.io/badge/environment-Docker%20Desktop-2496ED.svg)
![Client](https://img.shields.io/badge/client-DBeaver%20Community-382923.svg)

> Учебный проект по дисциплине «Базы данных». Проектирование реляционных схем, DDL-миграции, обеспечение ограничений целостности и контейнеризация PostgreSQL.

## О дисциплине
Курс посвящен практической работе с реляционными базами данных на примере PostgreSQL:
* Проектирование логических и физических схем данных (таблицы, связи, нормализация).
* Обеспечение целостности данных с помощью первичных/внешних ключей и ограничений `CHECK`.
* Изучение работы СУБД: индексы, транзакции, блокировки и чтение планов запросов.

## Tech Stack
* **Database:** PostgreSQL 17+
* **Containerization:** Docker & Docker Desktop
* **Client Tool:** DBeaver Community Edition
* **Version Control:** Git / GitHub

## Repository Structure

```text
Data_bases/
├── homeworks/                      # Практические и домашние задания
│   ├── hw_01/                      # ДЗ №1: Моделирование предметной области (Project Management)
│   │   ├── 01_create_tables.sql    # Базовый DDL-скрипт создания 6 таблиц и индексов
│   │   └── README.md               # Отчет по концептуальной, логической и физической моделям
│   └── hw_02/                      # ДЗ №2: Расширение схемы, M:N связи и валидация
│       ├── 01_add_tables.sql       # DDL добавления таблиц project_member и task_history
│       ├── 02_constraints_demo.sql # Скрипт демонстрации нарушений ограничений (PL/pgSQL)
│       └── README.md               # Отчет по ДЗ №2, анализ DROP CASCADE и сводная таблица
├── tasks/                          # Требования и методические указания
│   ├── ДЗ_1.md                     # Задание 1: Концептуальное и логическое проектирование
│   ├── ДЗ_2.md                     # Задание 2: Связи Many-to-Many и демонстрация ограничений
│   └── ДЗ_3.md                     # Задание 3: Базовый SQL, DDL, блокировки и Edge Cases
├── .gitignore                      # Список исключений для Git
└── README.md                       # Главная документация проекта
```

## Assignment Workflow & Engineering Standards

Каждое задание в репозитории выполняется по четкому инженерному регламенту:

1. **Schema Design & Normalization:** Выделение сущностей предметной области, связывание таблиц (1:N, M:N через junction tables) и приведение схемы к третьей нормальной форме (3НФ) без избыточности.
2. **Declarative Integrity:** Защита данных на уровне СУБД — строгие первичные (`PRIMARY KEY`) и внешние (`FOREIGN KEY`) ключи, правила удаления (`ON DELETE CASCADE` / `RESTRICT`), а также ограничения `CHECK`, `UNIQUE` и `NOT NULL`.
3. **Index Optimization:** Создание B-Tree индексов под частые запросы предметной области (по внешним ключам и полям сортировки), исключающих лишнее полное сканирование таблиц (`Seq Scan`).
4. **Validation & Exception Handling:** Проверка корректности ограничений через анонимные процедурные блоки `DO $$ ... EXCEPTION` (PL/pgSQL) с перехватом системных ошибок и выводом понятных бизнес-сообщений.
5. **Execution Reporting:** Составление отчета (`README.md` в папке задания) с описанием моделей, разбором поведения при `DROP CASCADE` и сводной таблицей перехваченных ошибок.

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
* **Database:** `project_db`
* **Username:** `Mark_V`
* **Password:** `12345`

### 3. Применение структуры базы данных
После подключения к базе в DBeaver откройте и выполните SQL-скрипты в следующем порядке:
1. `homeworks/hw_01/01_create_tables.sql` — создание базовых таблиц и связей.
2. `homeworks/hw_02/01_add_tables.sql` — добавление таблиц участников и истории задач.
