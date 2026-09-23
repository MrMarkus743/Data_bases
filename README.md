# Database Course Project

> Учебный проект по дисциплине «Базы данных». Проектирование реляционных схем, DDL-миграции, обеспечение ограничений целостности и контейнеризация PostgreSQL.

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
│   ├── ДЗ_1.md
│   ├── ДЗ_2.md
│   └── ДЗ_семинар_3.md
├── .gitignore                      # Список исключений для Git
└── README.md                       # Главная документация проекта