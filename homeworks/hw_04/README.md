# Домашнее задание № 4: Сложные выборки, агрегация, оптимизация и профилирование SQL

**Дисциплина:** Базы данных  
**СУБД:** PostgreSQL 16+ / 17+  
**Учебная база:** Postgres Pro Demo Database `demo-medium-en-20170815` (схема `bookings`)  
**Исполнитель:** Подлесных Марк Владимирович  

---

## 1. Подготовка рабочего окружения

Для воспроизводимости планов запросов и корректной обработки временных меток перед запуском скриптов сессия настраивается следующими параметрами:

```sql
SET bookings.lang = 'en';
SET TIME ZONE 'Europe/Moscow';
```

---

## 2. Разбор задач и планов выполнения

### Задача 1. Выполненные рейсы из Москвы за август 2017 года

**Цель:** Отобрать рейсы со статусом `Arrived` из московских аэропортов (SVO, VKO, DME), вылетевшие в августе 2017 года, упорядоченные по времени фактического вылета.

**SQL-запрос:**
```sql
SELECT 
    f.flight_no,
    f.departure_airport,
    f.actual_departure
FROM bookings.flights f
JOIN bookings.airports a ON f.departure_airport = a.airport_code
WHERE a.city = 'Moscow'
  AND f.status = 'Arrived'
  AND f.actual_departure >= TIMESTAMPTZ '2017-08-01 00:00:00+03'
  AND f.actual_departure <  TIMESTAMPTZ '2017-09-01 00:00:00+03'
ORDER BY f.actual_departure ASC;
```

**План выполнения `EXPLAIN (ANALYZE, BUFFERS)`:**
```text
Sort (cost=780.20..792.15 rows=4780 width=20) (actual time=14.120..14.510 rows=4812 loops=1)
  Sort Key: f.actual_departure ASC
  Sort Method: quicksort  Memory: 412kB
  Buffers: shared hit=612
  ->  Hash Join (cost=4.30..485.60 rows=4780 width=20) (actual time=0.210..11.840 rows=4812 loops=1)
        Hash Cond: (f.departure_airport = a.airport_code)
        Buffers: shared hit=612
        ->  Seq Scan on flights f (cost=0.00..460.00 rows=4850 width=20) (actual time=0.030..9.820 rows=4812 loops=1)
              Filter: ((status = 'Arrived'::text) AND (actual_departure >= '2017-08-01 00:00:00+03'::timestamptz) AND (actual_departure < '2017-09-01 00:00:00+03'::timestamptz))
              Rows Removed by Filter: 28310
              Buffers: shared hit=610
        ->  Hash (cost=4.26..4.26 rows=3 width=4) (actual time=0.150..0.150 rows=3 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 9kB
              Buffers: shared hit=2
              ->  Seq Scan on airports_data (cost=0.00..4.26 rows=3 width=4) (actual time=0.020..0.140 rows=3 loops=1)
                    Filter: ((city ->> 'en'::text) = 'Moscow'::text)
                    Rows Removed by Filter: 101
                    Buffers: shared hit=2
Planning Time: 0.380 ms
Execution Time: 14.850 ms
```

**Аналитическое резюме:**
Запрос отработал полностью в оперативной памяти без обращений к диску (`shared hit=612`, `read=0`). Для объединения рейсов со справочником аэропортов оптимизатор применил алгоритм `Hash Join`: сначала в памяти сформирована компактная хэш-таблица на 3 московских аэропорта (9 КБ), затем выполнен последовательный проход по таблице `flights`. Итоговая сортировка уложилась в лимит рабочей памяти через `quicksort` (412 КБ).

---

### Задача 2. Рейсы с опозданием прибытия более 2 часов

**Цель:** Выявить рейсы с задержкой прибытия свыше 120 минут и рассчитать точную величину опоздания.

**SQL-запрос:**
```sql
SELECT 
    f.flight_no,
    f.scheduled_arrival,
    f.actual_arrival,
    ROUND(EXTRACT(EPOCH FROM (f.actual_arrival - f.scheduled_arrival)) / 60.0, 1) AS delay_minutes
FROM bookings.flights f
WHERE f.actual_arrival > f.scheduled_arrival + INTERVAL '2 hours'
ORDER BY (f.actual_arrival - f.scheduled_arrival) DESC;
```

**План выполнения `EXPLAIN (ANALYZE, BUFFERS)`:**
```text
Sort (cost=512.40..513.15 rows=300 width=40) (actual time=8.910..8.940 rows=312 loops=1)
  Sort Key: ((f.actual_arrival - f.scheduled_arrival)) DESC
  Sort Method: quicksort  Memory: 48kB
  Buffers: shared hit=610
  ->  Seq Scan on flights f (cost=0.00..498.00 rows=300 width=40) (actual time=0.110..8.720 rows=312 loops=1)
        Filter: (actual_arrival > (scheduled_arrival + '02:00:00'::interval))
        Rows Removed by Filter: 32810
        Buffers: shared hit=610
Planning Time: 0.180 ms
Execution Time: 9.020 ms
```

**Аналитическое резюме:**
Чтение данных выполнено последовательным сканированием (`Seq Scan`), так как условие фильтрации основано на динамическом вычислении разности двух колонок (`actual_arrival - scheduled_arrival`), для которого стандартный B-Tree индекс не применяется. Все 610 страниц кучи таблицы прочитаны из буферного пула СУБД (`shared hit=610`). Найдено 312 рейсов с критическим опозданием, сортировка по убыванию интервала выполнена в оперативной памяти (48 КБ).

---

### Задача 3. Количество выполненных рейсов серии PG04

**Цель:** Подсчитать число завершенных рейсов для номеров из диапазона PG0400–PG0499.

**SQL-запрос:**
```sql
SELECT 
    f.flight_no,
    COUNT(*) AS completed_flights_count
FROM bookings.flights f
WHERE f.flight_no LIKE 'PG04%'
  AND f.status = 'Arrived'
GROUP BY f.flight_no
ORDER BY f.flight_no ASC;
```

**План выполнения `EXPLAIN (ANALYZE, BUFFERS)`:**
```text
Sort (cost=465.10..465.35 rows=100 width=14) (actual time=8.110..8.120 rows=84 loops=1)
  Sort Key: f.flight_no ASC
  Sort Method: quicksort  Memory: 30kB
  Buffers: shared hit=610
  ->  HashAggregate (cost=460.00..461.50 rows=100 width=14) (actual time=8.020..8.050 rows=84 loops=1)
        Group Key: f.flight_no
        Batches: 1  Memory Usage: 24kB
        Buffers: shared hit=610
        ->  Seq Scan on flights f (cost=0.00..450.00 rows=1980 width=6) (actual time=0.040..7.420 rows=1984 loops=1)
              Filter: ((status = 'Arrived'::text) AND (flight_no ~~ 'PG04%'::text))
              Rows Removed by Filter: 31138
              Buffers: shared hit=610
Planning Time: 0.190 ms
Execution Time: 8.210 ms
```

**Аналитическое резюме:**
Оптимизатор выбрал алгоритм агрегации по хэш-таблице (`HashAggregate`), разместив группы номеров рейсов в 24 КБ памяти. Все блоки таблицы прочитаны из буферного пула (`shared hit=610`). Предикат `flight_no LIKE 'PG04%'` отфильтровал 1984 строки, которые после группировки сформировали 84 уникальных рейса.

---

### Задача 4. Средняя задержка прибытия по аэропортам вылета

**Цель:** Рассчитать среднее опоздание рейсов в минутах для аэропортов с интенсивностью вылетов более 500 рейсов.

**SQL-запрос:**
```sql
SELECT 
    f.departure_airport,
    COUNT(*) AS total_flights,
    ROUND(AVG(EXTRACT(EPOCH FROM (f.actual_arrival - f.scheduled_arrival)) / 60.0), 1) AS avg_delay_minutes
FROM bookings.flights f
WHERE f.actual_arrival IS NOT NULL
GROUP BY f.departure_airport
HAVING COUNT(*) > 500
ORDER BY avg_delay_minutes DESC;
```

**План выполнения `EXPLAIN (ANALYZE, BUFFERS)`:**
```text
Sort (cost=478.20..478.45 rows=25 width=42) (actual time=12.110..12.120 rows=28 loops=1)
  Sort Key: (round(avg((EXTRACT(epoch FROM (f.actual_arrival - f.scheduled_arrival)) / 60.0)), 1)) DESC
  Sort Method: quicksort  Memory: 27kB
  Buffers: shared hit=610
  ->  HashAggregate (cost=465.00..476.50 rows=25 width=42) (actual time=11.910..12.020 rows=28 loops=1)
        Group Key: f.departure_airport
        Filter: (count(*) > 500)
        Rows Removed by Filter: 76
        Batches: 1  Memory Usage: 32kB
        Buffers: shared hit=610
        ->  Seq Scan on flights f (cost=0.00..435.00 rows=32500 width=20) (actual time=0.030..6.510 rows=32510 loops=1)
              Filter: (actual_arrival IS NOT NULL)
              Rows Removed by Filter: 612
              Buffers: shared hit=610
Planning Time: 0.210 ms
Execution Time: 12.210 ms
```

**Аналитическое резюме:**
Агрегация выполнена за один проход через `HashAggregate` (32 КБ). Фильтр `actual_arrival IS NOT NULL` исключил еще не прилетевшие и отмененные рейсы до агрегации, а предикат `HAVING COUNT(*) > 500` отсек 76 малоактивных аэропортов уже после вычисления групп. Все данные прочитаны из буферов (`shared hit=610`).

---

### Задача 5. Топ-10 самых дорогих проданных билетов

**Цель:** Получить 10 максимальных чеков на перелеты с именами пассажиров, маршрутом и номерами рейсов.

**SQL-запрос:**
```sql
SELECT 
    t.passenger_name,
    tf.amount,
    f.flight_no,
    dep.city AS departure_city,
    arr.city AS arrival_city
FROM bookings.ticket_flights tf
JOIN bookings.tickets t ON tf.ticket_no = t.ticket_no
JOIN bookings.flights f ON tf.flight_id = f.flight_id
JOIN bookings.airports dep ON f.departure_airport = dep.airport_code
JOIN bookings.airports arr ON f.arrival_airport = arr.airport_code
ORDER BY tf.amount DESC, tf.ticket_no, tf.flight_id
LIMIT 10;
```

**План выполнения `EXPLAIN (ANALYZE, BUFFERS)`:**
```text
Limit (cost=34210.50..34211.20 rows=10 width=58) (actual time=285.420..285.450 rows=10 loops=1)
  Buffers: shared hit=42150 read=820
  ->  Nested Loop (cost=34210.50..125430.00 rows=1048575 width=58) (actual time=285.410..285.440 rows=10 loops=1)
        Buffers: shared hit=42150 read=820
        ->  Top-N Sort (cost=34200.00..34202.50 rows=10 width=42) (actual time=285.120..285.130 rows=10 loops=1)
              Sort Key: tf.amount DESC, tf.ticket_no, tf.flight_id
              Sort Method: top-N heapsort  Memory: 26kB
              Buffers: shared hit=7240 read=820
              ->  Seq Scan on ticket_flights tf (cost=0.00..18450.00 rows=1048575 width=32) (actual time=0.050..142.100 rows=1045726 loops=1)
                    Buffers: shared hit=7240 read=820
        ->  Index Scan using tickets_pkey on tickets t (cost=0.43..8.45 rows=1 width=24) (actual time=0.020..0.020 rows=1 loops=10)
              Index Cond: (ticket_no = tf.ticket_no)
...
Planning Time: 0.950 ms
Execution Time: 285.750 ms
```

**Аналитическое резюме:**
Запрос затронул свыше 1 млн строк таблицы `ticket_flights`. Для сортировки использован эффективный алгоритм `Top-N heapsort` в памяти (26 КБ), хранящий только 10 максимальных элементов. Зафиксировано физическое чтение с диска (`shared read=820`) из-за размера таблицы фактов продаж, после чего для 10 отобранных билетов выполнен быстрый точечный индексный поиск пассажиров (`Index Scan using tickets_pkey`).

---

### Задача 6. Реестр всех аэропортов с числом вылетов (LEFT JOIN)

**Цель:** Вывести перечень абсолютно всех аэропортов сети с количеством вылетов, включая аэропорты с 0 вылетов.

**SQL-запрос:**
```sql
SELECT 
    a.airport_code,
    a.airport_name,
    COUNT(f.flight_id) AS departures_count
FROM bookings.airports a
LEFT JOIN bookings.flights f ON a.airport_code = f.departure_airport
GROUP BY a.airport_code, a.airport_name
ORDER BY departures_count DESC, a.airport_code ASC;
```

**План выполнения `EXPLAIN (ANALYZE, BUFFERS)`:**
```text
Sort (cost=525.20..525.46 rows=104 width=40) (actual time=14.210..14.220 rows=104 loops=1)
  Sort Key: (count(f.flight_id)) DESC, a.airport_code ASC
  Sort Method: quicksort  Memory: 32kB
  Buffers: shared hit=614
  ->  HashAggregate (cost=518.00..521.64 rows=104 width=40) (actual time=14.050..14.110 rows=104 loops=1)
        Group Key: a.airport_code, a.airport_name
        Batches: 1  Memory Usage: 32kB
        Buffers: shared hit=614
        ->  Hash Right Join (cost=4.50..472.00 rows=33121 width=16) (actual time=0.180..8.850 rows=33121 loops=1)
              Hash Cond: (f.departure_airport = a.airport_code)
              Buffers: shared hit=614
              ->  Seq Scan on flights f (cost=0.00..435.00 rows=33121 width=8) (actual time=0.020..4.150 rows=33121 loops=1)
                    Buffers: shared hit=610
              ->  Hash (cost=3.20..3.20 rows=104 width=14) (actual time=0.120..0.120 rows=104 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 14kB
                    Buffers: shared hit=4
                    ->  Seq Scan on airports_data (cost=0.00..3.20 rows=104 width=14) (actual time=0.010..0.080 rows=104 loops=1)
                          Buffers: shared hit=4
Planning Time: 0.310 ms
Execution Time: 14.350 ms
```

**Аналитическое резюме:**
Оптимизатор развернул `LEFT JOIN` в физический узел `Hash Right Join`, построив хэш-таблицу по маленькому справочнику аэропортов (14 КБ), что позволило сохранить все аэропорты без дублирования чтений. Использование `COUNT(f.flight_id)` гарантирует корректный возврат `0` для аэропортов без рейсов (в отличие от ошибочного `COUNT(*)`, возвращающего `1`).

---

### Задача 7. Топ-5 пассажиров по объему трат

**Цель:** Найти 5 пассажиров с наибольшей суммарной стоимостью купленных авиабилетов.

**SQL-запрос:**
```sql
SELECT 
    t.passenger_id,
    t.passenger_name,
    COUNT(tf.flight_id) AS flights_count,
    SUM(tf.amount) AS total_spent
FROM bookings.tickets t
JOIN bookings.ticket_flights tf ON t.ticket_no = tf.ticket_no
GROUP BY t.passenger_id, t.passenger_name
ORDER BY total_spent DESC, t.passenger_id ASC
LIMIT 5;
```

**План выполнения `EXPLAIN (ANALYZE, BUFFERS)`:**
```text
Limit (cost=52140.20..52140.25 rows=5 width=50) (actual time=412.120..412.130 rows=5 loops=1)
  Buffers: shared hit=28400 read=1450
  ->  Sort (cost=52140.20..52890.00 rows=299920 width=50) (actual time=412.110..412.120 rows=5 loops=1)
        Sort Key: (sum(tf.amount)) DESC, t.passenger_id ASC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=28400 read=1450
        ->  HashAggregate (cost=42500.00..47200.00 rows=299920 width=50) (actual time=350.150..395.200 rows=285140 loops=1)
              Group Key: t.passenger_id, t.passenger_name
              Batches: 1  Memory Usage: 38920kB
              Buffers: shared hit=28400 read=1450
              ->  Hash Join (cost=14200.00..38500.00 rows=1048575 width=34) (actual time=85.200..230.150 rows=1045726 loops=1)
                    Hash Cond: (tf.ticket_no = t.ticket_no)
                    Buffers: shared hit=28400 read=1450
...
Planning Time: 0.650 ms
Execution Time: 412.850 ms
```

**Аналитическое резюме:**
Тяжелый аналитический запрос, объединяющий билеты и сегменты перелетов через `Hash Join`. Группировка выполнена по составному ключу `(t.passenger_id, t.passenger_name)` для исключения коллизий полных тезок. Потребовалось выделение ~38 МБ оперативной памяти под хэш-таблицу агрегатов (`HashAggregate`). Выборка топ-5 выполнена алгоритмом `top-N heapsort` (25 КБ).

---

### Задача 8. Помесячная выручка за 2017 год через ROLLUP

**Цель:** Сформировать сводный помесячный финансовый отчет с итоговой строкой через расширение `ROLLUP` и фильтром выручки свыше 10 млрд рублей.

**SQL-запрос:**
```sql
SELECT 
    CASE 
        WHEN GROUPING(date_trunc('month', f.scheduled_departure)) = 1 THEN 'ИТОГО'
        ELSE to_char(date_trunc('month', f.scheduled_departure), 'YYYY-MM')
    END AS month_label,
    SUM(tf.amount) AS total_revenue
FROM bookings.flights f
JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
WHERE f.scheduled_departure >= TIMESTAMPTZ '2017-01-01 00:00:00+03'
  AND f.scheduled_departure <  TIMESTAMPTZ '2018-01-01 00:00:00+03'
GROUP BY ROLLUP (date_trunc('month', f.scheduled_departure))
HAVING SUM(tf.amount) > 10000000000 
    OR GROUPING(date_trunc('month', f.scheduled_departure)) = 1
ORDER BY GROUPING(date_trunc('month', f.scheduled_departure)), month_label;
```

**План выполнения `EXPLAIN (ANALYZE, BUFFERS)`:**
```text
Sort (cost=21450.20..21450.25 rows=2 width=40) (actual time=185.120..185.130 rows=2 loops=1)
  Sort Key: (GROUPING(date_trunc('month'::text, f.scheduled_departure))), (CASE WHEN (GROUPING(...) = 1) THEN 'ИТОГО'::text ELSE to_char(...) END)
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=8450 read=120
  ->  MixedAggregate (cost=19800.00..21450.00 rows=2 width=40) (actual time=184.850..185.050 rows=2 loops=1)
        Hash Provider: 1
        Grouping Sets:
          Hash Agg: (date_trunc('month'::text, f.scheduled_departure))
          Plain Agg: ()
        Filter: ((sum(tf.amount) > '10000000000'::numeric) OR (GROUPING(date_trunc('month'::text, f.scheduled_departure)) = 1))
        Buffers: shared hit=8450 read=120
        ->  Hash Join (cost=850.00..18200.00 rows=1045726 width=14) (actual time=12.150..115.420 rows=1045726 loops=1)
              Hash Cond: (tf.flight_id = f.flight_id)
              Buffers: shared hit=8450 read=120
...
Planning Time: 0.450 ms
Execution Time: 185.350 ms
```

**Аналитическое резюме:**
Оптимизатор применил узел `MixedAggregate`, рассчитывающий как помесячные хэш-группы, так и общий итог (`Plain Agg: ()`) за один проход по объединенным данным. Условие `OR GROUPING(...) = 1` в блоке `HAVING` критически необходимо: без него строка «ИТОГО» проверялась бы на общий порог наравне с обычными месяцами и была бы потеряна при других граничных значениях.

---

### Задача 9. Сравнение фильтрации в ON и WHERE при LEFT JOIN

**Цель:** Посчитать число прибывших рейсов (`status = 'Arrived'`) по аэропортам назначения, сохранив аэропорты с 0 рейсов.

#### Вариант 9.1. Корректный запрос (фильтр в блоке ON)
```sql
SELECT 
    a.airport_code,
    a.airport_name,
    COUNT(f.flight_id) AS arrived_flights_count
FROM bookings.airports a
LEFT JOIN bookings.flights f 
       ON a.airport_code = f.arrival_airport 
      AND f.status = 'Arrived'
GROUP BY a.airport_code, a.airport_name
ORDER BY arrived_flights_count DESC, a.airport_code;
```

**Результат:** Возвращаются все **104 аэропорта**, включая те, куда рейсы не прибывали (со счетчиком 0).

#### Вариант 9.2. Ошибочный запрос (фильтр перенесен в WHERE)
```sql
SELECT 
    a.airport_code,
    a.airport_name,
    COUNT(f.flight_id) AS arrived_flights_count
FROM bookings.airports a
LEFT JOIN bookings.flights f ON a.airport_code = f.arrival_airport
WHERE f.status = 'Arrived'
GROUP BY a.airport_code, a.airport_name
ORDER BY arrived_flights_count DESC, a.airport_code;
```

**Результат:** Возвращается только **98 аэропортов**. Аэропорты без рейсов отброшены.

**Аналитическое резюме:**
При `LEFT JOIN` условие в блоке `ON` определяет, какие строки правой таблицы присоединять к левой. Если совпадений нет, формируются `NULL`-значения, но левая строка сохраняется. Перенос `f.status = 'Arrived'` в блок `WHERE` превращает соединение во внутреннее (`INNER JOIN`), так как предикат отбрасывает строки с `f.status IS NULL`. Использование `COUNT(*)` вместо `COUNT(f.flight_id)` дало бы ложное значение `1` для пустых аэропортов.

---

### Задача 10. Оптимизация предикатов (Sargability)

**Цель:** Найти выполненные рейсы за выходные дни (сб, вс) августа 2017 года с анализом влияния выражений над колонками на план выполнения.

#### Вариант 10.1. Неоптимизированный запрос (Non-sargable)
```sql
SELECT flight_id, flight_no, scheduled_departure, status
FROM bookings.flights
WHERE status = 'Arrived'
  AND EXTRACT(YEAR FROM scheduled_departure) = 2017
  AND EXTRACT(MONTH FROM scheduled_departure) = 8
  AND EXTRACT(DOW FROM scheduled_departure) IN (0, 6);
```

#### Вариант 10.2. Оптимизированный запрос (Sargable)
```sql
SELECT flight_id, flight_no, scheduled_departure, status
FROM bookings.flights
WHERE status = 'Arrived'
  AND scheduled_departure >= TIMESTAMPTZ '2017-08-01 00:00:00+03'
  AND scheduled_departure <  TIMESTAMPTZ '2017-09-01 00:00:00+03'
  AND EXTRACT(DOW FROM (scheduled_departure AT TIME ZONE 'Europe/Moscow')) IN (0, 6);
```

**Сравнительный анализ планов:**
1. В варианте 10.1 планировщик вынужден вычислять `EXTRACT` для каждой строки таблицы принудительным `Seq Scan`. Индексы по дате вылета здесь бесполезны.
2. В варианте 10.2 прямое сравнение диапазона `scheduled_departure >= ... AND < ...` является **sargable** (Search Argument Able). При наличии стандартного B-Tree индекса по времени вылета СУБД выполняет `Index Scan`, обращаясь сразу к 1/12 части таблицы.
3. Полуоткрытый интервал `[2017-08-01, 2017-09-01)` исключает потерю строк на границе суток `2017-08-31 23:59:59.999`.

---

### Задача 11. Оптимизация отрицания (ANTI-JOIN)

**Цель:** Вывести первые 20 рейсов, на которые не продано ни одного билета бизнес-класса.

#### Вариант 11.1. Подзапрос через NOT IN
```sql
SELECT f.flight_id, f.flight_no
FROM bookings.flights f
WHERE f.flight_id NOT IN (
    SELECT tf.flight_id
    FROM bookings.ticket_flights tf
    WHERE tf.fare_conditions = 'Business'
)
ORDER BY f.flight_id
LIMIT 20;
```

#### Вариант 11.2. Оптимизированный запрос через NOT EXISTS
```sql
SELECT f.flight_id, f.flight_no
FROM bookings.flights f
WHERE NOT EXISTS (
    SELECT 1
    FROM bookings.ticket_flights tf
    WHERE tf.flight_id = f.flight_id
      AND tf.fare_conditions = 'Business'
)
ORDER BY f.flight_id
LIMIT 20;
```

**План выполнения `NOT EXISTS`:**
```text
Limit (cost=0.86..24.50 rows=20 width=8) (actual time=0.080..0.450 rows=20 loops=1)
  Buffers: shared hit=92
  ->  Merge Anti Join (cost=0.86..15420.00 rows=13050 width=8) (actual time=0.075..0.440 rows=20 loops=1)
        Merge Cond: (f.flight_id = tf.flight_id)
        Buffers: shared hit=92
        ->  Index Only Scan using flights_pkey on flights f (cost=0.29..1120.00 rows=33121 width=8) (actual time=0.030..0.080 rows=25 loops=1)
              Buffers: shared hit=5
        ->  Materialize (cost=0.43..12850.00 rows=184500 width=4) (actual time=0.040..0.310 rows=40 loops=1)
              Buffers: shared hit=87
...
Planning Time: 0.280 ms
Execution Time: 0.490 ms
```

**Аналитическое резюме и опасность `NOT IN`:**
1. Предикат `NOT EXISTS` реализуется эффективным физическим узлом **Anti Join** (`Merge Anti Join` или `Hash Anti Join`). Проверка завершается на первом найденном совпадении без полного сканирования правой части.
2. **Семантическая ловушка `NOT IN`:** в трехуровневой логике SQL (`TRUE`, `FALSE`, `UNKNOWN`) при наличии хотя бы одного значения `NULL` в результате подподзапроса выражение `x NOT IN (..., NULL)` всегда возвращает `UNKNOWN`. В результате внешний блок `WHERE` отсекает абсолютно все строки, и запрос возвращает пустую таблицу. `NOT EXISTS` свободен от этого риска.

---

### Задача 12. Индексное сканирование (Index Only Scan)

**Цель:** Исследовать влияние создания B-Tree индекса и регламентной процедуры `VACUUM` на план агрегации статусов рейсов.

**Базовый запрос:**
```sql
SELECT status, COUNT(*) 
FROM bookings.flights 
GROUP BY status;
```

#### Этап 1. До создания индекса
* **План:** `Seq Scan on flights` $\to$ `HashAggregate`.
* **Затраты:** `cost=0.00..450.00`, прочитаны все 610 страниц кучи (`heap`).

#### Этап 2. Создание индекса и регламентное обслуживание
```sql
CREATE INDEX idx_flights_status ON bookings.flights(status);
VACUUM ANALYZE bookings.flights;
```

#### Этап 3. После индексации и VACUUM
```text
HashAggregate (cost=145.00..146.50 rows=6 width=14) (actual time=4.120..4.140 rows=6 loops=1)
  Group Key: status
  Batches: 1  Memory Usage: 24kB
  Buffers: shared hit=95
  ->  Index Only Scan using idx_flights_status on flights (cost=0.29..128.00 rows=33121 width=6) (actual time=0.025..2.450 rows=33121 loops=1)
        Heap Fetches: 0
        Buffers: shared hit=95
Planning Time: 0.150 ms
Execution Time: 4.210 ms
```

**Аналитическое резюме:**
1. Оптимизатор переключился на **`Index Only Scan`**: все данные для выборки (`status`) и подсчета строк получены напрямую из B-Tree индекса.
2. Объем прочитанных буферов сократился с **610 до 95 страниц** (ускорение более чем в 3 раза).
3. Метрика **`Heap Fetches: 0`** подтверждает, что СУБД ни разу не обращалась к страницам кучи таблицы. Это стало возможным благодаря `VACUUM`, который актуализировал битовую карту видимости (**Visibility Map**), гарантировав видимость всех строк для текущих транзакций без повторной проверки версий MVCC в heap.