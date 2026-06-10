# Operational Analytics DustiniaDelixia Groceria
**Final Project Lab Manajemen Cerdas Informasi (MCI) - Teknik Informatika ITS**

---

## 🌟 Overview
Proyek ini merupakan analisis operasional *end-to-end* untuk platform e-commerce **DustiniaDelixia Groceria** (marketplace UMKM Indonesia). Sebagai **Operational Analyst**, proyek ini bertujuan untuk menjawab tantangan manajemen terkait komplain pengiriman dan efisiensi biaya distribusi dengan membongkar akar masalah keterlambatan ekstrim menggunakan data aktual di lapangan.

Analisis ini menggunakan dataset **Olist (Brazilian E-Commerce)** yang telah disesuaikan ke dalam konteks studi kasus DustiniaDelixia Groceria.

## 🛠️ Tech Stack (Modern Data Stack)
Arsitektur data dirancang untuk menangani beban kerja analitik (*OLAP*) yang cepat dan skalabel:

- **Orchestration:** [Apache Airflow](https://airflow.apache.org/) (DAG-based scheduling).
- **Processing Engine:** [Apache Spark](https://spark.apache.org/) (Kalkulasi KPI logistik yang berat).
- **Data Warehouse:** [ClickHouse](https://clickhouse.com/) (Columnar Database untuk query analitik sub-detik).
- **Visualization:** [Metabase](https://www.metabase.com/) (Operational Dashboard & Command Center).
- **Infrastructure:** Docker & Docker Compose.

## 📊 Pipeline Architecture
1. **Ingestion Layer:** Skrip Python (`load_olist_operational.py`) mengekstraksi data mentah CSV, melakukan sanitasi *timestamp* (menangani NaT/Null), dan memuatnya ke tabel operasional di ClickHouse.
2. **Transformation Layer:** Skrip Apache Spark (`operational_kpis_spark.py`) melakukan perhitungan KPI logistik seperti *Lead Time*, *Carrier Shipping Days*, dan *SLA Compliance* dari jutaan baris data.
3. **Analytics Layer:** Hasil transformasi disimpan dalam database `analytics` di ClickHouse.
4. **Presentation Layer:** Dashboard Metabase mengonsumsi data dari layer analitik untuk menyajikan wawasan yang dapat ditindaklanjuti.

## Step Analisis
Analisis disusun dalam 5 langkah investigatif untuk menemukan akar masalah:

1. **Step 1:** Menemukan bahwa mayoritas keterlambatan justru masuk kategori ekstrim (> 1 minggu).
2. **Step 2:** Melokalisasi masalah pada rute logistik tersibuk (contoh: SP -> RJ).
3. **Step 3:** Membedah waktu di Penjual vs Kurir. Terungkap ketimpangan besar: **6.6 hari (Seller) vs 37.8 hari (Carrier)**.
4. **Step 4:** Mengidentifikasi daftar *Top Sellers* yang menahan barang terlalu lama (> 15 hari).
5. **Step 5:** Mengidentifikasi rute logistik dengan kinerja kurir terburuk (SLA Breach tertinggi) untuk evaluasi vendor.

## How to Run

### 1. Run Data Pipeline
- Buka Airflow UI di `http://localhost:8080` (User/Pass: `admin`/`admin`).
- Aktifkan dan trigger DAG `olist_operational_data_load`.
- Pipeline akan menjalankan proses Ingesti ke ClickHouse dan Transformasi via Spark.

### 2. Access Dashboard
- Buka Metabase di `http://localhost:3000`.
- Hubungkan ke database `analytics` di ClickHouse.
- Gunakan query yang tersedia di file `final_operational_dashboard_queries.sql` untuk membangun visualisasi.

## 📂 Project Structure
- `dags/`: Berisi definisi pipeline Airflow.
- `dags/scripts/`: Skrip Python & Spark untuk pemrosesan data.
- `rawData/`: Folder sumber data CSV (Olist dataset).
- `final_operational_dashboard_queries.sql`: Kumpulan query SQL untuk dashboard Metabase.
- `laporan_ieee.tex`: Source code laporan jurnal dalam format LaTeX.

---

## Visualisasi Metabase
<img width="1310" height="1389" alt="img21" src="https://github.com/user-attachments/assets/425811c0-9027-40c0-92f6-23c783019b35" />
<img width="1310" height="742" alt="img22" src="https://github.com/user-attachments/assets/309617a7-6d3c-4f0a-9438-dbb5f737e0f3" />

**Author:** Riyannizaar Dwi Amarullah - 5025241121
**Persona:** Operational Analyst  
**Final Project Seleksi Admin Lab MCI ITS 2026**
