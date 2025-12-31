import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Wajib untuk contentType
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import '../models/product.dart';

class AIService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // FITUR 1: SMART RESTOCK (Bisa pakai DeepSeek/Gemini/Apapun di Backend)
  // ---------------------------------------------------------------------------
  Future<String> generateRestockMessage(String supplierName, Product product) async {
    String defaultMessage = "Halo $supplierName, saya mau restock ${product.name}. Mohon info stok.";

    try {
      final response = await _supabase.functions.invoke(
        'generate-order', 
        body: {
          'supplier_name': supplierName,
          'items': [
            {
              'name': product.name,
              'sku': product.sku,
              'current_stock': product.currentStock,
              'min_stock': product.minStock
            }
          ]
        },
      );

      final data = response.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      } else if (data is String) {
        return data;
      }
      return defaultMessage;

    } catch (e) {
      print("AI Restock Error: $e");
      return defaultMessage;
    }
  }

  // ---------------------------------------------------------------------------
  // FITUR 2: SCAN STRUK (Backend: GROQ LLAMA 3.2 VISION)
  // ---------------------------------------------------------------------------
  Future<ReceiptResult> analyzeReceipt(File imageFile) async {
    try {
      // 1. Ambil URL & Key dari .env
      final projectUrl = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_KEY']; // Kunci Anonim (Stabil)

      if (projectUrl == null || anonKey == null) {
        throw "Konfigurasi .env belum lengkap (SUPABASE_URL / SUPABASE_KEY).";
      }
      
      final functionUrl = Uri.parse('$projectUrl/functions/v1/parse-receipt');

      // 2. Siapkan Request
      var request = http.MultipartRequest('POST', functionUrl);

      // 3. Attach File Gambar
      // MediaType sangat penting agar Backend tahu ini gambar
      var pic = await http.MultipartFile.fromPath(
        'file', 
        imageFile.path,
        contentType: MediaType('image', 'jpeg'), 
      );
      request.files.add(pic);

      // 4. HEADER OTENTIKASI
      // Kita gunakan Anon Key agar tidak kena error 401 Invalid JWT
      request.headers.addAll({
        'Authorization': 'Bearer $anonKey', 
        'apikey': anonKey, 
        'x-client-info': 'supabase-flutter-sdk',
      });

      // 5. Kirim Request
      // print("Mengirim gambar ke Groq..."); // Debugging
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 6. Handle Response
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Backend Groq kita mengembalikan { success: true/false, user_message: "...", data: ... }
        return ReceiptResult.fromJson(jsonResponse);
      } else {
        // Tangkap error server (misal 500 atau 429 Limit)
        print("Server Error: ${response.body}");
        throw "Gagal scan (${response.statusCode}). Coba lagi.";
      }

    } catch (e) {
      print("AI Scan Error: $e");
      return ReceiptResult(
        success: false, 
        error: e.toString().replaceAll("Exception:", "").trim()
      );
    }
  }
}

// ---------------------------------------------------------------------------
// MODELS (SINKRON DENGAN OUTPUT GROQ)
// ---------------------------------------------------------------------------

class ReceiptResult {
  final bool success;
  final ReceiptData? data;
  final String? error;

  ReceiptResult({required this.success, this.data, this.error});

  factory ReceiptResult.fromJson(Map<String, dynamic> json) {
    return ReceiptResult(
      success: json['success'] ?? false,
      // Backend Groq kirim 'user_message', kita tampilkan sebagai error jika success=false
      error: json['user_message'] ?? json['error'],
      data: json['data'] != null ? ReceiptData.fromJson(json['data']) : null,
    );
  }
}

class ReceiptData {
  final String? supplierName;
  final String? transactionDate;
  final String summaryText;
  final List<ReceiptItem> items;

  ReceiptData({
    this.supplierName, 
    this.transactionDate, 
    required this.summaryText,
    required this.items
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<ReceiptItem> itemsList = list.map((i) => ReceiptItem.fromJson(i)).toList();

    return ReceiptData(
      supplierName: json['supplier_name'],
      transactionDate: json['transaction_date'],
      summaryText: json['summary_text'] ?? "Ringkasan data struk",
      items: itemsList,
    );
  }
}

class ReceiptItem {
  final String name;
  final int qty;
  final int price;

  ReceiptItem({required this.name, required this.qty, required this.price});

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] ?? "Item Tanpa Nama",
      // Gunakan num agar aman (kadang AI kirim string angka "1" atau int 1)
      qty: (json['qty'] is String ? int.tryParse(json['qty']) : json['qty']) ?? 1,
      price: (json['price'] is String ? int.tryParse(json['price']) : json['price']) ?? 0,
    );
  }
}