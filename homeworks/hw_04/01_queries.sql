SET bookings.lang = 'en';
SET TIME ZONE 'Europe/Moscow';


-- Блок 1. Базовая фильтрация, даты и интервалы

-- Задача 1. Выполненные рейсы из московских аэропортов за август 2017
EXPLAIN (ANALYZE, BUFFERS)
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


-- Задача 2. Рейсы с опозданием более 2 часов
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    f.flight_no,
    f.scheduled_arrival,
    f.actual_arrival,
    ROUND(EXTRACT(EPOCH FROM (f.actual_arrival - f.scheduled_arrival)) / 60.0, 1) AS delay_minutes
FROM bookings.flights f
WHERE f.actual_arrival > f.scheduled_arrival + INTERVAL '2 hours'
ORDER BY (f.actual_arrival - f.scheduled_arrival) DESC;


-- Задача 3. Рейсы серии PG04 (PG0400–PG0499)
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    f.flight_no,
    COUNT(*) AS completed_flights_count
FROM bookings.flights f
WHERE f.flight_no LIKE 'PG04%'
  AND f.status = 'Arrived'
GROUP BY f.flight_no
ORDER BY f.flight_no ASC;


-- Задача 4. Среднее опоздание прибытия по аэропортам вылета (>500 рейсов)
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    f.departure_airport,
    COUNT(*) AS total_flights,
    ROUND(AVG(EXTRACT(EPOCH FROM (f.actual_arrival - f.scheduled_arrival)) / 60.0), 1) AS avg_delay_minutes
FROM bookings.flights f
WHERE f.actual_arrival IS NOT NULL
GROUP BY f.departure_airport
HAVING COUNT(*) > 500
ORDER BY avg_delay_minutes DESC;


-- Блок 2. Соединения таблиц (JOIN) и бизнес-агрегации

-- Задача 5. Топ-10 самых дорогих проданных билетов
EXPLAIN (ANALYZE, BUFFERS)
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


-- Задача 6. Реестр всех аэропортов с количеством вылетов (LEFT JOIN)
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    a.airport_code,
    a.airport_name,
    COUNT(f.flight_id) AS departures_count
FROM bookings.airports a
LEFT JOIN bookings.flights f ON a.airport_code = f.departure_airport
GROUP BY a.airport_code, a.airport_name
ORDER BY departures_count DESC, a.airport_code ASC;


-- Задача 7. Топ-5 пассажиров по суммарным тратам на билеты
EXPLAIN (ANALYZE, BUFFERS)
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


-- Блок 3. Продвинутая аналитика, Sargability и оптимизация планов

-- Задача 8. Помесячная выручка за 2017 год с общим итогом через ROLLUP
EXPLAIN (ANALYZE, BUFFERS)
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


-- Задача 9. Число прибывших рейсов по аэропортам прибытия
-- 9.1 Корректный запрос (условие статуса в блоке ON соединения)
EXPLAIN (ANALYZE, BUFFERS)
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

-- 9.2 Контрольный запуск с ошибкой (перенос условия в WHERE отсекает пустые аэропорты)
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    a.airport_code,
    a.airport_name,
    COUNT(f.flight_id) AS arrived_flights_count
FROM bookings.airports a
LEFT JOIN bookings.flights f ON a.airport_code = f.arrival_airport
WHERE f.status = 'Arrived'
GROUP BY a.airport_code, a.airport_name
ORDER BY arrived_flights_count DESC, a.airport_code;


-- Задача 10. Sargability: выполненные рейсы в выходные дни августа 2017
-- 10.1 Неоптимизированный вариант (функции над полями)
EXPLAIN (ANALYZE, BUFFERS)
SELECT flight_id, flight_no, scheduled_departure, status
FROM bookings.flights
WHERE status = 'Arrived'
  AND EXTRACT(YEAR FROM scheduled_departure) = 2017
  AND EXTRACT(MONTH FROM scheduled_departure) = 8
  AND EXTRACT(DOW FROM scheduled_departure) IN (0, 6);

-- 10.2 Оптимизированный вариант (полуоткрытый диапазон дат)
EXPLAIN (ANALYZE, BUFFERS)
SELECT flight_id, flight_no, scheduled_departure, status
FROM bookings.flights
WHERE status = 'Arrived'
  AND scheduled_departure >= TIMESTAMPTZ '2017-08-01 00:00:00+03'
  AND scheduled_departure <  TIMESTAMPTZ '2017-09-01 00:00:00+03'
  AND EXTRACT(DOW FROM (scheduled_departure AT TIME ZONE 'Europe/Moscow')) IN (0, 6);


-- Задача 11. ANTI-JOIN: рейсы без проданных билетов бизнес-класса
-- 11.1 Запрос через NOT IN
EXPLAIN (ANALYZE, BUFFERS)
SELECT f.flight_id, f.flight_no
FROM bookings.flights f
WHERE f.flight_id NOT IN (
    SELECT tf.flight_id
    FROM bookings.ticket_flights tf
    WHERE tf.fare_conditions = 'Business'
)
ORDER BY f.flight_id
LIMIT 20;

-- 11.2 Оптимизированный запрос через NOT EXISTS
EXPLAIN (ANALYZE, BUFFERS)
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


-- Задача 12. Индексное сканирование (Index Only Scan)
-- 12.1 До создания индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT status, COUNT(*) 
FROM bookings.flights 
GROUP BY status;

-- 12.2 Создание покрывающего B-Tree индекса и актуализация карты видимости
CREATE INDEX IF NOT EXISTS idx_flights_status ON bookings.flights(status);
VACUUM ANALYZE bookings.flights;

-- 12.3 После индексации (демонстрация Index Only Scan)
EXPLAIN (ANALYZE, BUFFERS)
SELECT status, COUNT(*) 
FROM bookings.flights 
GROUP BY status;