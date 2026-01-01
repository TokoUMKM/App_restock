import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String _phone = "";    
  String _address = ""; 
  
  // State UI
  bool _isLoading = false;
  bool _notifEnabled = true; 

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // --- 1. LOAD DATA PROFIL ---
  void _loadProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata ?? {};
      setState(() {
        _fullName = meta['full_name'] ?? "User Toko";
        _shopName = meta['shop_name'] ?? "Toko Saya";
        _phone = meta['shop_phone'] ?? "";       
        _address = meta['shop_address'] ?? "";   
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20), // Agar tidak ketutup BottomNav
      ),
    );
  }

  // --- 2. EDIT PROFIL ---
  void _showEditProfileDialog() {
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
              const Text("Edit Profil Toko", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              _buildTextField(nameCtrl, "Nama Pemilik", Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(shopCtrl, "Nama Toko", Icons.store_outlined),
              const SizedBox(height: 16),
              _buildTextField(phoneCtrl, "No. Telepon", Icons.phone_outlined, inputType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(addressCtrl, "Alamat", Icons.location_on_outlined, maxLines: 2, isLast: true),
              
              const SizedBox(height: 30),
              
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
                    setState(() => _isLoading = true);
                    
                    try {
                      await Supabase.instance.client.auth.updateUser(
                        UserAttributes(data: {
                          'full_name': nameCtrl.text.trim(), 
                          'shop_name': shopCtrl.text.trim(),
                          'shop_phone': phoneCtrl.text.trim(),   
                          'shop_address': addressCtrl.text.trim() 
                        }),
                      );
                      _loadProfile(); 
                      _showSnack("Profil berhasil diperbarui!");
                    } catch (e) {
                      _showSnack("Gagal update: $e", isError: true);
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, 
      {TextInputType inputType = TextInputType.text, int maxLines = 1, bool isLast = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2962FF))),
      ),
    );
  }

  // --- 3. KONTAK ADMIN ---
  Future<void> _contactAdmin() async {
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

  // --- 4. LOGOUT ---
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Keluar Aplikasi?"),
        content: const Text("Pastikan semua pekerjaan Anda sudah tersimpan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true); // Loading state
              
              await Future.delayed(const Duration(milliseconds: 500));
              await Supabase.instance.client.auth.signOut();
              
              ref.invalidate(productListProvider);
              ref.invalidate(cartProvider);
              
              if (mounted) {
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

  // --- 5. HAPUS AKUN (CRITICAL FIX) ---
  void _confirmDeleteAccount() {
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("HAPUS AKUN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("PERINGATAN: Data stok dan riwayat akan dihapus permanen dari server.\n\nKetik 'HAPUS' untuk melanjutkan.", style: TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 16),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                hintText: "Ketik HAPUS",
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
                setState(() => _isLoading = true); // Tampilkan loading fullscreen

                try {
                   // [FIX: WAJIB PANGGIL RPC UNTUK HAPUS DATA DI DB]
                   await Supabase.instance.client.rpc('delete_user_account');

                   // Logout setelah data bersih
                   await Supabase.instance.client.auth.signOut();
                   
                   // Reset Riverpod
                   ref.invalidate(productListProvider);
                   ref.invalidate(cartProvider);

                   if (mounted) {
                     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                     _showSnack("Akun berhasil dihapus permanen.");
                   }
                } catch (e) {
                   setState(() => _isLoading = false);
                   _showSnack("Gagal menghapus akun: $e", isError: true);
                }
              } else {
                _showSnack("Konfirmasi salah. Ketik 'HAPUS'.", isError: true);
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
    if (_isLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- HEADER MODERN ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF2962FF), 
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFE3F2FD),
                          child: Text(
                            _fullName.isNotEmpty ? _fullName[0].toUpperCase() : "A",
                            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF2962FF)),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: InkWell(
                          onTap: _showEditProfileDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.edit, color: Colors.white, size: 14),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _fullName,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _shopName,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (_phone.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(_phone, style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                    )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- MENU CONTENT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("PENGATURAN"),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_active_outlined, 
                          title: "Notifikasi Stok", 
                          value: _notifEnabled, 
                          onChanged: (val) => setState(() => _notifEnabled = val)
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildMenuTile(
                          icon: Icons.language, 
                          title: "Bahasa", 
                          subtitle: "Indonesia", 
                          onTap: () {
                             _showSnack("Fitur Multi-bahasa segera hadir.");
                          }
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle("BANTUAN"),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.support_agent_rounded, 
                          title: "Hubungi Admin", 
                          subtitle: "WhatsApp Support", 
                          onTap: _contactAdmin
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildMenuTile(
                          icon: Icons.info_outline_rounded, 
                          title: "Tentang Aplikasi", 
                          subtitle: "Versi 1.0.0", 
                          onTap: () {}
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle("AKUN"),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.logout_rounded, 
                          title: "Keluar Aplikasi", 
                          onTap: _confirmLogout,
                          isDestructive: false, 
                          overrideColor: Colors.redAccent
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildMenuTile(
                          icon: Icons.delete_forever_rounded, 
                          title: "Hapus Akun", 
                          onTap: _confirmDeleteAccount,
                          isDestructive: true 
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
    );
  }

  Widget _buildMenuTile({
    required IconData icon, 
    required String title, 
    String? subtitle, 
    required VoidCallback onTap, 
    bool isDestructive = false,
    Color? overrideColor,
  }) {
    final Color contentColor = overrideColor ?? (isDestructive ? Colors.red : Colors.grey.shade700);
    
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, color: contentColor, size: 20),
      ),
      title: Text(title, style: TextStyle(
        fontWeight: FontWeight.w600, 
        fontSize: 14, 
        color: isDestructive ? Colors.red : Colors.black87
      )),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon, 
    required String title, 
    required bool value, 
    required ValueChanged<bool> onChanged
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2962FF),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.grey.shade700, size: 20),
      ),
    );
  }
}