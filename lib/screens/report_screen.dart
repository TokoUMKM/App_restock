import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/supabase_services.dart';

// --- PROVIDERS ---
final transactionReportProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(supabaseServiceProvider).getTransactionReport();
});

final assetReportProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(supabaseServiceProvider).getAssetReport();
});

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  // --- LOGIKA EXPORT PDF ---
  Future<void> _generatePdf(BuildContext context, WidgetRef ref) async {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata; 

    final String shopName = (metadata?['shop_name'] ?? "TOKO SAYA").toString().toUpperCase();
    final String userName = metadata?['full_name'] ?? user?.email ?? "Admin";
    final String userEmail = user?.email ?? "-";

    final pdf = pw.Document();
    final now = DateTime.now();
    
    // Locale 'id_ID' sudah di-init di main.dart
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    final timeStr = DateFormat('HH:mm').format(now);
    final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(now);

    final txData = await ref.read(supabaseServiceProvider).getTransactionReport();
    final assetData = await ref.read(supabaseServiceProvider).getAssetReport();

    double totalValuation = 0;
    for(var item in assetData) {
      totalValuation += (item['total_value'] as num).toDouble();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("LAPORAN MANAJEMEN STOK", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(shopName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Text("Pemilik: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(userName, style: const pw.TextStyle(fontSize: 10)),
                  ]),
                  pw.Row(children: [
                    pw.Text("Email: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(userEmail, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ]),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Bulan Laporan: $monthStr"),
                      pw.Text("Dicetak: $dateStr, Pukul $timeStr"),
                    ]
                  ),
                  pw.SizedBox(height: 20),
                ]
              )
            ),

            // SECTION 1: RINGKASAN ASET
            pw.Text("1. Ringkasan Valuasi Aset", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total Nilai Aset Barang:"),
                  pw.Text("Rp ${NumberFormat('#,###', 'id_ID').format(totalValuation)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]
              )
            ),
            pw.SizedBox(height: 20),

            // SECTION 2: TABEL TOP ASSETS
            pw.Text("Top 5 Aset Terbesar:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Nama Produk', 'Nilai Aset (Rp)'],
              data: assetData.map((e) => [
                e['product_name'], 
                NumberFormat('#,###', 'id_ID').format(e['total_value'])
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 30),

            // SECTION 3: TABEL AKTIVITAS TRANSAKSI
            pw.Text("2. Aktivitas Stok (30 Hari Terakhir)", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Tanggal', 'Barang Masuk (Qty)', 'Barang Keluar (Qty)'],
              data: txData.map((e) => [
                DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(e['tx_date'])),
                e['total_in'].toString(),
                e['total_out'].toString(),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            
            pw.SizedBox(height: 40),
            pw.Text("Dicetak otomatis oleh sistem Inventory App.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_$shopName',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        appBar: AppBar(
          title: const Text("Laporan & Analitik", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Color(0xFF2962FF),
            labelColor: Color(0xFF2962FF),
            tabs: [
              Tab(text: "Grafik Stok"),
              Tab(text: "Valuasi Aset"),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _generatePdf(context, ref),
              icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD50000)),
              tooltip: "Export PDF",
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            _buildStockChartTab(ref),
            _buildAssetPieTab(ref),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: GRAFIK BAR CHART ---
  Widget _buildStockChartTab(WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tren Pergerakan Stok (7 Hari Terakhir)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ref.watch(transactionReportProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
              data: (rawSqlData) {
                // LOGIKA NORMALISASI DATA
                Map<String, Map<String, dynamic>> dataMap = {};
                for (var item in rawSqlData) {
                  String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(item['tx_date']));
                  dataMap[dateKey] = item;
                }

                List<Map<String, dynamic>> chartData = [];
                DateTime today = DateTime.now();
                
                for (int i = 6; i >= 0; i--) {
                  DateTime d = today.subtract(Duration(days: i));
                  String dateKey = DateFormat('yyyy-MM-dd').format(d);
                  
                  if (dataMap.containsKey(dateKey)) {
                    chartData.add(dataMap[dateKey]!);
                  } else {
                    chartData.add({
                      'tx_date': d.toIso8601String(),
                      'total_in': 0,
                      'total_out': 0,
                    });
                  }
                }

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calculateMaxY(chartData),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                           String type = rodIndex == 0 ? "Masuk" : "Keluar";
                           return BarTooltipItem("$type: ${rod.toY.toInt()}", const TextStyle(color: Colors.white));
                        }
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              final date = DateTime.parse(chartData[index]['tx_date']);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('E d', 'id_ID').format(date), 
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    ),
                    barGroups: chartData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: (item['total_in'] as num).toDouble(),
                            color: Colors.blue,
                            width: 12,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: (item['total_out'] as num).toDouble(),
                            color: Colors.red,
                            width: 12,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSimpleLegend(Colors.blue, "Stok Masuk"),
              const SizedBox(width: 20),
              _buildSimpleLegend(Colors.red, "Stok Keluar"),
            ],
          )
        ],
      ),
    );
  }

  // --- TAB 2: PIE CHART ---
  Widget _buildAssetPieTab(WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Komposisi Nilai Aset (Top 5)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // PIE CHART
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ref.watch(assetReportProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
              data: (data) {
                if (data.isEmpty) return const Center(child: Text("Belum ada aset bernilai"));
                
                final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red];

                return PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final value = (item['total_value'] as num).toDouble();
                      final color = colors[index % colors.length];

                      return PieChartSectionData(
                        color: color,
                        value: value,
                        // Tampilkan persentase atau angka ringkas di dalam Pie
                        title: NumberFormat.compact(locale: 'id_ID').format(value),
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // LEGEND RAPI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Rincian Aset", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                
                ref.watch(assetReportProvider).maybeWhen(
                  data: (data) {
                    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red];
                    return Column(
                      children: data.asMap().entries.map((entry) {
                        return _buildDetailedLegend(
                          color: colors[entry.key % colors.length], 
                          name: entry.value['product_name'] ?? 'Tanpa Nama',
                          price: "Rp ${NumberFormat('#,###', 'id_ID').format(entry.value['total_value'])}"
                        );
                      }).toList(),
                    );
                  },
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Max Y untuk Chart
  double _calculateMaxY(List<dynamic> data) {
    double max = 0;
    for (var item in data) {
      double valIn = (item['total_in'] as num).toDouble();
      double valOut = (item['total_out'] as num).toDouble();
      if (valIn > max) max = valIn;
      if (valOut > max) max = valOut;
    }
    return max == 0 ? 10 : max * 1.2;
  }

  // Legend Sederhana (Untuk Bar Chart)
  Widget _buildSimpleLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Legend Detail & Rapi (Untuk Pie Chart Aset)
  Widget _buildDetailedLegend({required Color color, required String name, required String price}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // Jarak vertikal antar item
      child: Row(
        children: [
          // 1. Indikator Warna
          Container(
            width: 12, 
            height: 12, 
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)
          ),
          const SizedBox(width: 12),
          
          // 2. Nama Produk (Mengisi ruang sisa)
          Expanded(
            child: Text(
              name, 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
              overflow: TextOverflow.ellipsis, // Potong jika kepanjangan
            ),
          ),
          
          const SizedBox(width: 8),

          // 3. Harga (Rata Kanan)
          Text(
            price, 
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)
          ),
        ],
      ),
    );
  }
}