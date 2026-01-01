class Supplier {
  final String id;
  final String name;
  final String phoneNumber;

  Supplier({
    required this.id, 
    required this.name, 
    required this.phoneNumber
  });

  // Factory untuk mengubah data JSON/Map dari Supabase menjadi Object Dart
  // Menggunakan 'fromMap' adalah standar industri untuk Riverpod/Supabase
  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      // Konversi aman ke String (mencegah error jika ID berupa angka)
      id: map['id']?.toString() ?? '', 
      
      // Default value string kosong jika null (Anti Crash)
      name: map['name'] ?? 'Tanpa Nama', 
      
      // Cek dua kemungkinan nama kolom: 'phone_number' atau 'phone'
      phoneNumber: map['phone_number'] ?? map['phone'] ?? '', 
    );
  }

  // Method untuk mengubah Object kembali ke Map (Berguna saat Simpan/Update)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone_number': phoneNumber,
    };
  }
  
  // Getter Helper untuk Link WhatsApp
  // Membersihkan karakter non-angka agar link valid (misal: "0812-345" -> "62812345")
  String get waLink {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), ''); // Hapus dash/spasi
    
    // Ganti 08 di depan dengan 62
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }
    
    return "https://wa.me/$cleanNumber";
  }
}