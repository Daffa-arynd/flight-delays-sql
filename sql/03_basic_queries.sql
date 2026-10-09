-- =========================================================
-- 03_basic_queries.sql
-- Query dasar: ringkasan, delay per maskapai, cancellation rate
-- Definisi: delayed = telat tiba >= 15 menit (standar US DOT)
-- =========================================================

-- Q1. Ringkasan keseluruhan 2015
SELECT COUNT(*)                                          AS total_flights,
       COUNT(*) FILTER (WHERE cancelled)                 AS cancelled_flights,
       ROUND(100.0 * COUNT(*) FILTER (WHERE cancelled)
             / COUNT(*), 2)                              AS cancel_rate_pct,
       ROUND(AVG(arrival_delay), 2)                      AS avg_arrival_delay_min,
       ROUND(100.0 * COUNT(*) FILTER (WHERE arrival_delay >= 15)
             / COUNT(arrival_delay), 2)                  AS pct_delayed_15min
FROM flights;

-- Q2. Delay per maskapai (hanya penerbangan yang benar-benar terbang)
SELECT a.airline_name,
       COUNT(f.arrival_delay)                              AS flights_flown,
       ROUND(AVG(f.departure_delay), 2)                    AS avg_departure_delay_min,
       ROUND(AVG(f.arrival_delay), 2)                      AS avg_arrival_delay_min,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.arrival_delay >= 15)
             / COUNT(f.arrival_delay), 2)                  AS pct_delayed_15min
FROM flights f
JOIN airlines a ON a.airline_code = f.airline_code
WHERE f.cancelled = FALSE
  AND f.diverted  = FALSE
GROUP BY a.airline_name
ORDER BY avg_arrival_delay_min;

-- Q3. Cancellation rate per maskapai
SELECT a.airline_name,
       COUNT(*)                                            AS total_flights,
       COUNT(*) FILTER (WHERE f.cancelled)                 AS cancelled_flights,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.cancelled)
             / COUNT(*), 2)                                AS cancellation_rate_pct
FROM flights f
JOIN airlines a ON a.airline_code = f.airline_code
GROUP BY a.airline_name
ORDER BY cancellation_rate_pct DESC;

-- Q4. Alasan pembatalan penerbangan (persentase memakai window function)
SELECT CASE cancellation_reason
           WHEN 'A' THEN 'Airline / Carrier'
           WHEN 'B' THEN 'Weather'
           WHEN 'C' THEN 'National Air System'
           WHEN 'D' THEN 'Security'
       END                                                  AS cancel_reason,
       COUNT(*)                                             AS cancelled_flights,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)   AS pct_of_cancellations
FROM flights
WHERE cancelled = TRUE
GROUP BY cancellation_reason
ORDER BY cancelled_flights DESC;

