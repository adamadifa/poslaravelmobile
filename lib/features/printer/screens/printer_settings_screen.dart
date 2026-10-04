import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/features/printer/providers/printer_provider.dart';
import 'package:poslaravelmobile/features/settings/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final printer = context.read<PrinterProvider>();
    _footerController = TextEditingController(text: printer.footerNote);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().scanDevices();
    });
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final printer = context.watch<PrinterProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final storeName = settingsProv.profile?.companyName.isNotEmpty == true ? settingsProv.profile!.companyName : 'WARUNG PRO POS';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Printer Bluetooth Thermal',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              'Konfigurasi cetak struk kasir 58mm & 80mm',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pindai Perangkat',
            icon: printer.isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 20),
            onPressed: printer.isScanning ? null : () => printer.scanDevices(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. Connection Status Banner
          _buildConnectionBanner(context, printer),
          const SizedBox(height: 20),

          // 2. Available / Paired Devices Card
          _buildDeviceListCard(context, printer),
          const SizedBox(height: 20),

          // 3. Printer Options & Configuration Card
          _buildConfigurationCard(printer),
          const SizedBox(height: 24),

          // 4. Test Print Button
          _buildTestPrintButton(context, printer, storeName),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(BuildContext context, PrinterProvider printer) {
    final isConnected = printer.isConnected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConnected ? LucideIcons.printer : LucideIcons.bluetooth,
                  color: isConnected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isConnected ? 'TERHUBUNG' : 'BELUM TERHUBUNG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isConnected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? (printer.connectedName ?? 'Printer Bluetooth')
                          : 'Pilih printer thermal dari daftar di bawah',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (printer.connectedMac != null)
                      Text(
                        'MAC: ${printer.connectedMac}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
              if (isConnected)
                TextButton(
                  onPressed: () async {
                    await printer.disconnect();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Koneksi printer diputuskan.')),
                      );
                    }
                  },
                  child: const Text(
                    'Putus',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (printer.statusMessage.isNotEmpty && !isConnected) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      printer.statusMessage,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceListCard(BuildContext context, PrinterProvider printer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Perangkat Bluetooth Terpasang (Paired)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                if (!printer.isScanning)
                  InkWell(
                    onTap: () => printer.scanDevices(),
                    child: const Text(
                      'Pindai Ulang',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (printer.isScanning)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Sedang memindai printer Bluetooth...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else if (printer.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(LucideIcons.bluetoothOff, size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    const Text(
                      'Tidak ada perangkat Bluetooth ditemukan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pastikan printer thermal menyala dan sudah di-pairing di menu Bluetooth Pengaturan HP Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(LucideIcons.refreshCw, size: 14),
                      label: const Text('Coba Pindai Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: () => printer.scanDevices(),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: printer.devices.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final device = printer.devices[index];
                final isCurrentConnected = printer.isConnected && (printer.connectedMac == device.macAdress);
                final isThisConnecting = printer.isConnecting && (printer.connectedMac == device.macAdress);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCurrentConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrentConnected ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.printer,
                      size: 18,
                      color: isCurrentConnected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                  ),
                  title: Text(
                    device.name.isNotEmpty ? device.name : 'Unknown Bluetooth Device',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrentConnected ? FontWeight.w800 : FontWeight.w700,
                      color: isCurrentConnected ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    device.macAdress,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  trailing: isThisConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : isCurrentConnected
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            )
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              onPressed: printer.isConnecting
                                  ? null
                                  : () async {
                                      final success = await printer.connect(device.macAdress, device.name);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? 'Berhasil terhubung ke ${device.name}'
                                                  : 'Gagal menghubungkan. Pastikan printer dalam jangkauan dan menyala.',
                                            ),
                                            backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                          ),
                                        );
                                      }
                                    },
                              child: const Text(
                                'Hubungkan',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard(PrinterProvider printer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfigurasi & Pengaturan Struk',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),

          // Paper Size Selector (58mm vs 80mm)
          const Text(
            'Ukuran Kertas Thermal',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => printer.updateConfig(paperSize: '58'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: printer.paperSize == '58' ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: printer.paperSize == '58' ? AppColors.primary : const Color(0xFFE2E8F0),
                        width: printer.paperSize == '58' ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '58 mm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: printer.paperSize == '58' ? AppColors.primary : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Standar Mobile Mini (32 Kolom)',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => printer.updateConfig(paperSize: '80'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: printer.paperSize == '80' ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: printer.paperSize == '80' ? AppColors.primary : const Color(0xFFE2E8F0),
                        width: printer.paperSize == '80' ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '80 mm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: printer.paperSize == '80' ? AppColors.primary : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Lebar / Desktop (48 Kolom)',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Auto Print on Checkout
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Otomatis Cetak Struk Saat Checkout', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            subtitle: const Text('Langsung kirim ke printer setelah transaksi sukses', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            value: printer.autoPrint,
            activeTrackColor: AppColors.primary,
            onChanged: (val) => printer.updateConfig(autoPrint: val),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Copies
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jumlah Rangkap Struk', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  Text('Rangkap untuk kasir / pelanggan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.minusCircle, size: 20, color: AppColors.primary),
                    onPressed: printer.copies > 1 ? () => printer.updateConfig(copies: printer.copies - 1) : null,
                  ),
                  Text('${printer.copies}x', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(LucideIcons.plusCircle, size: 20, color: AppColors.primary),
                    onPressed: printer.copies < 3 ? () => printer.updateConfig(copies: printer.copies + 1) : null,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Footer Note
          const Text('Catatan Kaki Struk (Footer)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _footerController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Contoh: Terima Kasih Atas Kunjungan Anda!',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            onChanged: (val) => printer.updateConfig(footerNote: val),
          ),
        ],
      ),
    );
  }

  Widget _buildTestPrintButton(BuildContext context, PrinterProvider printer, String storeName) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: const Icon(LucideIcons.printer, size: 18),
        label: const Text(
          'Uji Coba Cetak Struk (Test Print)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        onPressed: () async {
          final success = await printer.testPrint(storeName: storeName);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Perintah uji coba cetak berhasil dikirim ke printer thermal!'
                      : 'Gagal mencetak struk uji coba. Pastikan printer Bluetooth terhubung.',
                ),
                backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
            );
          }
        },
      ),
    );
  }
}
