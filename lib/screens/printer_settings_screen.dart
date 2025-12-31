import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<BluetoothInfo> _devices = [];
  String _connectedMac = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() => _isLoading = true);
    
    // 1. Minta Izin Bluetooth
    await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();

    // 2. Ambil List Device yang sudah dipairing (Bonded)
    final List<BluetoothInfo> bondedDevices = await PrintBluetoothThermal.pairedBluetooths;
    
    // 3. Cek Status Koneksi saat ini
    final bool isConnected = await PrintBluetoothThermal.connectionStatus;
    
    setState(() {
      _devices = bondedDevices;
      _isLoading = false;
      // Library ini tidak memberitahu MAC mana yang connect, jadi kita reset status UI dulu
      if (!isConnected) _connectedMac = ""; 
    });
  }

  Future<void> _connect(String macAddress) async {
    setState(() => _isLoading = true);
    
    try {
      // Disconnect dulu yang lama (biar aman)
      await PrintBluetoothThermal.disconnect;
      
      // Connect yang baru
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      
      if (result) {
        setState(() => _connectedMac = macAddress);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Printer Terhubung!"), backgroundColor: Colors.green));
      } else {
        throw "Gagal menghubungkan.";
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Printer Bluetooth"),
        actions: [
          IconButton(onPressed: _scanDevices, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Pastikan Printer sudah dinyalakan dan dipairing lewat menu Bluetooth HP.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _devices.length,
                  separatorBuilder: (_,__) => const Divider(),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isConnected = _connectedMac == device.macAdress;

                    return ListTile(
                      leading: Icon(Icons.print, color: isConnected ? Colors.green : Colors.grey),
                      title: Text(device.name),
                      subtitle: Text(device.macAdress),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected ? Colors.red.shade50 : Colors.blue.shade50,
                          foregroundColor: isConnected ? Colors.red : Colors.blue,
                        ),
                        onPressed: () => _connect(device.macAdress),
                        child: Text(isConnected ? "Terhubung" : "Hubungkan"),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}