import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  static const String _prefKeyMac = 'printer_mac_address';
  static const String _prefKeyName = 'printer_device_name';
  static const String _prefKeyPaper = 'printer_paper_size'; // '58' or '80'
  static const String _prefKeyAutoPrint = 'printer_auto_print_checkout';
  static const String _prefKeyCopies = 'printer_copy_count';
  static const String _prefKeyFooter = 'printer_footer_note';

  String? _savedMac;
  String? _savedName;
  String _paperSize = '58';
  bool _autoPrint = true;
  int _copies = 1;
  String _footerNote = 'Terima Kasih Atas Kunjungan Anda!';

  String? get savedMac => _savedMac;
  String? get savedName => _savedName;
  String get paperSize => _paperSize;
  bool get autoPrint => _autoPrint;
  int get copies => _copies;
  String get footerNote => _footerNote;

  /// Load saved printer configurations from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _savedMac = prefs.getString(_prefKeyMac);
    _savedName = prefs.getString(_prefKeyName);
    _paperSize = prefs.getString(_prefKeyPaper) ?? '58';
    _autoPrint = prefs.getBool(_prefKeyAutoPrint) ?? true;
    _copies = prefs.getInt(_prefKeyCopies) ?? 1;
    _footerNote = prefs.getString(_prefKeyFooter) ?? 'Terima Kasih Atas Kunjungan Anda!';
  }

  /// Save printer config
  Future<void> saveSettings({
    String? mac,
    String? name,
    String? paperSize,
    bool? autoPrint,
    int? copies,
    String? footerNote,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (mac != null) {
      _savedMac = mac;
      await prefs.setString(_prefKeyMac, mac);
    }
    if (name != null) {
      _savedName = name;
      await prefs.setString(_prefKeyName, name);
    }
    if (paperSize != null) {
      _paperSize = paperSize;
      await prefs.setString(_prefKeyPaper, paperSize);
    }
    if (autoPrint != null) {
      _autoPrint = autoPrint;
      await prefs.setBool(_prefKeyAutoPrint, autoPrint);
    }
    if (copies != null) {
      _copies = copies;
      await prefs.setInt(_prefKeyCopies, copies);
    }
    if (footerNote != null) {
      _footerNote = footerNote;
      await prefs.setString(_prefKeyFooter, footerNote);
    }
  }

  /// Request Bluetooth & Location permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool isGranted = statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );

    // If bluetoothScan is permanently denied or not applicable, check connection
    return isGranted || await Permission.bluetoothConnect.isGranted;
  }

  /// Check if Bluetooth is powered on
  Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (_) {
      return false;
    }
  }

  /// Scan paired bluetooth devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      await requestPermissions();
      final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Check connection status
  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  /// Connect to Bluetooth printer by MAC Address
  Future<bool> connect(String macAddress, String deviceName) async {
    try {
      await requestPermissions();
      final bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (connected) {
        await saveSettings(mac: macAddress, name: deviceName);
      }
      return connected;
    } catch (e) {
      return false;
    }
  }

  /// Disconnect printer
  Future<bool> disconnect() async {
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (_) {
      return false;
    }
  }

  /// Generate Test Receipt Bytes
  Future<List<int>> generateTestReceiptBytes({String? storeName}) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      _paperSize == '80' ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );
    List<int> bytes = [];

    final name = storeName ?? 'WARUNG PRO POS';
    final now = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    bytes += generator.reset();
    bytes += generator.text(
      name,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      'SISTEM KASIR & INVENTORI PRO',
      styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'UJI COBA CETAK STRUK THERMAL',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Waktu: $now',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Ukuran Kertas: ${_paperSize}mm',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Koneksi: Bluetooth ESC/POS OK',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    // Sample Items
    bytes += generator.row([
      PosColumn(text: '1x Kopi Espresso', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rp 18.000', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: '2x Roti Bakar Coklat', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rp 30.000', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rp 48.000', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'BAYAR (TUNAI)', width: 6),
      PosColumn(text: 'Rp 50.000', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'KEMBALI', width: 6),
      PosColumn(text: 'Rp 2.000', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text(
      '================================',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      _footerNote,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Simpan struk ini sebagai bukti sah',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Generate Receipt Bytes from Sale Transaction
  Future<List<int>> generateSaleReceiptBytes({
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
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      _paperSize == '80' ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );
    List<int> bytes = [];
    final curFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    bytes += generator.reset();

    // Store Header
    bytes += generator.text(
      storeName.toUpperCase(),
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    if (storeAddress != null && storeAddress.isNotEmpty) {
      bytes += generator.text(
        storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (storePhone != null && storePhone.isNotEmpty) {
      bytes += generator.text(
        'Telp: $storePhone',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    // Meta Info
    bytes += generator.row([
      PosColumn(text: 'No: $invoiceNumber', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: dateString, width: 5, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Kasir: $cashierName', width: 6),
      PosColumn(text: 'Pelanggan: ${customerName ?? "Umum"}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    // Items List
    for (var item in items) {
      final name = item['name'] ?? item['product_name'] ?? 'Item';
      final qty = (item['quantity'] ?? item['qty'] ?? 1).toDouble();
      final price = (item['unit_price'] ?? item['price'] ?? 0).toDouble();
      final itemTotal = (item['subtotal'] ?? (qty * price)).toDouble();

      bytes += generator.text(
        name,
        styles: const PosStyles(bold: true),
      );
      bytes += generator.row([
        PosColumn(
          text: '  ${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)} x ${curFormat.format(price)}',
          width: 7,
        ),
        PosColumn(
          text: curFormat.format(itemTotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    // Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(text: curFormat.format(subtotal), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Diskon', width: 6),
        PosColumn(text: '- ${curFormat.format(discount)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (tax > 0) {
      bytes += generator.row([
        PosColumn(text: 'Pajak (PPN)', width: 6),
        PosColumn(text: '+ ${curFormat.format(tax)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'TOTAL AKHIR', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size1)),
      PosColumn(
        text: curFormat.format(grandTotal),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size1),
      ),
    ]);

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.row([
      PosColumn(text: 'Metode Bayar', width: 6),
      PosColumn(text: paymentMethod.toUpperCase(), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    if (paymentMethod.toLowerCase() == 'cash' || paymentMethod.toLowerCase() == 'tunai') {
      bytes += generator.row([
        PosColumn(text: 'Uang Diterima', width: 6),
        PosColumn(text: curFormat.format(cashGiven), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Kembalian', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: curFormat.format(changeAmount), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }

    bytes += generator.text(
      '================================',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      _footerNote,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Barang yang sudah dibeli tidak dapat ditukar',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Print Raw Bytes to Connected Bluetooth Thermal Printer
  Future<bool> printBytes(List<int> bytes) async {
    try {
      bool connected = await isConnected();
      if (!connected && _savedMac != null) {
        connected = await connect(_savedMac!, _savedName ?? 'Printer');
      }

      if (!connected) {
        return false;
      }

      for (int i = 0; i < _copies; i++) {
        final result = await PrintBluetoothThermal.writeBytes(bytes);
        if (!result) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
