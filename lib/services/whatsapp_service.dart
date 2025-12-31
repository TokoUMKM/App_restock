import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  static Future<void> sendOrder(String phone, String message) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }
    // Encode Pesan
    final Uri url = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}"
    );

    // Eksekusi dengan Fallback
    try {
      // Coba cek dulu (Best Practice)
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      throw 'Gagal membuka WhatsApp. Pastikan aplikasi terinstall.';
    }
  }
}