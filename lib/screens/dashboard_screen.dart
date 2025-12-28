import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dangerCount = ref.watch(dangerCountProvider);
    final products = ref.watch(productListProvider);
    final totalStock = products.fold(0, (sum, item) => sum + item.currentStock);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. PREMIUM HEADER
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                "Overview Toko",
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              background: Container(
                color: Colors.white,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(top: 50, right: 20),
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.black87),
                ),
              ),
            ),
          ),

          // 2. CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION: URGENT ACTION ---
                  if (dangerCount > 0) _buildAlertCard(dangerCount),

                  const SizedBox(height: 24),

                  // --- SECTION: SUMMARY METRICS ---
                  Row(
                    children: [
                      Expanded(
                          child: _buildMetricCard(
                              "Total SKU",
                              "${products.length}",
                              Icons.qr_code,
                              Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildMetricCard("Total Unit", "$totalStock",
                              Icons.layers, Colors.purple)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text("Aksi Cepat",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // --- SECTION: QUICK ACTIONS ---
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildActionBtn(
                            "Scan Struk",
                            Icons.document_scanner_rounded,
                            const Color(0xFF2962FF)),
                        _buildActionBtn("Input Manual", Icons.edit_note_rounded,
                            Colors.teal),
                        _buildActionBtn(
                            "Laporan", Icons.bar_chart_rounded, Colors.orange),
                        _buildActionBtn("Supplier",
                            Icons.local_shipping_rounded, Colors.indigo),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text("Performa Stok",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Placeholder Chart
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text("Grafik Penjualan Mingguan",
                              style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF2962FF),
        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
        label: const Text("Scan Struk",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAlertCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.red.shade100, shape: BoxShape.circle),
            child: Icon(Icons.warning_rounded, color: Colors.red.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Stok Kritis Terdeteksi",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800)),
                const SizedBox(height: 4),
                Text("$count item perlu di-restock dalam 2 hari.",
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)
              ],
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
