SET bookings.lang = 'en';
SET TIME ZONE 'Europe/Moscow';


-- Q1. Уникальные рейсы, сортировка и collation

-- Сравнение планов DISTINCT и GROUP BY
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT flight_no 
FROM bookings.flights 
ORDER BY flight_no;

EXPLAIN (ANALYZE, BUFFERS)
SELECT flight_no 
FROM bookings.flights 
GROUP BY flight_no 
ORDER BY flight_no;

-- Проверка порядка сортировки регистра
SELECT val
FROM (VALUES ('PG0001'), ('pg0001'), ('PG0002'), ('pg0002')) AS t(val)
ORDER BY val;


-- Q2. Агрегация выручки и учет пассажиров при связях 1:N

-- Подсчет выручки и пассажиров с защитой от дублирования
SELECT 
    f.flight_id,
    f.flight_no,
    COALESCE(SUM(tf.amount), 0) AS total_revenue,
    COUNT(tf.ticket_no) AS sold_seats_count,
    COUNT(DISTINCT t.passenger_id) AS unique_passengers_count
FROM bookings.flights f
LEFT JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
LEFT JOIN bookings.tickets t ON tf.ticket_no = t.ticket_no
GROUP BY f.flight_id, f.flight_no
ORDER BY total_revenue DESC
LIMIT 10;


-- Q3. Отмененные рейсы, пустые аэропорты и трёхзначная логика NULL

-- Корректный запрос через NOT EXISTS (включает города без рейсов)
SELECT DISTINCT a.city
FROM bookings.airports a
WHERE NOT EXISTS (
    SELECT 1
    FROM bookings.flights f
    WHERE f.departure_airport = a.airport_code
      AND f.status = 'Cancelled'
)
ORDER BY a.city;

-- Демонстрация проблемы NOT IN с NULL
-- Если подзапрос возвращает NULL, внешний запрос отсекает все строки:
SELECT a.city
FROM bookings.airports a
WHERE a.airport_code NOT IN (
    SELECT f.departure_airport
    FROM bookings.flights f
    WHERE f.status = 'Cancelled'
       OR f.departure_airport IS NULL
);


-- Q4. Посадочные талоны, дубликаты и аномалии данных

-- Уникальные пассажиры на конкретном рейсе (сравнение планов)
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT t.passenger_id, t.passenger_name
FROM bookings.boarding_passes bp
JOIN bookings.tickets t ON bp.ticket_no = t.ticket_no
WHERE bp.flight_id = 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT t.passenger_id, t.passenger_name
FROM bookings.boarding_passes bp
JOIN bookings.tickets t ON bp.ticket_no = t.ticket_no
WHERE bp.flight_id = 100
GROUP BY t.passenger_id, t.passenger_name;


-- Q5. Исследование DDL и блокировок в каталоге PostgreSQL

-- Просмотр сохраненного значения по умолчанию в pg_attribute
SELECT 
    attname, 
    atthasdef, 
    atthasmissing, 
    attmissingval
FROM pg_attribute
WHERE attrelid = 'bookings.flights'::regclass
  AND attname = 'status';

-- Проверка активных блокировок в реальном времени
SELECT 
    locktype, 
    relation::regclass, 
    mode, 
    granted
FROM pg_locks
WHERE relation = 'bookings.flights'::regclass;


-- Q6. Агрегатные функции и семантика NULL

-- Влияние NULL на AVG (исключение невылетевших рейсов)
SELECT 
    COUNT(*) AS total_rows,
    COUNT(actual_departure) AS departed_flights_count,
    AVG(actual_departure - scheduled_departure) AS avg_delay_calculated
FROM bookings.flights;

-- Сравнение COUNT(*) и COUNT(column)
SELECT 
    COUNT(*) AS count_all,
    COUNT(aircraft_code) AS count_aircraft,
    COUNT(actual_departure) AS count_actual_dep
FROM bookings.flights;