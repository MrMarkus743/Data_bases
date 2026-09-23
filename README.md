# Database Course Project

> Учебный проект по дисциплине «Базы данных». Реализация физической модели данных, DDL-скриптов и контейнеризации для СУБД PostgreSQL.

## Tech Stack
* **Database:** PostgreSQL 17+
* **Containerization:** Docker & Docker Desktop
* **Version Control:** Git / GitHub

## Repository Structure

```text
Data_bases/
├── Docker/                 # Конфигурация для запуска базы данных
├── homeworks/              # Выполненные практические работы
│   ├── hw_01/              # ДЗ №1: Модель данных и SQL-скрипт (Project Management)
│   └── hw_02/              # ДЗ №2: Текущая работа
├── Materials/              # Учебные материалы и лекции курса
├── tasks/                  # Файлы с требованиями к заданиям
│   ├── ДЗ_1.md             # Задание 1
│   ├── ДЗ_2.md             # Задание 2
│   └── ДЗ_семинар_3.md     # Задание 3
├── venv/                   # Виртуальное окружение Python (игнорируется Git)
├── .gitignore              # Правила исключения системных файлов из репозитория
└── README.md               # Главный файл документации
```

## Getting Started

### Prerequisites
* Установленный [Docker Desktop](https://www.docker.com/) с поддержкой WSL 2 / аппаратной виртуализации.

### Running the Database Container
1. Запустите существующий контейнер с базой данных:
   ```powershell
   docker start hw01-modeling-db