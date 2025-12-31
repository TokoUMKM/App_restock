import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; // [PENTING] Import dotenv

import '../screens/login_screen.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Data Profil
  String _fullName = "";
  String _shopName = "";
  String _email = "";
  String _phone = "";   
  String _address = ""; 
  
  // State UI
  bool _isLoading = false;
  bool _notifEnabled = true; // State untuk toggle notifikasi

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // --- 1. LOAD DATA PROFIL LENGKAP ---
  void _loadProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata ?? {};
      setState(() {
        _email = user.email ?? "";
        _fullName = meta['full_name'] ?? "User Toko";
        _shopName = meta['shop_name'] ?? "Toko Saya";
        _phone = meta['shop_phone'] ?? "";       // Load No HP Toko
        _address = meta['shop_address'] ?? "";   // Load Alamat Toko
      });
    }
  }

  // --- HELPER SNACKBAR ---
  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF2962FF),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- 2. LOGIC UPDATE PROFIL (LENGKAP) ---
  void _showEditProfileDialog() {
    // Siapkan controller dengan text yang sudah ada
    final nameCtrl = TextEditingController(text: _fullName);
    final shopCtrl = TextEditingController(text: _shopName);
    final phoneCtrl = TextEditingController(text: _phone);
    final addressCtrl = TextEditingController(text: _address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Informasi Toko", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Input Nama
              _buildTextField(nameCtrl, "Nama Pemilik", Icons.person_outline),
              const SizedBox(height: 12),
              
              // Input Toko
              _buildTextField(shopCtrl, "Nama Toko", Icons.store_outlined),
              const SizedBox(height: 12),
              
              // [BARU] Input Telepon
              _buildTextField(phoneCtrl, "No. Telepon Toko", Icons.phone_outlined, inputType: TextInputType.phone),
              const SizedBox(height: 12),

              // [BARU] Input Alamat
              _buildTextField(addressCtrl, "Alamat Lengkap", Icons.location_on_outlined, maxLines: 2),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true); // Tampilkan loading global (opsional) atau snackbar
                    
                    try {
                      // Update Metadata ke Supabase
                      await Supabase.instance.client.auth.updateUser(
                        UserAttributes(data: {
                          'full_name': nameCtrl.text.trim(), 
                          'shop_name': shopCtrl.text.trim(),
                          'shop_phone': phoneCtrl.text.trim(),   // Simpan HP
                          'shop_address': addressCtrl.text.trim() // Simpan Alamat
                        }),
                      );
                      
                      _loadProfile(); // Refresh UI Lokal
                      _showSnack("Profil berhasil diperbarui!");
                    } catch (e) {
                      _showSnack("Gagal update: $e", isError: true);
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text("Simpan Perubahan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper TextField agar kode rapi
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        isDense: true,
      ),
    );
  }

  // --- 3. FITUR HUBUNGI ADMIN (WA) ---
  Future<void> _contactAdmin() async {
    // Ambil nomor dari .env agar aman
    final adminPhone = dotenv.env['ADMIN_WA'] ?? ""; 
    
    if (adminPhone.isEmpty) {
      _showSnack("Nomor Admin belum dikonfigurasi.", isError: true);
      return;
    }

    final uri = Uri.parse("https://wa.me/$adminPhone?text=Halo%20Admin%20RestockAI,%20saya%20butuh%20bantuan.");
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack("Tidak dapat membuka WhatsApp.", isError: true);
      }
    } catch (e) {
      _showSnack("Error: $e", isError: true);
    }
  }

  // --- 4. LOGOUT DENGAN LOADING (LOGGING UX) ---
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: const Column(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF2962FF), size: 48),
            SizedBox(height: 16),
            Text("Keluar Aplikasi?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Sesi Anda akan berakhir. Pastikan data sudah tersimpan.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade300)
            ),
            child: const Text("Batal", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup Dialog Konfirmasi

              // [UX UPGRADE] Tampilkan Loading Indicator (Logging out...)
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Sedang keluar...")
                        ],
                      ),
                    ),
                  ),
                )
              );
              
              // Simulasi delay sedikit agar user 'merasakan' proses logout
              await Future.delayed(const Duration(milliseconds: 800));

              // Proses Logout Asli
              await Supabase.instance.client.auth.signOut();
              
              // Reset State Riverpod
              ref.invalidate(productListProvider);
              ref.invalidate(cartProvider);
              
              if (mounted) {
                // Tutup Loading Dialog
                Navigator.pop(context); 
                
                // Pindah ke Login Screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  // --- 5. HAPUS AKUN (SAFE MODE) ---
  void _confirmDeleteAccount() {
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("HAPUS AKUN PERMANEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Semua data stok dan riwayat akan hilang. Ini tidak dapat dibatalkan.", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                labelText: "Ketik 'HAPUS' untuk konfirmasi",
                border: OutlineInputBorder(),
                isDense: true,
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              if (confirmCtrl.text == "HAPUS") {
                Navigator.pop(ctx);
                try {
                   // Fallback: SignOut dan beri pesan
                   await Supabase.instance.client.auth.signOut();
                   ref.invalidate(productListProvider);
                   
                   if (mounted) {
                     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permintaan hapus akun diterima.")));
                   }
                } catch (e) {
                   _showSnack("Gagal memproses permintaan.", isError: true);
                }
              } else {
                _showSnack("Kata konfirmasi salah.", isError: true);
              }
            },
            child: const Text("HAPUS SEKARANG", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), 
        child: Column(
          children: [
            // --- KARTU PROFIL ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF2962FF).withOpacity(0.1),
                    child: Text(
                      _fullName.isNotEmpty ? _fullName[0].toUpperCase() : "U",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2962FF)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_shopName, style: const TextStyle(color: Color(0xFF2962FF), fontWeight: FontWeight.w500)),
                        // Tampilkan Telepon & Alamat jika ada
                        if (_phone.isNotEmpty) 
                          Padding(padding: const EdgeInsets.only(top: 2), child: Text(_phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                        if (_address.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(top: 2), child: Text(_address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditProfileDialog, 
                    icon: const Icon(Icons.edit_square, color: Color(0xFF2962FF)),
                    tooltip: "Edit Profil",
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // --- MENU PENGATURAN ---
            _buildSectionHeader("Pengaturan"),
            
            _buildMenuTile(Icons.language, "Bahasa Aplikasi", "Indonesia (ID)", () => _showSnack("Saat ini hanya Bahasa Indonesia.")),
            
            // Switch Notifikasi (Sekarang Interaktif)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                value: _notifEnabled,
                onChanged: (val) {
                  setState(() => _notifEnabled = val);
                  _showSnack(val ? "Notifikasi Diaktifkan" : "Notifikasi Dinonaktifkan");
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.notifications_outlined, color: Colors.orange),
                ),
                title: const Text("Notifikasi Stok", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                activeColor: const Color(0xFF2962FF),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // --- MENU BANTUAN ---
            _buildSectionHeader("Bantuan"),
            _buildMenuTile(Icons.help_outline_rounded, "Pusat Bantuan", "FAQ & Panduan", () => _showSnack("Membuka halaman panduan...")),
            
            // Tombol Hubungi Admin (WA)
            _buildMenuTile(Icons.support_agent_rounded, "Hubungi Admin", "WhatsApp Support", _contactAdmin),

            const SizedBox(height: 24),

            // --- MENU AKUN (DANGER ZONE) ---
            _buildSectionHeader("Akun"),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.logout, color: Colors.orange),
                    ),
                    title: const Text("Keluar Aplikasi", style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _confirmLogout,
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.delete_forever, color: Colors.red),
                    ),
                    title: const Text("Hapus Akun", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _confirmDeleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 13)),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF2962FF), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      ),
    );
  }
}