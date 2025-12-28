<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/52ab3c33-7156-46e0-9c10-6b389da1cde1" /># 📦 Restock App - Inventory Management System

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

**Restock App** adalah aplikasi mobile berbasis Flutter yang dirancang untuk memudahkan UMKM dan admin gudang dalam memantau stok barang secara *real-time*.

Proyek ini berfokus pada **User Experience (UX)** yang efisien dan **User Interface (UI)** yang bersih (Clean Design), memastikan pengguna dapat mengelola inventaris dengan cepat dan tanpa kebingungan.

---
![Uploading image.png…]()

## 🎨 UI/UX Design Showcase

Bagian ini menampilkan implementasi antarmuka yang telah dibangun dengan pendekatan *User-Centered Design*.

| **Login Screen** | **Dashboard / Home** |
|:---:|:---:|
| <img src="blob:https://web.whatsapp.com/284b17f4-0c37-49b9-8602-4686b18e17a9"> | <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/a0b528a0-37cb-49a4-b23c-c1ae4ec4d9c9" /> |
| *Desain minimalis dengan input field yang jelas dan tombol thumb-friendly.* | *Grid layout untuk menampilkan banyak produk dengan kartu yang informatif.* |

> **Catatan:** Gambar di atas adalah representasi visual dari kode yang telah diimplementasikan.

---

## 🛠️ Design System & Architecture

Sebagai fondasi UI/UX, aplikasi ini menggunakan **Modular Architecture** untuk memastikan kode mudah dibaca, dirawat, dan dikembangkan.

### 1. Color Palette & Typography
Kami menggunakan `Teal` sebagai warna primer untuk memberikan kesan profesional, tenang, dan terpercaya.
* **Primary Color:** `Colors.teal`
* **Background:** `Colors.grey[50]` (Untuk mengurangi kelelahan mata / *eye strain*)
* **Shape:** Rounded Corners (12px - 16px) untuk kesan modern dan ramah.

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
    └── home_screen.dart   # Dashboard utama (Grid View)
