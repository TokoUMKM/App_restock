# Project Restock 📦

**Project Restock** adalah aplikasi manajemen inventaris modern berbasis mobile yang dikembangkan menggunakan **Flutter**. Aplikasi ini dirancang untuk mempermudah proses pencatatan stok barang (stock opname), pelacakan arus masuk/keluar barang, serta visualisasi data inventaris secara *real-time*.

Proyek ini dibangun dengan pendekatan **Modern UI/UX Architecture**, mengutamakan kemudahan penggunaan (usability) dan estetika antarmuka yang bersih.

---

## 🛠 Teknologi & Arsitektur (Tech Stack)

Aplikasi ini menggunakan pustaka (libraries) standar industri untuk memastikan performa, skalabilitas, dan kemudahan pemeliharaan:

* **Core Framework:** [Flutter](https://flutter.dev/) (Dart SDK `^3.4.0`)
* **State Management:** [Riverpod](https://riverpod.dev/) (`^2.6.1`) - Dipilih karena keamanan *compile-safe*, testability, dan performa yang lebih baik dibanding Provider.
* **Backend & Database:** [Supabase](https://supabase.com/) (`^2.12.0`) - Menggunakan PostgreSQL sebagai database utama dengan fitur autentikasi dan *real-time subscription*.
* **UI Components:**
    * **Icons:** [Phosphor Icons](https://pub.dev/packages/phosphor_flutter) (`^2.1.0`) - Untuk konsistensi visual ikonografi.
    * **Typography:** [Google Fonts](https://pub.dev/packages/google_fonts) (`^6.3.0`).
    * **Visualization:** [FL Chart](https://pub.dev/packages/fl_chart) (`^0.71.0`) - Untuk grafik statistik stok.
* **Localization:** Intl (`^0.20.2`).

---

## ⚙️ Prasyarat Sistem (System Requirements)

Penting: Proyek ini dikonfigurasi untuk berjalan optimal dengan spesifikasi berikut (untuk menghindari konflik Gradle/Kotlin):

1.  **Java Development Kit (JDK):** Wajib menggunakan **Java 17 LTS** (Temurin/OpenJDK 17).
    * *Catatan: Penggunaan Java 21 dapat menyebabkan error `Unsupported class file major version 65` pada Gradle 7.6.*
2.  **Flutter SDK:** Channel Stable (v3.22.x atau terbaru).

---

## 🚀 Panduan Instalasi & Menjalankan (Getting Started)

Ikuti langkah berikut untuk menjalankan proyek di lingkungan lokal (Localhost):

1.  **Clone Repository**
    ```bash
    git clone [https://github.com/username-anda/project_restock.git](https://github.com/username-anda/project_restock.git)
    cd project_restock
    ```

2.  **Instalasi Dependensi**
    Pastikan koneksi internet stabil untuk mengunduh *packages*.
    ```bash
    flutter clean
    flutter pub get
    ```

3.  **Konfigurasi Environment**
    Pastikan `JAVA_HOME` pada sistem operasi Anda telah mengarah ke JDK 17.

4.  **Jalankan Aplikasi**
    Hubungkan device fisik atau emulator, lalu jalankan:
    ```bash
    flutter run
    ```

---

## 👥 Kontributor

* **UI/UX Architect & Developer:** [Nama Anda]
* **Tim Pengembang:** [Nama Anggota Tim Lain]

---

# project_restock

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
