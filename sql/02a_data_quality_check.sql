-- Diagnostik: cek apakah data bisa disambung (JOIN) dengan benar
SELECT 'maskapai tidak ada di tabel airlines' AS cek, COUNT(*) AS jumlah
FROM staging.flights f
WHERE NOT EXISTS (SELECT 1 FROM staging.airlines a WHERE a.iata_code = f.airline)
UNION ALL
SELECT 'origin tidak ada di tabel airports', COUNT(*)
FROM staging.flights f
WHERE NOT EXISTS (SELECT 1 FROM staging.airports a WHERE a.iata_code = f.origin_airport)
UNION ALL
SELECT 'origin berupa angka (bukan kode huruf)', COUNT(*)
FROM staging.flights
WHERE origin_airport ~ '^[0-9]+$';