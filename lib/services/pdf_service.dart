import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/cart_provider.dart'; 

class PdfInvoiceService {
  
  // Fungsi Utama Cetak Struk
  static Future<void> printReceipt({
    required List<CartItem> items,
    required int total,
    required String cashierName,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String paymentMethod, // <--- PARAMETER BARU
  }) async {
    
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Font setup (Optional: Gunakan font bawaan)
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Format kertas struk (80mm)
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER TOKO ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(shopName, style: pw.TextStyle(font: fontBold, fontSize: 18)),
                    if (shopAddress.isNotEmpty)
                      pw.Text(shopAddress, style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.center),
                    if (shopPhone.isNotEmpty)
                      pw.Text("Telp: $shopPhone", style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5),

              // --- INFO TRANSAKSI ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Tanggal:", style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text(dateStr, style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Kasir:", style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text(cashierName, style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // --- LIST ITEM ---
              pw.ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Nama Barang & Qty
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.product.name, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                              pw.Text("${item.qty} x ${currency.format(item.product.price)}", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                        // Subtotal Item
                        pw.Text(
                          currency.format(item.product.price * item.qty),
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
              pw.Divider(thickness: 0.5),

              // --- TOTAL & PEMBAYARAN ---
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  pw.Text(currency.format(total), style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 5),
              
              // --- TAMPILAN METODE PEMBAYARAN (BARU) ---
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(4)
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Metode Bayar:", style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text(paymentMethod.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Terima Kasih", style: pw.TextStyle(font: fontBold, fontSize: 12))),
              pw.Center(child: pw.Text("Barang yang dibeli tidak dapat ditukar", style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey))),
            ],
          );
        },
      ),
    );

    // Kirim ke Printer / Preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Struk-$dateStr',
    );
  }
}