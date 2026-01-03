import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Menggunakan LayoutBuilder untuk responsivitas dinamis
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Deteksi apakah sedang mode Landscape atau Tablet lebar
          final isWideScreen = constraints.maxWidth > 600 || constraints.maxWidth > constraints.maxHeight;

          return Center(
            // SingleChildScrollView: KUNCI agar tidak error saat di-rotate
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: ConstrainedBox(
                // Batasi lebar maksimum konten agar tidak 'gepeng' di layar lebar
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 450 : double.infinity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- ILUSTRASI & TEKS ---
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F7FC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_rounded, 
                            size: 80, 
                            color: Color(0xFF2962FF)
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "Kelola Toko\nJadi Lebih Mudah",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Pantau stok, kasir pintar, dan laporan\npenjualan dalam satu aplikasi.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // --- TOMBOL AKSI ---
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const LoginScreen())
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2962FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)
                          ),
                          elevation: 0,
                        ),
                        child: const Text("Masuk Akun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const RegisterScreen())
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2962FF), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)
                          ),
                        ),
                        child: const Text("Daftar Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2962FF))),
                      ),
                    ),
                    
                    // Tambahan padding bawah agar aman di HP berponi saat landscape
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}