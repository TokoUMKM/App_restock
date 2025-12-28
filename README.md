# 📦 Restock App - Inventory Management System

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

**Restock App** adalah aplikasi mobile berbasis Flutter yang dirancang untuk memudahkan UMKM dan admin gudang dalam memantau stok barang secara *real-time*.

Proyek ini berfokus pada **User Experience (UX)** yang efisien dan **User Interface (UI)** yang bersih (Clean Design), memastikan pengguna dapat mengelola inventaris dengan cepat dan tanpa kebingungan.

---

## 🎨 UI/UX Design Showcase

Bagian ini menampilkan implementasi antarmuka yang telah dibangun dengan pendekatan *User-Centered Design*.

### 1. Authentication & Dashboard
| **Login Screen** | **Dashboard / Home** |
|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/a0b528a0-37cb-49a4-b23c-c1ae4ec4d9c9" width="300" alt="Login Screen" /> | <img src="https://github.com/user-attachments/assets/52ab3c33-7156-46e0-9c10-6b389da1cde1" width="300" alt="Home Dashboard" /> |
| *Desain minimalis dengan input field yang jelas dan tombol thumb-friendly.* | *Grid layout untuk menampilkan banyak produk dengan kartu yang informatif.* |

### 2. Inventory & Profile Management
| **Stock Management (Inventory)** | **User Profile** |
|:---:|:---:|
| <img src="assets/screenshots/inventory_screen.png" width="300" alt="Manajemen Stok" /> | <img src="assets/screenshots/profile_screen.png" width="300" alt="Profil User" /> |
| *Fitur filter status (Kritis, Menipis) dan indikator warna visual untuk memudahkan monitoring stok.* | *Navigasi pengaturan toko dan akun yang terstruktur dengan hierarki informasi yang jelas.* |

> **Catatan:** Ganti path `assets/screenshots/...` dengan lokasi file gambar yang Anda miliki atau link upload GitHub yang baru.

---

## 🛠️ Design System & Architecture

Sebagai fondasi UI/UX, aplikasi ini menggunakan **Modular Architecture** untuk memastikan kode mudah dibaca, dirawat, dan dikembangkan.

### 1. Color Palette & Typography
Kami menggunakan `Teal` sebagai warna primer untuk memberikan kesan profesional, tenang, dan terpercaya.
* **Primary Color:** `Colors.teal`
* **Background:** `Colors.grey[50]` (Untuk mengurangi kelelahan mata / *eye strain*)
* **Status Colors:**
    * 🔴 **Danger:** Stok Kritis (Restock!)
    * 🟡 **Warning:** Stok Menipis
    * 🟢 **Safe:** Stok Aman

### 2. Folder Structure
Struktur direktori disusun berdasarkan fungsi komponen UI:

```text
lib/
├── main.dart           # Entry Point aplikasi
├── theme.dart          # Centralized Design System (Warna, Font, Input Style)
├── widgets/            # Komponen UI yang dapat digunakan kembali (Reusable)
│   └── product_card.dart  # Widget kartu untuk menampilkan item barang
└── screens/            # Halaman utama aplikasi
    ├── login_screen.dart  # Halaman otentikasi pengguna
    ├── home_screen.dart   # Dashboard utama (Grid View)
    ├── inventory_screen.dart # Halaman manajemen stok dengan filter
    └── profile_screen.dart   # Halaman pengaturan akun
