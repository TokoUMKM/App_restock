import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';

// --- IMPORTS SCREEN ---
import 'screens/dashboard_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/camera_screen.dart'; 
import 'screens/cashier_screen.dart'; 
import 'screens/welcome_screen.dart'; 
import 'services/notification_service.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      throw Exception("File .env tidak ditemukan. Pastikan konfigurasi benar.");
    }

    final sbUrl = dotenv.env['SUPABASE_URL'];
    final sbKey = dotenv.env['SUPABASE_KEY'];
    if (sbUrl == null || sbKey == null) {
      throw Exception("SUPABASE_URL atau SUPABASE_KEY kosong di .env");
    }

    await Supabase.initialize(url: sbUrl, anonKey: sbKey);
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    await NotificationService.init().catchError((e) {
      debugPrint("Gagal init notifikasi: $e");
    });

    await initializeDateFormatting('id_ID', null);

    // [PENTING] Izinkan Landscape juga
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    debugPrint("FATAL ERROR: $error");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TokoUMKM',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2962FF),
          brightness: Brightness.light,
          primary: const Color(0xFF2962FF),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
              color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final session = Supabase.instance.client.auth.currentSession;
          
          if (session != null) {
            return const MainScaffold();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const DashboardScreen(),     
    const ProductListScreen(),   
    const CashierScreen(),       
    const ProfileScreen(),       
  ];

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
      extendBody: true,
      backgroundColor: const Color(0xFFF4F7FC),
      
      // [SOLUSI #5] Matikan resize agar FAB/Navbar tidak terdorong keyboard
      resizeToAvoidBottomInset: false, 

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      floatingActionButton: SizedBox(
        width: 65, 
        height: 65,
        child: FloatingActionButton(
          onPressed: _onScanPressed,
          elevation: 4,
          backgroundColor: const Color(0xFFFF6D00), 
          shape: const CircleBorder(), 
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 28, color: Colors.white),
              Text("SCAN", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), 
        notchMargin: 8.0, 
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 15,
        height: 70,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.dashboard_rounded, label: "Home", index: 0),
            _buildNavItem(icon: Icons.inventory_2_rounded, label: "Stok", index: 1),
            const SizedBox(width: 40), 
            _buildNavItem(icon: Icons.point_of_sale_rounded, label: "Kasir", index: 2),
            _buildNavItem(icon: Icons.person_rounded, label: "Profil", index: 3),
          ],
        ),
      ),
    );
  }

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
            Icon(icon, color: color, size: isSelected ? 28 : 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}