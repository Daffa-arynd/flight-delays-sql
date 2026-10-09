-- =========================================================
-- 04_advanced_queries.sql
-- Query lanjutan: JOIN, CTE, window function
-- Definisi: delayed = telat >= 15 menit (standar US DOT)
-- Catatan : analisis per bandara (Q5, Q7) tidak mencakup
--           Oktober karena kode bandara numerik tidak bisa
--           dipetakan ke tabel airports.
-- =========================================================

-- Q5. JOIN: 10 bandara asal tersibuk beserta tingkat delay keberangkatan
SELECT ap.airport_name,
       ap.city,
       ap.state,
       COUNT(*)                                             AS scheduled_departures,
       ROUND(AVG(f.departure_delay), 2)                     AS avg_dep_delay_min,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.departure_delay >= 15)
             / COUNT(f.departure_delay), 2)                 AS pct_delayed_15min
FROM flights f
JOIN airports ap ON ap.airport_code = f.origin_airport
GROUP BY ap.airport_name, ap.city, ap.state
ORDER BY scheduled_departures DESC
LIMIT 10;

-- Q6. CTE: performa tiap maskapai dibanding rata-rata nasional
WITH overall AS (
    SELECT AVG(arrival_delay) AS avg_all
    FROM flights
    WHERE cancelled = FALSE AND diverted = FALSE
),
per_airline AS (
    SELECT airline_code,
           COUNT(arrival_delay) AS flights_flown,
           AVG(arrival_delay)   AS avg_delay
    FROM flights
    WHERE cancelled = FALSE AND diverted = FALSE
    GROUP BY airline_code
)
SELECT a.airline_name,
       p.flights_flown,
       ROUND(p.avg_delay, 2)              AS avg_arrival_delay_min,
       ROUND(o.avg_all, 2)                AS national_avg_min,
       ROUND(p.avg_delay - o.avg_all, 2)  AS diff_vs_national_min
FROM per_airline p
CROSS JOIN overall o
JOIN airlines a ON a.airline_code = p.airline_code
ORDER BY diff_vs_national_min;

-- Q7. CTE + window function: 3 bandara terburuk per bulan (RANK per bulan)
--     Bandara dengan < 1000 keberangkatan di bulan itu dikeluarkan
--     supaya persentase tidak bias oleh sampel kecil.
WITH airport_month AS (
    SELECT f.month,
           f.origin_airport,
           ap.airport_name,
           COUNT(f.departure_delay) AS flights_flown,
           ROUND(100.0 * COUNT(*) FILTER (WHERE f.departure_delay >= 15)
                 / COUNT(f.departure_delay), 2) AS pct_delayed_15min
    FROM flights f
    JOIN airports ap ON ap.airport_code = f.origin_airport
    GROUP BY f.month, f.origin_airport, ap.airport_name
    HAVING COUNT(f.departure_delay) >= 1000
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY month ORDER BY pct_delayed_15min DESC) AS rank_worst
    FROM airport_month
)
SELECT month, rank_worst, airport_name, origin_airport,
       flights_flown, pct_delayed_15min
FROM ranked
WHERE rank_worst <= 3
ORDER BY month, rank_worst;

-- Q8. Window function: ranking bulan berdasarkan persentase delay nasional
WITH monthly AS (
    SELECT month,
           COUNT(arrival_delay) AS flights_flown,
           ROUND(100.0 * COUNT(*) FILTER (WHERE arrival_delay >= 15)
                 / COUNT(arrival_delay), 2) AS pct_delayed_15min
    FROM flights
    WHERE cancelled = FALSE AND diverted = FALSE
    GROUP BY month
)
SELECT month,
       flights_flown,
       pct_delayed_15min,
       RANK() OVER (ORDER BY pct_delayed_15min DESC) AS rank_worst_month
FROM monthly
ORDER BY month;