# 📦 Restock App - Smart Inventory Management

![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

**Restock App** adalah solusi manajemen inventaris cerdas berbasis Flutter. Aplikasi ini dirancang untuk membantu pemilik toko memantau kesehatan stok secara *real-time*, memprediksi kapan barang habis, dan mengelola operasional toko dalam satu genggaman.

---

## 📱 UI/UX Gallery & Feature Breakdown

Berikut adalah tampilan antarmuka (User Interface) beserta penjelasan fungsional dari setiap modul.

### 1. Dashboard & Authentication
| **Halaman Login** | **Smart Dashboard** |
|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/a0b528a0-37cb-49a4-b23c-c1ae4ec4d9c9" width="300" alt="Login UI" /> | <img src="https://github.com/user-attachments/assets/52ab3c33-7156-46e0-9c10-6b389da1cde1" width="300" alt="Dashboard UI" /> |
| **Fitur:** Otentikasi aman dengan desain minimalis. Fokus pada kemudahan akses (thumb-friendly button). | **Fitur:** *Overview* kesehatan toko. Banner peringatan otomatis muncul jika ada stok kritis. Akses cepat ke laporan & scan struk. |

### 2. Inventory & Profile Management
| **Stock Management (Inventory)** | **User Profile** |
|:---:|:---:|
| <img width="300" alt="image" src="https://github.com/user-attachments/assets/56c55ee1-3e1a-4b68-9520-4d8c56d130a0" /> | <img width="300" alt="image" src="https://github.com/user-attachments/assets/17813eb4-de12-4adc-b783-94958029ad8b" /> |
| **Fitur:** Filter stok otomatis (Kritis/Aman) dan prediksi sisa hari sebelum barang habis. | **Fitur:** Manajemen identitas toko, pengaturan akses karyawan (kasir), dan integrasi kontak supplier. |
---

## ✨ Penjelasan Fitur Unggulan

Berdasarkan *screenshot* di atas, berikut adalah detail kemampuan sistem:

### 🏠 1. Dashboard Pintar (Home Overview)
Halaman ini berfungsi sebagai pusat kontrol.
* **Alert System:** Banner merah *"Stok Kritis Terdeteksi"* memberikan urgensi kepada owner untuk segera belanja.
* **Key Metrics:** Menampilkan total SKU dan Total Unit barang secara ringkas.
* **Quick Actions:** Tombol pintas untuk aktivitas harian seperti *Scan Struk* (Input barang masuk via kamera) dan *Input Manual*.

### 📦 2. Manajemen Stok (Inventory Logic)
Sistem tidak hanya mencatat jumlah, tapi juga memberikan insight.
* **Smart Filtering:** Tab kategori (`Semua`, `Kritis`, `Menipis`) memudahkan owner menyortir barang prioritas.
* **Visual Status Badges:**
    * 🔴 **Restock!** (Merah): Stok sangat sedikit, harus beli sekarang.
    * 🟡 **Warning** (Kuning): Stok mulai menipis.
    * 🟢 **Aman** (Hijau): Stok mencukupi.
* **Stock Prediction:** Fitur *"1.5 Hari lagi"* memberikan estimasi kapan barang akan habis berdasarkan rata-rata penjualan harian.

### 👤 3. Profil & Manajemen Operasional
Pusat pengaturan untuk pemilik toko.
* **Manajemen Karyawan:** Fitur untuk menambah akun akses bagi kasir atau staf gudang.
* **Integrasi Supplier:** Menyimpan kontak WA supplier agar bisa dihubungi langsung dari aplikasi.
* **Notifikasi Stok:** Pengaturan untuk menghidupkan/mematikan notifikasi push saat stok menipis.

---

## 🛠️ Tech Stack & Architecture

Aplikasi ini dibangun menggunakan arsitektur **MVVM (Model-View-ViewModel)** untuk memisahkan logika bisnis dari UI.

* **Framework:** Flutter (Dart)
* **State Management:** Provider / BLoC (Pilih sesuai yang kalian pakai)
* **Local Storage:** Hive / SQLite (Untuk cache data offline)
* **Backend:** Firebase / Laravel API

---

## 🚀 Instalasi

1.  Clone repo ini:
    ```bash
    git clone [https://github.com/username-anda/restock-app.git](https://github.com/username-anda/restock-app.git)
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Jalankan aplikasi:
    ```bash
    flutter run
    ```

---

<p align="center">
  <b>Kelompok 11 - Mobile Programming</b><br>
  Dibuat dengan ❤️ oleh [Nama Anda] sebagai UI/UX Architect
</p>
