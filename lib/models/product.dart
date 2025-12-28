// Lokasi: lib/models/product.dart

enum StockStatus { safe, warning, danger }

class Product {
  final String id;
  final String name;
  final int currentStock;
  final double daysRemaining; // Burn-rate logic
  final StockStatus status;

  Product({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.daysRemaining,
    required this.status,
  });
}
