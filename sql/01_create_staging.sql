-- =========================================================
-- 01_create_staging.sql
-- Tabel mentah (staging): semua kolom TEXT supaya import
-- CSV tidak gagal karena data kotor. Dibersihkan di Step 4.
-- =========================================================

CREATE SCHEMA IF NOT EXISTS staging;

-- Tabel maskapai (2 kolom)
CREATE TABLE staging.airlines (
    iata_code TEXT,
    airline   TEXT
);

-- Tabel bandara (7 kolom)
CREATE TABLE staging.airports (
    iata_code TEXT,
    airport   TEXT,
    city      TEXT,
    state     TEXT,
    country   TEXT,
    latitude  TEXT,
    longitude TEXT
);

-- Tabel penerbangan (31 kolom)
CREATE TABLE staging.flights (
    year                TEXT,
    month               TEXT,
    day                 TEXT,
    day_of_week         TEXT,
    airline             TEXT,
    flight_number       TEXT,
    tail_number         TEXT,
    origin_airport      TEXT,
    destination_airport TEXT,
    scheduled_departure TEXT,
    departure_time      TEXT,
    departure_delay     TEXT,
    taxi_out            TEXT,
    wheels_off          TEXT,
    scheduled_time      TEXT,
    elapsed_time        TEXT,
    air_time            TEXT,
    distance            TEXT,
    wheels_on           TEXT,
    taxi_in             TEXT,
    scheduled_arrival   TEXT,
    arrival_time        TEXT,
    arrival_delay       TEXT,
    diverted            TEXT,
    cancelled           TEXT,
    cancellation_reason TEXT,
    air_system_delay    TEXT,
    security_delay      TEXT,
    airline_delay       TEXT,
    late_aircraft_delay TEXT,
    weather_delay       TEXT
);