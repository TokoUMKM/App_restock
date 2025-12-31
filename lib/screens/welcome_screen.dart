import 'package:flutter/material.dart';
import 'login_screen.dart'; // Pastikan import login screen Anda

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFE3F2FD)], // Putih ke Biru Muda
              ),
            ),
          ),
          
          // Konten
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Ilustrasi / Icon Besar
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 80, color: Color(0xFF2962FF)),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  const Text(
                    "Kelola Toko\nLebih Cerdas",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF1E293B),
                      height: 1.2
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    "Pantau stok, kasir otomatis, dan laporan keuangan dalam satu aplikasi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                  ),
                  
                  const Spacer(),

                  // Tombol Mulai
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigasi ke Login
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (_) => const LoginScreen())
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                        shadowColor: const Color(0xFF2962FF).withOpacity(0.4),
                      ),
                      child: const Text("Mulai Sekarang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}