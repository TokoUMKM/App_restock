import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/product.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Inisialisasi (Dipanggil saat aplikasi mulai)
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Izin untuk iOS (Optional jika nanti mau build iOS)
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

  // 2. Minta Izin (Khusus Android 13+)
  static Future<void> requestPermission() async {
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // 3. Tampilkan Notifikasi Stok
  static Future<void> checkAndShowStockAlert(List<Product> products) async {
    // Filter produk yang stoknya kritis ( <= minStock )
    final criticalItems = products.where((p) => p.currentStock <= p.minStock).toList();

    if (criticalItems.isEmpty) return;

    // Supaya tidak spam, kita rangkum dalam 1 notifikasi jika itemnya banyak
    String bodyText;
    if (criticalItems.length == 1) {
      bodyText = "Stok ${criticalItems.first.name} tinggal ${criticalItems.first.currentStock}!";
    } else {
      bodyText = "${criticalItems.length} barang perlu restock segera (termasuk ${criticalItems.first.name}).";
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'stock_channel', 'Stock Alerts',
      channelDescription: 'Notifikasi saat stok menipis',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0, // ID Notifikasi (0 = akan ditimpa jika muncul lagi)
      'Peringatan Stok!', 
      bodyText, 
      details
    );
  }
}