import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  static Future<void> sendOrder(String phone, String message) async {
    final String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri url = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}"
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Tidak dapat membuka WhatsApp';
    }
  }
}