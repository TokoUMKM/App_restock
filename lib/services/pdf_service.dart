import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';

class PdfInvoiceService {
  // Generate & Print Struk (Dinamis)
  static Future<void> printReceipt({
    required List<CartItem> items,
    required int total,
    required String cashierName,
    required String shopName,    
    required String shopAddress, 
    required String shopPhone,   
  }) async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Ukuran Kertas Struk Thermal 80mm
        margin: const pw.EdgeInsets.all(10), 
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER TOKO ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(shopName.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    if (shopAddress.isNotEmpty) 
                      pw.Text(shopAddress, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
                    if (shopPhone.isNotEmpty) 
                      pw.Text("Telp: $shopPhone", style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              
              // INFO TRANSAKSI
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Tgl: $dateStr", style: const pw.TextStyle(fontSize: 8)),
                  pw.Text("Kasir: $cashierName", style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 10),

              // LIST BARANG
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // Nama
                  1: const pw.FlexColumnWidth(1), // Qty
                  2: const pw.FlexColumnWidth(2), // Harga
                },
                children: [
                  // Header Tabel
                  pw.TableRow(children: [
                    pw.Text("Item", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.Text("Qty", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.Text("Total", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  ]),
                  // Isi Tabel
                  ...items.map((e) {
                    return pw.TableRow(children: [
                      pw.Text(e.product.name, style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("x${e.qty}", style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(currency.format(e.product.price * e.qty), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
                    ]);
                  }).toList(),
                ],
              ),
              
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // TOTAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(currency.format(total), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Terima Kasih", style: const pw.TextStyle(fontSize: 9))),
              pw.Center(child: pw.Text("Powered by Restock App", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey))),
            ],
          );
        },
      ),
    );

    // Tampilkan Preview
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}