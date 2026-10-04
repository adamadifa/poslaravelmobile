import 'package:flutter/material.dart';
import 'package:poslaravelmobile/core/services/printer_service.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterProvider extends ChangeNotifier {
  final PrinterService _printerService = PrinterService();

  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _connectedMac;
  String? _connectedName;
  String _statusMessage = 'Belum terhubung ke printer Bluetooth';

  List<BluetoothInfo> get devices => _devices;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get connectedMac => _connectedMac;
  String? get connectedName => _connectedName;
  String get statusMessage => _statusMessage;

  String get paperSize => _printerService.paperSize;
  bool get autoPrint => _printerService.autoPrint;
  int get copies => _printerService.copies;
  String get footerNote => _printerService.footerNote;

  PrinterProvider() {
    init();
  }

  Future<void> init() async {
    await _printerService.loadSettings();
    _connectedMac = _printerService.savedMac;
    _connectedName = _printerService.savedName;
    await checkConnectionStatus();
    notifyListeners();
  }

  Future<void> checkConnectionStatus() async {
    try {
      _isConnected = await _printerService.isConnected();
      if (_isConnected) {
        _statusMessage = 'Terhubung ke ${_connectedName ?? "Printer Bluetooth"}';
      } else {
        _statusMessage = _connectedMac != null
            ? 'Printer tersimpan: ${_connectedName ?? _connectedMac} (Offline)'
            : 'Belum terhubung ke printer Bluetooth';
      }
    } catch (_) {
      _isConnected = false;
    }
    notifyListeners();
  }

  Future<void> scanDevices() async {
    _isScanning = true;
    _statusMessage = 'Mencari perangkat printer Bluetooth...';
    notifyListeners();

    try {
      final isBtOn = await _printerService.isBluetoothEnabled();
      if (!isBtOn) {
        _statusMessage = 'Bluetooth HP dalam keadaan mati. Silakan nyalakan Bluetooth.';
        _isScanning = false;
        notifyListeners();
        return;
      }

      _devices = await _printerService.getPairedDevices();
      _statusMessage = _devices.isEmpty
          ? 'Tidak ada perangkat printer Bluetooth tersambung/paired.'
          : 'Ditemukan ${_devices.length} perangkat Bluetooth';
      
      await checkConnectionStatus();
    } catch (e) {
      _statusMessage = 'Gagal memindai Bluetooth: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> connect(String mac, String name) async {
    _isConnecting = true;
    _statusMessage = 'Menghubungkan ke $name...';
    notifyListeners();

    try {
      final success = await _printerService.connect(mac, name);
      if (success) {
        _isConnected = true;
        _connectedMac = mac;
        _connectedName = name;
        _statusMessage = 'Berhasil terhubung ke $name';
      } else {
        _isConnected = false;
        _statusMessage = 'Gagal menghubungkan ke $name. Pastikan printer menyala.';
      }
      return success;
    } catch (e) {
      _isConnected = false;
      _statusMessage = 'Error koneksi: $e';
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<bool> disconnect() async {
    try {
      await _printerService.disconnect();
      _isConnected = false;
      _statusMessage = 'Koneksi printer diputuskan';
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> testPrint({String? storeName}) async {
    try {
      final bytes = await _printerService.generateTestReceiptBytes(storeName: storeName);
      final success = await _printerService.printBytes(bytes);
      if (success) {
        _statusMessage = 'Uji coba cetak berhasil dikirim!';
      } else {
        _statusMessage = 'Gagal mencetak. Cek koneksi printer.';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _statusMessage = 'Gagal mencetak: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> printSale({
    required String storeName,
    String? storeAddress,
    String? storePhone,
    required String invoiceNumber,
    required String dateString,
    required String cashierName,
    String? customerName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    double discount = 0,
    double tax = 0,
    required double grandTotal,
    required String paymentMethod,
    double cashGiven = 0,
    double changeAmount = 0,
  }) async {
    try {
      final bytes = await _printerService.generateSaleReceiptBytes(
        storeName: storeName,
        storeAddress: storeAddress,
        storePhone: storePhone,
        invoiceNumber: invoiceNumber,
        dateString: dateString,
        cashierName: cashierName,
        customerName: customerName,
        items: items,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        grandTotal: grandTotal,
        paymentMethod: paymentMethod,
        cashGiven: cashGiven,
        changeAmount: changeAmount,
      );
      return await _printerService.printBytes(bytes);
    } catch (e) {
      debugPrint('Print Sale Error: $e');
      return false;
    }
  }

  Future<void> updateConfig({
    String? paperSize,
    bool? autoPrint,
    int? copies,
    String? footerNote,
  }) async {
    await _printerService.saveSettings(
      paperSize: paperSize,
      autoPrint: autoPrint,
      copies: copies,
      footerNote: footerNote,
    );
    notifyListeners();
  }
}
