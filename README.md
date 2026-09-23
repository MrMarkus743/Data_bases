# Database Course Project

> Учебный проект по дисциплине «Базы данных». Реализация физической модели данных, DDL-скриптов и контейнеризации для СУБД PostgreSQL.

## Tech Stack
* **Database:** PostgreSQL 17+
* **Containerization:** Docker & Docker Desktop
* **Version Control:** Git / GitHub

## Repository Structure

```text
Data_bases/
├── homeworks/              # Практические и домашние задания
│   ├── hw_01/              # ДЗ №1: Моделирование предметной области (Project Management)
│   └── hw_02/              # ДЗ №2: Практическая работа
├── tasks/                  # Условия и требования к заданиям
│   ├── ДЗ_1.md
│   ├── ДЗ_2.md
│   └── ДЗ_семинар_3.md
├── .gitignore              # Список исключений для Git
└── README.md               # Документация проекта
```

## Getting Started

### Prerequisites
* Установленный [Docker Desktop](https://www.docker.com/) с поддержкой WSL 2 / аппаратной виртуализации.

### Running the Database Container
1. Запустите существующий контейнер с базой данных:
   ```powershell
   docker start hw01-modeling-db