-- =========================================================
-- 02_clean_and_build_schema.sql
-- Proyek : Analisis Flight Delays 2015 (PostgreSQL)
-- Tujuan : Bangun tabel final bertipe data benar dari staging
-- Catatan: Seluruh penerbangan bulan Oktober memakai kode
--          bandara numerik yang tidak bisa dipetakan ke
--          tabel airports (lihat 02a_data_quality_check.sql)
-- =========================================================

-- ---------- 1. Tabel final ----------

-- Maskapai
CREATE TABLE airlines (
    airline_code VARCHAR(2) PRIMARY KEY,
    airline_name TEXT       NOT NULL
);

-- Bandara
CREATE TABLE airports (
    airport_code VARCHAR(5) PRIMARY KEY,
    airport_name TEXT       NOT NULL,
    city         TEXT,
    state        TEXT,
    country      TEXT,
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION
);

-- Penerbangan (satu baris = satu penerbangan)
CREATE TABLE flights (
    flight_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    flight_date         DATE        NOT NULL,
    month               SMALLINT    NOT NULL,
    day_of_week         SMALLINT    NOT NULL,   -- 1 = Senin ... 7 = Minggu
    airline_code        VARCHAR(2)  NOT NULL REFERENCES airlines (airline_code),
    flight_number       INTEGER,
    tail_number         TEXT,
    origin_airport      VARCHAR(5)  NOT NULL,   -- sebagian berupa kode angka
    destination_airport VARCHAR(5)  NOT NULL,
    scheduled_departure SMALLINT,               -- format HHMM
    departure_time      SMALLINT,
    departure_delay     SMALLINT,               -- menit, negatif = lebih awal
    taxi_out            SMALLINT,
    wheels_off          SMALLINT,
    scheduled_time      SMALLINT,
    elapsed_time        SMALLINT,
    air_time            SMALLINT,
    distance            SMALLINT,               -- mil
    wheels_on           SMALLINT,
    taxi_in             SMALLINT,
    scheduled_arrival   SMALLINT,
    arrival_time        SMALLINT,
    arrival_delay       SMALLINT,               -- menit
    diverted            BOOLEAN     NOT NULL,
    cancelled           BOOLEAN     NOT NULL,
    cancellation_reason CHAR(1),                -- A=maskapai, B=cuaca, C=NAS, D=keamanan
    air_system_delay    SMALLINT,
    security_delay      SMALLINT,
    airline_delay       SMALLINT,
    late_aircraft_delay SMALLINT,
    weather_delay       SMALLINT
);

-- ---------- 2. Isi airlines dan airports ----------

INSERT INTO airlines (airline_code, airline_name)
SELECT TRIM(iata_code), TRIM(airline)
FROM staging.airlines;

INSERT INTO airports (airport_code, airport_name, city, state, country, latitude, longitude)
SELECT TRIM(iata_code), TRIM(airport), TRIM(city), TRIM(state), TRIM(country),
       NULLIF(latitude, '')::DOUBLE PRECISION,
       NULLIF(longitude, '')::DOUBLE PRECISION
FROM staging.airports;

-- ---------- 3. Isi flights (ubah teks jadi tipe yang benar) ----------

INSERT INTO flights (
    flight_date, month, day_of_week, airline_code, flight_number, tail_number,
    origin_airport, destination_airport, scheduled_departure, departure_time,
    departure_delay, taxi_out, wheels_off, scheduled_time, elapsed_time, air_time,
    distance, wheels_on, taxi_in, scheduled_arrival, arrival_time, arrival_delay,
    diverted, cancelled, cancellation_reason, air_system_delay, security_delay,
    airline_delay, late_aircraft_delay, weather_delay
)
SELECT
    make_date(year::INT, month::INT, day::INT),
    month::SMALLINT,
    day_of_week::SMALLINT,
    airline,
    NULLIF(flight_number, '')::INTEGER,
    NULLIF(tail_number, ''),
    origin_airport,
    destination_airport,
    NULLIF(scheduled_departure, '')::SMALLINT,
    NULLIF(departure_time, '')::SMALLINT,
    NULLIF(departure_delay, '')::SMALLINT,
    NULLIF(taxi_out, '')::SMALLINT,
    NULLIF(wheels_off, '')::SMALLINT,
    NULLIF(scheduled_time, '')::SMALLINT,
    NULLIF(elapsed_time, '')::SMALLINT,
    NULLIF(air_time, '')::SMALLINT,
    NULLIF(distance, '')::SMALLINT,
    NULLIF(wheels_on, '')::SMALLINT,
    NULLIF(taxi_in, '')::SMALLINT,
    NULLIF(scheduled_arrival, '')::SMALLINT,
    NULLIF(arrival_time, '')::SMALLINT,
    NULLIF(arrival_delay, '')::SMALLINT,
    (diverted = '1'),
    (cancelled = '1'),
    NULLIF(cancellation_reason, ''),
    NULLIF(air_system_delay, '')::SMALLINT,
    NULLIF(security_delay, '')::SMALLINT,
    NULLIF(airline_delay, '')::SMALLINT,
    NULLIF(late_aircraft_delay, '')::SMALLINT,
    NULLIF(weather_delay, '')::SMALLINT
FROM staging.flights;

-- ---------- 4. Index untuk mempercepat query ----------

CREATE INDEX idx_flights_airline ON flights (airline_code);
CREATE INDEX idx_flights_origin  ON flights (origin_airport);
CREATE INDEX idx_flights_month   ON flights (month);

ANALYZE flights;

-- ---------- 5. Perbaikan encoding nama bandara ----------
-- Nama JFK di file sumber mengandung karakter rusak (Â)
UPDATE airports
SET airport_name = 'John F. Kennedy International Airport (New York International Airport)'
WHERE airport_code = 'JFK';