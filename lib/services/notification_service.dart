import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/product.dart';

class NotificationService {
  // 1. Plugin Notifikasi Lokal & Flag Dialog
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isDialogShowing = false;

  // ===========================================================================
  // A. SETUP AWAL (Dipanggil di main.dart & dashboard_screen.dart)
  // ===========================================================================

  /// Inisialisasi Settings Notifikasi Lokal
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings, 
      iOS: iosSettings
    );

    await _notificationsPlugin.initialize(settings);
  }

  /// Inisialisasi Firebase Cloud Messaging (FCM)
  static Future<void> initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Minta Izin (Wajib untuk Android 13+ & iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('LOG FCM: Izin Diberikan');
      
      // 2. Subscribe ke Topik Stok (Agar menerima pesan dari server)
      await messaging.subscribeToTopic('stock_alerts');
      
      // 3. Handle Pesan saat Aplikasi SEDANG DIBUKA (Foreground)
      // Firebase tidak memunculkan notifikasi otomatis jika app terbuka, jadi kita buat manual.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('LOG FCM: Pesan Foreground diterima: ${message.notification?.title}');
        
        if (message.notification != null) {
          _showSystemNotification(
            message.notification!.title ?? 'Info',
            message.notification!.body ?? 'Ada update stok',
          );
        }
      });
    }
  }

  // ===========================================================================
  // B. LOGIKA UTAMA (Local Check & Display)
  // ===========================================================================

  /// Fungsi Cek Stok Lokal (Dipanggil dari DashboardScreen)
  static void checkAndShowStockAlert(BuildContext context, List<Product> products) {
    // 1. Filter Produk Kritis
    final criticalProducts = products.where((p) {
      return p.currentStock <= 0 || p.currentStock <= p.minStock;
    }).toList();

    print("LOG NOTIFIKASI: Total=${products.length}, Kritis=${criticalProducts.length}");

    if (criticalProducts.isEmpty) return; 

    // 2. Tampilkan DIALOG (Hanya jika belum tampil)
    if (!_isDialogShowing) {
      _showDialog(context, criticalProducts);
    }

    // 3. (Opsional) Tampilkan juga Notifikasi di Status Bar agar tersimpan di history
    // _showSystemNotification("Perhatian Stok", "${criticalProducts.length} barang perlu restock.");
  }

  // ===========================================================================
  // C. HELPER FUNCTIONS (Tampilan)
  // ===========================================================================

  /// Menampilkan Notifikasi di Status Bar HP (System Tray)
  static Future<void> _showSystemNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'stock_alert_channel', // ID Channel
      'Stok Menipis',        // Nama Channel
      channelDescription: 'Notifikasi penting stok toko',
      importance: Importance.max, // Max = Muncul popup di atas layar (Heads-up)
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Colors.red,
      styleInformation: BigTextStyleInformation(''), // Agar teks panjang bisa dibaca
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // ID Unik (pakai waktu agar bisa numpuk)
      title, 
      body, 
      details
    );
  }

  /// Menampilkan Popup Dialog di Tengah Layar
  static void _showDialog(BuildContext context, List<Product> criticalProducts) {
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text("Perhatian Stok!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Terdapat ${criticalProducts.length} barang yang perlu segera direstock:",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              
              // List Barang (Dibatasi max 4)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: criticalProducts.length > 4 ? 4 : criticalProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (ctx, i) {
                    final p = criticalProducts[i];
                    final isEmpty = p.currentStock <= 0;
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isEmpty ? Colors.red.shade50 : Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEmpty ? Icons.block : Icons.low_priority,
                            size: 16,
                            color: isEmpty ? Colors.red : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                isEmpty ? "Stok Habis" : "Sisa: ${p.currentStock} ${p.unit}",
                                style: TextStyle(
                                  fontSize: 11, 
                                  color: isEmpty ? Colors.red : Colors.orange.shade800
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              if (criticalProducts.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      "+ ${criticalProducts.length - 4} barang lainnya",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _isDialogShowing = false;
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text("Nanti Saja", style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _isDialogShowing = false;
                    Navigator.pop(ctx);
                    // Opsi: Navigasi ke halaman stok
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Cek Stok"),
                ),
              ),
            ],
          )
        ],
      ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }
}