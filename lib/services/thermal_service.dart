import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';

class ThermalPrinterService {
  // Cek Koneksi & Permission
  Future<bool> checkConnection() async {
    // Cek izin bluetooth dulu (Library ini butuh izin lokasi & bluetooth connect)
    final bool result = await PrintBluetoothThermal.connectionStatus;
    return result;
  }

  // Fungsi Cetak
  Future<void> printReceipt({
    required List<CartItem> items,
    required int total,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String cashierName,
  }) async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      throw "Printer belum terhubung. Cek Pengaturan Printer.";
    }

    // 1. SIAPKAN GENERATOR (Kertas 58mm adalah standar printer bluetooth portable)
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yy HH:mm').format(now);

    // 2. SUSUN STRUK (ESC/POS COMMANDS)
    
    // --- HEADER ---
    bytes += generator.text(shopName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    
    if (shopAddress.isNotEmpty) {
      bytes += generator.text(shopAddress, styles: const PosStyles(align: PosAlign.center));
    }
    if (shopPhone.isNotEmpty) {
      bytes += generator.text("Telp: $shopPhone", styles: const PosStyles(align: PosAlign.center));
    }
    
    bytes += generator.feed(1);
    bytes += generator.hr(); // Garis putus-putus

    // --- INFO ---
    bytes += generator.row([
      PosColumn(text: 'Tgl: $dateStr', width: 6, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: 'Kasir: $cashierName', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();

    // --- ITEMS ---
    for (var item in items) {
      // Baris 1: Nama Barang
      bytes += generator.text(item.product.name, styles: const PosStyles(align: PosAlign.left, bold: true));
      
      // Baris 2: Qty x Harga .... Total
      bytes += generator.row([
        PosColumn(
          text: '${item.qty} x ${NumberFormat.decimalPattern('id').format(item.product.price)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: currency.format(item.product.price * item.qty),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    // --- TOTAL ---
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(height: PosTextSize.size2, bold: true)),
      PosColumn(
          text: currency.format(total),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
    ]);

    bytes += generator.feed(1);
    
    // --- FOOTER ---
    bytes += generator.text('Terima Kasih', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Barang yg dibeli tdk dpt ditukar', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(2); // Spasi bawah untuk sobek kertas

    // 3. KIRIM KE PRINTER
    await PrintBluetoothThermal.writeBytes(bytes);
  }
}