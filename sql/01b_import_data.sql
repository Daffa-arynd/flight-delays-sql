-- =========================================================
-- 01b_import_data.sql
-- Import 3 file CSV ke schema staging.
-- Dijalankan lewat psql (bukan Query Tool pgAdmin) karena
-- memakai perintah \copy.
--
-- Jalankan dari folder utama proyek (flight-delays-sql):
--   psql -U postgres -d flight_delays -f sql/01b_import_data.sql
--
-- Prasyarat: file CSV (dari Kaggle) sudah ada di folder data/
-- =========================================================

\copy staging.airlines FROM 'data/airlines.csv' WITH (FORMAT csv, HEADER true)
\copy staging.airports FROM 'data/airports.csv' WITH (FORMAT csv, HEADER true)
\copy staging.flights  FROM 'data/flights.csv'  WITH (FORMAT csv, HEADER true)