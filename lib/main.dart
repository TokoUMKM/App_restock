import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- IMPORTS SCREEN ---
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/spalsh_screen.dart';
import 'screens/camera_screen.dart'; 
 import 'screens/cashier_screen.dart'; // Buka komen ini jika file sudah ada

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env & Supabase
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_KEY'] ?? '',
  );

  await initializeDateFormatting('id_ID', null);

  // Setup Status Bar (Transparan, Icon Gelap)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart UMKM Restock',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC), // Warna background global
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2962FF),
          brightness: Brightness.light,
          primary: const Color(0xFF2962FF),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Agar menyatu dengan background
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
              color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}

// --- MAIN SCAFFOLD (MODIFIED: SCAN TENGAH & MENONJOL) ---
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  // Daftar Halaman (Scan tidak masuk sini karena dia aksi langsung/overlay)
  final List<Widget> _pages = [
    const DashboardScreen(),     // Index 0: Home
    const ProductListScreen(),   // Index 1: Stok
    // Index 2 & 3 bergeser karena Scan ada di tombol tengah terpisah
    const CashierScreen(),       // Index 2: Kasir (Pindah ke kanan)
    const ProfileScreen(),       // Index 3: Profile
  ];

  // Aksi Tombol Scan (Membuka Kamera Langsung)
  void _onScanPressed() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const CameraScreen())
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // PENTING: Agar background menyatu dengan lekukan tombol
      backgroundColor: const Color(0xFFF4F7FC),
      
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // --- TOMBOL SCAN (TENGAH, BESAR, KONTRAS) ---
      floatingActionButton: SizedBox(
        width: 70, // Ukuran lebih besar dari standar
        height: 70,
        child: FloatingActionButton(
          onPressed: _onScanPressed,
          elevation: 4,
          backgroundColor: const Color(0xFFFF6D00), // WARNA KONTRAS (Oranye)
          shape: const CircleBorder(), // Bulat sempurna
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 30, color: Colors.white),
              SizedBox(height: 2),
              Text("SCAN", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))
            ],
          ),
        ),
      ),
      // Posisi 'Docked' membuat tombol menempel di tengah BottomBar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- NAVIGATION BAR ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Membuat lekukan (notch)
        notchMargin: 10.0, // Jarak lekukan dari tombol
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 10,
        height: 70,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // KIRI (Home & Stok)
            _buildNavItem(icon: Icons.dashboard_rounded, label: "Home", index: 0),
            _buildNavItem(icon: Icons.inventory_2_rounded, label: "Stok", index: 1),

            // SPASI KOSONG DI TENGAH (Untuk tombol Scan)
            const SizedBox(width: 40),

            // KANAN (Kasir & Profil)
            _buildNavItem(icon: Icons.point_of_sale_rounded, label: "Kasir", index: 2),
            _buildNavItem(icon: Icons.person_rounded, label: "Profil", index: 3),
          ],
        ),
      ),
    );
  }

  // Helper Widget untuk Item Menu agar kodenya rapi
  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? const Color(0xFF2962FF) : Colors.grey.shade400;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}