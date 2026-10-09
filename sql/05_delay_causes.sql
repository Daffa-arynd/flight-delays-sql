-- =========================================================
-- 05_delay_causes.sql
-- Analisis penyebab delay: nasional, per bulan, per bandara
-- Catatan: kolom penyebab hanya terisi untuk penerbangan yang
--          telat tiba >= 15 menit. Analisis per bandara tidak
--          mencakup Oktober (kode bandara numerik).
-- =========================================================

-- Q9. Cek cakupan data penyebab delay
SELECT COUNT(*) FILTER (WHERE cancelled = FALSE AND diverted = FALSE
                          AND arrival_delay >= 15)       AS delayed_15min_flights,
       COUNT(*) FILTER (WHERE airline_delay IS NOT NULL) AS flights_with_cause_data,
       COUNT(*) FILTER (WHERE airline_delay IS NOT NULL
                          AND arrival_delay < 15)        AS cause_but_under_15min,
       COUNT(*) FILTER (WHERE arrival_delay >= 15
                          AND airline_delay IS NULL)     AS delayed_without_cause
FROM flights;

-- Q10. Penyebab delay secara nasional (total menit dan persentase)
SELECT v.cause,
       SUM(v.minutes)                                              AS total_delay_min,
       ROUND(100.0 * SUM(v.minutes) / SUM(SUM(v.minutes)) OVER (), 2) AS pct_of_delay_min
FROM flights f
CROSS JOIN LATERAL (VALUES
        ('Airline',          f.airline_delay),
        ('Late aircraft',    f.late_aircraft_delay),
        ('Air system (NAS)', f.air_system_delay),
        ('Weather',          f.weather_delay),
        ('Security',         f.security_delay)
     ) AS v(cause, minutes)
WHERE f.airline_delay IS NOT NULL
GROUP BY v.cause
ORDER BY total_delay_min DESC;

-- Q11. Komposisi penyebab delay per bulan (% dari total menit delay)
WITH monthly AS (
    SELECT month,
           COUNT(*)                          AS delayed_flights,
           SUM(airline_delay)                AS airline_min,
           SUM(late_aircraft_delay)          AS late_aircraft_min,
           SUM(air_system_delay)             AS air_system_min,
           SUM(weather_delay)                AS weather_min,
           SUM(security_delay)               AS security_min
    FROM flights
    WHERE airline_delay IS NOT NULL
    GROUP BY month
),
with_total AS (
    SELECT *,
           airline_min + late_aircraft_min + air_system_min
             + weather_min + security_min    AS total_min
    FROM monthly
)
SELECT month,
       delayed_flights,
       ROUND(100.0 * airline_min       / total_min, 1) AS pct_airline,
       ROUND(100.0 * late_aircraft_min / total_min, 1) AS pct_late_aircraft,
       ROUND(100.0 * air_system_min    / total_min, 1) AS pct_air_system,
       ROUND(100.0 * weather_min       / total_min, 1) AS pct_weather,
       ROUND(100.0 * security_min      / total_min, 1) AS pct_security
FROM with_total
ORDER BY month;

-- Q12. 10 bandara dengan total menit delay terbesar + komposisi penyebabnya
WITH airport_cause AS (
    SELECT f.origin_airport,
           ap.airport_name,
           COUNT(*)                                AS delayed_flights,
           COALESCE(SUM(f.airline_delay), 0)       AS airline_min,
           COALESCE(SUM(f.late_aircraft_delay), 0) AS late_aircraft_min,
           COALESCE(SUM(f.air_system_delay), 0)    AS air_system_min,
           COALESCE(SUM(f.weather_delay), 0)       AS weather_min,
           COALESCE(SUM(f.security_delay), 0)      AS security_min
    FROM flights f
    JOIN airports ap ON ap.airport_code = f.origin_airport
    WHERE f.airline_delay IS NOT NULL
    GROUP BY f.origin_airport, ap.airport_name
),
with_total AS (
    SELECT *,
           airline_min + late_aircraft_min + air_system_min
             + weather_min + security_min          AS total_min
    FROM airport_cause
)
SELECT origin_airport,
       airport_name,
       delayed_flights,
       total_min,
       ROUND(100.0 * airline_min       / total_min, 1) AS pct_airline,
       ROUND(100.0 * late_aircraft_min / total_min, 1) AS pct_late_aircraft,
       ROUND(100.0 * air_system_min    / total_min, 1) AS pct_air_system,
       ROUND(100.0 * weather_min       / total_min, 1) AS pct_weather
FROM with_total
ORDER BY total_min DESC
LIMIT 10;

-- Q13. Penyebab delay di bandara TERBURUK tiap bulan (ranking sama seperti Q7)
--      Bandara dengan < 1000 keberangkatan di bulan itu dikeluarkan.
WITH airport_month AS (
    SELECT f.month,
           f.origin_airport,
           COUNT(f.departure_delay)                AS flights_flown,
           ROUND(100.0 * COUNT(*) FILTER (WHERE f.departure_delay >= 15)
                 / COUNT(f.departure_delay), 2)    AS pct_delayed_15min,
           COALESCE(SUM(f.airline_delay), 0)       AS airline_min,
           COALESCE(SUM(f.late_aircraft_delay), 0) AS late_aircraft_min,
           COALESCE(SUM(f.air_system_delay), 0)    AS air_system_min,
           COALESCE(SUM(f.weather_delay), 0)       AS weather_min,
           COALESCE(SUM(f.security_delay), 0)      AS security_min
    FROM flights f
    JOIN airports ap ON ap.airport_code = f.origin_airport
    GROUP BY f.month, f.origin_airport
    HAVING COUNT(f.departure_delay) >= 1000
),
ranked AS (
    SELECT *,
           airline_min + late_aircraft_min + air_system_min
             + weather_min + security_min          AS total_min,
           RANK() OVER (PARTITION BY month
                        ORDER BY pct_delayed_15min DESC) AS rank_worst
    FROM airport_month
)
SELECT month,
       origin_airport,
       pct_delayed_15min,
       ROUND(100.0 * airline_min       / NULLIF(total_min, 0), 1) AS pct_airline,
       ROUND(100.0 * late_aircraft_min / NULLIF(total_min, 0), 1) AS pct_late_aircraft,
       ROUND(100.0 * air_system_min    / NULLIF(total_min, 0), 1) AS pct_air_system,
       ROUND(100.0 * weather_min       / NULLIF(total_min, 0), 1) AS pct_weather
FROM ranked
WHERE rank_worst = 1
ORDER BY month;