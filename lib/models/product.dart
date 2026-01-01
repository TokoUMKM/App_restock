class Product {
  final String? id; 
  final String sku;
  final String name;
  final int currentStock;
  final int minStock;
  final int price;
  final String? userId;
  final String? supplierId; // Tambahan Baru
  
  // Field tambahan agar fitur Scan Struk tidak error
  final String unit;         
  final String? description; 
  final String? category;    

  Product({
    this.id,
    required this.sku,
    required this.name,
    required this.currentStock,
    required this.minStock,
    required this.price,
    this.userId,
    this.supplierId,
    this.unit = 'Pcs',          // Default 'Pcs'
    this.description,
    this.category = 'Umum',     // Default 'Umum'
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    // Helper kecil untuk memaksa data jadi Integer (Mencegah crash tipe data)
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return Product(
      id: map['id']?.toString(), 
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      
      currentStock: parseInt(map['current_stock']),
      minStock: parseInt(map['min_stock']),
      price: parseInt(map['price']),
      
      userId: map['user_id']?.toString(),
      supplierId: map['supplier_id']?.toString(), 

      // Mapping field tambahan
      unit: map['unit'] ?? 'Pcs',
      description: map['description'],
      category: map['category'] ?? 'Umum',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sku': sku,
      'name': name,
      'current_stock': currentStock,
      'min_stock': minStock,
      'price': price,
      if (userId != null) 'user_id': userId,
      'supplier_id': supplierId, // Kirim null jika tidak ada supplier
      
      // Kirim field tambahan ke DB
      'unit': unit,
      'description': description,
      'category': category,
    };
  }
}