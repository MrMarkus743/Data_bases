# Database Course Project

![Database](https://img.shields.io/badge/database-PostgreSQL%2017%2B-336791.svg)
![Environment](https://img.shields.io/badge/environment-Docker%20Desktop-2496ED.svg)
![Client](https://img.shields.io/badge/client-DBeaver%20Community-382923.svg)

> Учебный проект по дисциплине «Базы данных».

## Tech Stack
* **Database:** PostgreSQL 16+
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
│   ├── hw_03/                      # ДЗ №1: Моделирование предметной области (Project Management)
│   │   ├── 01_tasks.sql            # Запросы по таске
│   │   └── README.md               # Отчет с описанием работы всех запросов
│   └── hw_04/                      # ДЗ №4: Сложные выборки, агрегация и профилирование (EXPLAIN)
│       ├── 01_queries.sql          # Решения 12 аналитических задач на учебной базе demo
│       └── README.md               # Отчет с профилями планов выполнения (ANALYZE, BUFFERS)
├── tasks/                          # Требования и методические указания
│   ├── ДЗ_1.md                     # Задание 1: Концептуальное и логическое проектирование
│   ├── ДЗ_2.md                     # Задание 2: Связи Many-to-Many и демонстрация ограничений
│   ├── ДЗ_3.md                     # Задание 3: Базовый SQL, DDL, блокировки и Edge Cases
│   └── ДЗ_4.md                     # Задание 4: Аналитические запросы, оконные функции и EXPLAIN
├── .gitignore                      # Список исключений для Git
└── README.md                       # Главная документация проекта
```

## Getting Started

### Запуск контейнера PostgreSQL в Docker

```powershell
docker-compose up -d
```