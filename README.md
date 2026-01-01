# 📦 Restock AI - Aplikasi Kasir & Stok Pintar

![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-2D2D2D)
![License](https://img.shields.io/badge/License-MIT-green)

**Restock AI** adalah solusi manajemen inventaris cerdas berbasis Flutter yang dirancang khusus untuk UMKM. Aplikasi ini membantu pemilik toko memantau kesehatan stok secara *real-time*, menerima notifikasi otomatis saat barang menipis, dan memprediksi kebutuhan *restock* berdasarkan tren penjualan.

---

## 📱 Galeri Antarmuka (UI/UX)

Berikut adalah tampilan antarmuka aplikasi yang didesain dengan pendekatan *Clean & Modern UI*.

### 1. Otentikasi & Welcome Screen
| **Halaman Login** | **Welcome Screen** | **Halaman Register** |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/a0b528a0-37cb-49a4-b23c-c1ae4ec4d9c9" width="250" alt="Login UI" /> | <img src="https://github.com/user-attachments/assets/81307006-958d-47bb-b318-e9a8a0a481a4" width="250" alt="Welcome UI" /> | <img src="https://github.com/user-attachments/assets/5bd5c892-1af9-48ba-bb66-1063ae0f46ba" width="250" alt="Register UI" /> |
| **Login Aman**<br>Terintegrasi dengan Supabase Auth. | **Sapaan Hangat**<br>Onboarding yang ramah pengguna. | **Registrasi Cepat**<br>Pendaftaran akun toko baru. |

### 2. Dashboard, Stok & Scan
| **Dashboard Utama** | **Manajemen Stok** | **Review Scan** |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/457ee706-8a75-46fb-81ad-eac19d6a286e" width="250" alt="Dashboard UI" /> | <img src="https://github.com/user-attachments/assets/51036528-4fe0-4cbc-aa5c-10cc6f777662" width="250" alt="Stock UI" /> | <img src="https://github.com/user-attachments/assets/afac9231-e332-44ea-abf5-6f574b47c1bc" width="250" alt="Scan UI" /> |
| **Pusat Kontrol**<br>Ringkasan kesehatan toko & grafik. | **Indikator Stok**<br>Status warna (Merah/Kuning/Hijau). | **AI Scan**<br>Verifikasi hasil scan produk. |

### 3. Laporan, Kasir & Supplier
| **Laporan Keuangan** | **Kasir (POS)** | **Tambah Supplier** |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/288047d8-02b4-4f47-a27d-be75e5cae078" width="250" alt="Report UI" /> | <img src="https://github.com/user-attachments/assets/a3344f39-026c-4c1f-b3cd-bea3a089a516" width="250" alt="Cashier UI" /> | <img src="https://github.com/user-attachments/assets/519bfc0f-fabd-43e9-9069-5df1da3f432a" width="250" alt="Supplier UI" /> |
| **Analisa Bisnis**<br>Pantau omzet dan performa. | **Transaksi Cepat**<br>Mode kasir yang mudah digunakan. | **Database Supplier**<br>Simpan kontak pemasok. |

---

## ✨ Fitur Unggulan

### 🏠 1. Dashboard Pintar (Real-time Overview)
* **Smart Alerts:** Banner merah otomatis muncul jika ada barang dengan stok 0 atau di bawah batas minimum.
* **Analisa Cepat:** Kartu statistik menampilkan total SKU dan total unit barang secara *live*.
* **Menu Cepat:** Akses instan ke fitur *Scan Barcode*, *Input Manual*, dan *Laporan*.

### 📦 2. Manajemen Stok Cerdas
* **Visual Indicators:**
    * 🔴 **Habis:** Stok 0 (Perlu tindakan segera).
    * 🟡 **Restock:** Stok menipis (Warning).
    * 🟢 **Aman:** Stok melimpah.
* **Prediksi Stok:** Algoritma sederhana yang menghitung estimasi hari sebelum barang habis (misal: *"Habis dalam 1.5 hari"*).

### 🔔 3. Sistem Notifikasi Hybrid
* **Push Notifications (FCM):** Notifikasi stok menipis dikirim langsung ke HP meskipun aplikasi ditutup.
* **In-App Dialog:** Popup peringatan saat pengguna membuka aplikasi untuk memastikan owner sadar akan stok kritis.

### 🛡️ 4. Keamanan & Profil
* **Data Privacy:** Fitur hapus akun mandiri yang mematuhi kebijakan Google Play Store (menghapus data Auth, Profil, dan Produk).
* **Cloud Sync:** Semua data tersimpan aman di Cloud (Supabase), tidak hilang meski ganti HP.

---

## 🛠️ Tech Stack & Arsitektur

Aplikasi ini dibangun dengan standar industri modern untuk performa dan skalabilitas.

* **Framework:** Flutter (Dart)
* **State Management:** Flutter Riverpod (2.0+)
* **Backend as a Service:** Supabase (PostgreSQL, Auth, Edge Functions)
* **Notifications:** Firebase Cloud Messaging (FCM)
* **Native Integration:** Camera (Scan Barcode), UCrop (Image Cropping), Flutter Local Notifications.

---

## 🚀 Panduan Instalasi (Development)

Untuk menjalankan proyek ini di mesin lokal Anda:

### Prasyarat
* Flutter SDK (Versi 3.10 ke atas)
* Akun Supabase & Firebase

### Langkah-langkah

1.  **Clone Repository:**
    ```bash
    git clone [https://github.com/TokoUmkm/App_restock.git](https://github.com/TokoUmkm/App_restock.git)
    cd App_restock
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Konfigurasi Environment (.env):**
    Buat file `.env` di root folder dan isi dengan kredensial Supabase Anda:
    ```env
    SUPABASE_URL=[https://your-project-id.supabase.co](https://your-project-id.supabase.co)
    SUPABASE_KEY=your-anon-key
    ADMIN_WA=628123456789
    ```

4.  **Konfigurasi Firebase:**
    * Letakkan file `google-services.json` di folder `android/app/`.

5.  **Jalankan Aplikasi:**
    ```bash
    flutter run
    ```

---

## 📱 Rilis & Build

Untuk membuat file APK/AAB siap rilis ke Play Store:

1.  Pastikan Anda telah membuat `key.properties` dan `upload-keystore.jks`.
2.  Jalankan perintah build:
    ```bash
    # Untuk Android App Bundle (Play Store)
    flutter build appbundle --release

    # Untuk APK (Testing)
    flutter build apk --release
    ```

---

## 🤝 Kontribusi

Kontribusi selalu diterima! Silakan buat *Pull Request* atau buka *Issue* jika menemukan bug atau ide fitur baru.

---

### 👥 Tim Pengembang

Dibuat dengan ❤️ oleh:
* **Muhammad Adam Sirojuddin Munawar**
* **Muhammad Tibia Nugraha**
* **Nisrina Aliya Tharifa**
* **Raditya Raihan**