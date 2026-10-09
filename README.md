# Maskapai Mana yang Paling Andal? Analisis SQL atas 5,8 Juta Penerbangan Domestik AS 2015

Proyek ini menjawab satu pertanyaan: dari 14 maskapai domestik di Amerika Serikat, mana yang paling jarang telat dan paling jarang membatalkan penerbangan, dan kapan serta di bandara mana delay paling parah terjadi.

## Business Problem

Analisis ini ditujukan untuk orang yang memilih maskapai dan jadwal terbang: travel manager perusahaan, tim operasional yang sering mengirim karyawan dinas, dan penumpang yang ingin tahu risiko delay sebelum memesan tiket.

Keputusan yang ingin dibantu:
- Maskapai mana yang sebaiknya dipilih (dan dihindari) kalau ketepatan waktu penting.
- Bulan dan bandara mana yang perlu diberi waktu cadangan lebih banyak atau dihindari untuk koneksi yang ketat.
- Apa penyebab delay yang paling dominan, sehingga bisa tahu risiko mana yang bisa dikurangi lewat pilihan maskapai dan mana yang tidak.

## Dataset

- **Sumber:** [2015 Flight Delays and Cancellations (US DOT) di Kaggle](https://www.kaggle.com/datasets/usdot/flight-delays)
- **Ukuran:**
  - `flights.csv`: 5.819.079 baris x 31 kolom
  - `airlines.csv`: 14 baris
  - `airports.csv`: 322 baris
- **Periode:** 1 Januari sampai 31 Desember 2015, penerbangan domestik AS
- **Catatan penting:**
  - **Definisi delay:** penerbangan dianggap telat jika tiba 15 menit atau lebih setelah jadwal (standar US DOT). Penerbangan yang dibatalkan dan dialihkan (diverted) tidak dihitung dalam analisis delay; pembatalan dianalisis terpisah lewat cancellation rate.
  - **Data Oktober:** seluruh 486.165 penerbangan bulan Oktober (8,4% dari total) memakai kode bandara numerik yang tidak ada pemetaannya di `airports.csv`, sehingga tidak bisa diterjemahkan ke nama bandara. Penerbangan ini tetap dipakai di analisis per maskapai dan per bulan, tapi **tidak ikut** di analisis per bandara (Q5, Q7, Q12, Q13). Cek kualitas data ada di `sql/02a_data_quality_check.sql`.
  - **Data penyebab delay:** kolom penyebab hanya terisi untuk penerbangan yang telat tiba 15 menit atau lebih (1.063.439 penerbangan). Kolom `weather_delay` hanya mencatat cuaca ekstrem; cuaca biasa seperti angin kencang atau jarak pandang rendah dicatat sebagai gangguan sistem lalu lintas udara (NAS).
  - File CSV (sekitar 565 MB) tidak disertakan di repo karena melebihi batas ukuran GitHub. Unduh dari Kaggle (lihat bagian Cara Menjalankan).

## Tools

- **PostgreSQL 17** dan **pgAdmin 4** untuk database dan query
- **SQL:** JOIN, CTE, window function (`RANK`, `SUM() OVER`), `FILTER`, `CROSS JOIN LATERAL`
- **Python (matplotlib)** hanya untuk membuat chart dari hasil query

## Pendekatan

1. **Cleaning**
   - Memuat CSV ke schema `staging` (semua kolom teks) supaya import tidak gagal karena data kotor.
   - Membangun tiga tabel final (`airlines`, `airports`, `flights`) dengan tipe data yang benar: tanggal, angka, boolean, dan nilai kosong menjadi `NULL`.
   - Memeriksa kualitas JOIN antar tabel (menemukan masalah kode bandara Oktober), lalu menambah index untuk mempercepat query.
2. **Analisis**

   | File | Isi |
   |---|---|
   | `03_basic_queries.sql` | Ringkasan, delay per maskapai, cancellation rate, penyebab pembatalan |
   | `04_advanced_queries.sql` | JOIN ke bandara, CTE perbandingan dengan rata-rata nasional, ranking bandara terburuk per bulan (`RANK`), ranking bulan |
   | `05_delay_causes.sql` | Penyebab delay secara nasional, per bulan, per bandara, dan di bandara terburuk tiap bulan |
3. **Visualisasi:** chart dibuat dengan `scripts/make_charts.py` memakai angka dari hasil query.

## Temuan Utama

- **Skala masalahnya besar.** Dari 5.819.079 penerbangan, **18,61%** tiba telat 15 menit atau lebih (rata-rata telat 4,41 menit) dan **1,54%** (89.884 penerbangan) dibatalkan. Total delay mencapai sekitar 62,65 juta menit.
- **Alaska, Delta, dan Hawaiian paling andal.** Ketiganya di bawah rata-rata nasional untuk delay maupun pembatalan:

  | Maskapai | Rata-rata telat tiba | Telat 15+ menit | Cancel rate |
  |---|---|---|---|
  | Alaska | -0,98 menit | 13,04% | 0,39% |
  | Delta | 0,19 menit | 13,56% | 0,44% |
  | Hawaiian | 2,02 menit | 11,33% | 0,22% |
  | Spirit | 14,47 menit | 29,71% | 1,71% |
  | Frontier | 12,50 menit | 26,16% | 0,65% |

- **American Eagle paling sering membatalkan penerbangan:** 5,10% (3,3 kali rata-rata nasional), disusul Atlantic Southeast 2,66%.
- **Penyebab delay terbesar adalah efek domino,** yaitu pesawat yang datang telat dari penerbangan sebelumnya (39,84% dari total menit delay), diikuti masalah internal maskapai (32,20%) dan sistem lalu lintas udara (22,88%). Cuaca ekstrem hanya 4,95%.
- **Cuaca lebih memengaruhi pembatalan daripada delay.** Cuaca menyebabkan 54,35% pembatalan, tapi hanya 4,95% menit delay.
- **Delay punya dua puncak musiman.** Juni (23,48%) dan Februari (23,35%) paling buruk; Oktober (12,44%) dan September (13,00%) paling lancar.
- **Bandara terburuk berganti sesuai musim.** Persentase telat berangkat tertinggi per bulan: Chicago O'Hare di Januari (31,96%) dan Februari (37,48%), Dallas Love Field di Mei (34,15%), Chicago Midway di Juni (34,60%), Baltimore-Washington di Juli (33,23%), Miami di Agustus (28,05%). Di Februari porsi cuaca di O'Hare naik ke 15,0% dari total menit delay, dibanding 10,1% rata-rata setahun.
- **Sebagian besar maskapai mengejar waktu di udara.** Contoh United: telat berangkat rata-rata 14,33 menit, tapi telat tiba hanya 5,43 menit. Spirit dan Frontier hampir tidak bisa mengejar (15,88 menjadi 14,47 menit, dan 13,30 menjadi 12,50 menit).

## Rekomendasi Keputusan

1. **Pilih Alaska, Delta, atau Hawaiian** jika rutenya tersedia. Ketiganya konsisten berada di tiga besar untuk telat rata-rata, persentase telat, dan cancel rate. Delta paling teruji karena volumenya besar (870 ribu penerbangan dalam data).
2. **Beri waktu cadangan ekstra untuk Spirit dan Frontier.** Hampir 3 dari 10 penerbangan Spirit (29,71%) dan lebih dari 1 dari 4 penerbangan Frontier (26,16%) telat. Untuk **American Eagle** dan **Atlantic Southeast**, hindari koneksi yang ketat karena cancel rate-nya 5,10% dan 2,66%.
3. **Jika jadwal fleksibel, hindari Februari dan Juni;** September dan Oktober paling lancar. Selisihnya besar: 23,48% telat di Juni dibanding 12,44% di Oktober.
4. **Hindari koneksi pendek lewat bandara yang sedang di puncak masalahnya:** Chicago O'Hare dan Denver di Januari, O'Hare, LaGuardia (35,84%) dan Boston (32,48%) di Februari, Dallas Love Field di Mei, Chicago Midway di Juni, Baltimore-Washington di Juli, dan Miami di Agustus.
5. **Karena 39,84% menit delay berasal dari efek domino,** penerbangan lanjutan di hari yang sama dengan pesawat yang sama berisiko lebih tinggi. Pilih jadwal dengan jeda antar penerbangan yang cukup.

## Screenshot / Demo

![Persentase penerbangan telat per maskapai](images/01_delay_by_airline.png)

![Cancellation rate per maskapai](images/02_cancellation_by_airline.png)

![Persentase telat per bulan](images/03_delay_by_month.png)

![Penyebab delay dibanding penyebab pembatalan](images/04_delay_vs_cancel_causes.png)

![Komposisi penyebab delay di 10 bandara terbesar](images/05_delay_causes_by_airport.png)

## Cara Menjalankan

**Kebutuhan:** PostgreSQL 15 atau lebih baru (dengan `psql`), dan Python 3 dengan `matplotlib` (hanya untuk chart).

1. Unduh dataset dari [Kaggle](https://www.kaggle.com/datasets/usdot/flight-delays), ekstrak, dan taruh `airlines.csv`, `airports.csv`, `flights.csv` di folder `data/`.
2. Buat database:
   ```
   psql -U postgres -c "CREATE DATABASE flight_delays;"
   ```
3. Jalankan file SQL **berurutan dari folder utama proyek**:
   ```
   psql -U postgres -d flight_delays -f sql/01_create_staging.sql
   psql -U postgres -d flight_delays -f sql/01b_import_data.sql
   psql -U postgres -d flight_delays -f sql/02a_data_quality_check.sql
   psql -U postgres -d flight_delays -f sql/02_clean_and_build_schema.sql
   psql -U postgres -d flight_delays -f sql/03_basic_queries.sql
   psql -U postgres -d flight_delays -f sql/04_advanced_queries.sql
   psql -U postgres -d flight_delays -f sql/05_delay_causes.sql
   ```
   Import `flights.csv` memakan waktu beberapa menit. Query 03 sampai 05 juga bisa dijalankan satu per satu di pgAdmin Query Tool.
4. (Opsional) Buat ulang chart:
   ```
   pip install matplotlib
   python scripts/make_charts.py
   ```

## Keterbatasan & Next Steps

**Keterbatasan**
- Data hanya satu tahun (2015), jadi pola musiman belum teruji di tahun lain.
- Perbandingan antar maskapai belum mengontrol jaringan rute, jarak terbang, dan bandara yang dilayani. Hasilnya berarti "paling andal di data 2015 dengan jaringan rutenya masing-masing", bukan "paling baik secara mutlak".
- Maskapai dengan volume kecil (Hawaiian sekitar 76 ribu dan Virgin America sekitar 61 ribu penerbangan) punya estimasi yang kurang stabil dibanding maskapai besar.
- Oktober tidak tercakup di analisis per bandara karena kode bandara numerik tidak bisa dipetakan.
- Analisis per bandara memakai bandara asal. Penyebab delay dicatat untuk keterlambatan tiba, jadi efek domino bisa berasal dari bandara lain.
- Penjelasan musiman (misalnya cuaca di musim dingin) adalah pola yang terlihat di data, bukan bukti sebab-akibat. Tidak ada uji signifikansi statistik.

**Next steps**
- Mencari tabel pemetaan kode bandara numerik (ID bandara US DOT) untuk melengkapi data Oktober.
- Menganalisis delay per jam keberangkatan dan hari dalam seminggu (kolom `scheduled_departure` dan `day_of_week` sudah ada di tabel).
- Menganalisis per rute (asal-tujuan) untuk membandingkan maskapai di rute yang sama.
- Membuat dashboard interaktif (Power BI, Tableau, atau Metabase) di atas database ini.
