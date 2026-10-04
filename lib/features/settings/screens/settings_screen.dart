import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/widgets/app_sidebar_drawer.dart';
import 'package:poslaravelmobile/data/models/store_settings_model.dart';
import 'package:poslaravelmobile/features/auth/providers/auth_provider.dart';
import 'package:poslaravelmobile/features/auth/screens/login_screen.dart';
import 'package:poslaravelmobile/features/printer/providers/printer_provider.dart';
import 'package:poslaravelmobile/features/printer/screens/printer_settings_screen.dart';
import 'package:poslaravelmobile/features/settings/providers/settings_provider.dart';
import 'package:poslaravelmobile/features/shift/providers/shift_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = const [
    {'title': 'Profil Toko', 'icon': LucideIcons.store},
    {'title': 'Jenis Usaha', 'icon': LucideIcons.layers},
    {'title': 'Format Prefix', 'icon': LucideIcons.hash},
    {'title': 'Pajak & Valuta', 'icon': LucideIcons.percent},
    {'title': 'Template Struk', 'icon': LucideIcons.receipt},
    {'title': 'Admin Fee Agen', 'icon': LucideIcons.landmark},
    {'title': 'Sistem & Kasir', 'icon': LucideIcons.cpu},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan Sistem',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Profil usaha, format dokumen, aturan pajak & struk',
              style: TextStyle(fontSize: 10.5, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Segarkan Pengaturan',
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
            onPressed: () => settingsProv.fetchSettings(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              tabs: _tabs.map((tab) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab['icon'] as IconData, size: 15),
                      const SizedBox(width: 6),
                      Text(tab['title'] as String),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: settingsProv.isLoading && settingsProv.settings == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  SizedBox(height: 12),
                  Text('Memuat konfigurasi toko...', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _ProfileSettingsTab(settings: settingsProv.profile),
                _BusinessTypeSettingsTab(settings: settingsProv.businessType),
                _PrefixesSettingsTab(settings: settingsProv.prefixes),
                _TaxCurrencySettingsTab(settings: settingsProv.taxCurrency),
                _ReceiptSettingsTab(settings: settingsProv.receipt),
                _AgentSettingsTab(settings: settingsProv.agent),
                const _SystemAppTab(),
              ],
            ),
    );
  }
}

// =========================================================================
// TAB 1: PROFIL TOKO & USAHA
// =========================================================================
class _ProfileSettingsTab extends StatefulWidget {
  final StoreProfileModel? settings;
  const _ProfileSettingsTab({this.settings});

  @override
  State<_ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<_ProfileSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _npwpCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _ProfileSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _initControllers();
    }
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: widget.settings?.companyName ?? 'WarungPro');
    _taglineCtrl = TextEditingController(text: widget.settings?.companyTagline ?? '');
    _addressCtrl = TextEditingController(text: widget.settings?.companyAddress ?? '');
    _phoneCtrl = TextEditingController(text: widget.settings?.companyPhone ?? '');
    _emailCtrl = TextEditingController(text: widget.settings?.companyEmail ?? '');
    _npwpCtrl = TextEditingController(text: widget.settings?.companyNpwp ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _npwpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<SettingsProvider>();
    final ok = await prov.saveProfile({
      'company_name': _nameCtrl.text.trim(),
      'company_tagline': _taglineCtrl.text.trim(),
      'company_address': _addressCtrl.text.trim(),
      'company_phone': _phoneCtrl.text.trim(),
      'company_email': _emailCtrl.text.trim(),
      'company_npwp': _npwpCtrl.text.trim(),
    });

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil toko berhasil diperbarui!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.errorMessage ?? 'Gagal menyimpan profil toko.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Avatar / Logo Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: widget.settings?.companyLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              widget.settings!.companyLogoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(LucideIcons.store, color: AppColors.primary, size: 28),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(LucideIcons.store, color: AppColors.primary, size: 28),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.settings?.companyName ?? 'WarungPro POS',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.settings?.companyTagline.isNotEmpty == true
                              ? widget.settings!.companyTagline
                              : 'Sistem Kasir & Manajemen Bisnis',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Identitas Toko & Kontak', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 14),

                  _buildFormField('Nama Toko / Perusahaan *', _nameCtrl, LucideIcons.store, isRequired: true),
                  const SizedBox(height: 12),
                  _buildFormField('Tagline / Slogan', _taglineCtrl, LucideIcons.sparkles, hint: 'Misal: Solusi Kasir Ritel Modern'),
                  const SizedBox(height: 12),
                  _buildFormField('Alamat Lengkap Toko', _addressCtrl, LucideIcons.mapPin, maxLines: 2),
                  const SizedBox(height: 12),
                  _buildFormField('No. Telepon / WhatsApp', _phoneCtrl, LucideIcons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildFormField('Email Kontak', _emailCtrl, LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildFormField('NPWP Perusahaan', _npwpCtrl, LucideIcons.fileText),
                  const SizedBox(height: 22),

                  _buildSaveButton(
                    label: 'Simpan Profil Toko',
                    isSaving: prov.isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 2: JENIS USAHA & MODE OPERASIONAL
// =========================================================================
class _BusinessTypeSettingsTab extends StatefulWidget {
  final BusinessTypeSettingsModel? settings;
  const _BusinessTypeSettingsTab({this.settings});

  @override
  State<_BusinessTypeSettingsTab> createState() => _BusinessTypeSettingsTabState();
}

class _BusinessTypeSettingsTabState extends State<_BusinessTypeSettingsTab> {
  late String _businessType;
  late bool _posAllowManualPriceEdit;

  // FNB
  late bool _fnbTableManagement;
  late bool _fnbKitchenDisplay;
  late bool _fnbModifiers;
  late bool _fnbReservation;
  late String _fnbDefaultServiceType;
  late TextEditingController _fnbServiceChargeCtrl;
  late bool _fnbAutoPrintKitchen;
  late bool _fnbQueueNumber;

  // Service
  late bool _serviceBooking;
  late bool _serviceTechnician;
  late bool _serviceDuration;
  late int _serviceSlotMinutes;
  late bool _serviceAutoQueue;
  late bool _serviceMaterialUsage;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  @override
  void didUpdateWidget(covariant _BusinessTypeSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _initFields();
    }
  }

  void _initFields() {
    final s = widget.settings;
    _businessType = s?.businessType ?? 'retail';
    _posAllowManualPriceEdit = s?.posAllowManualPriceEdit ?? true;

    _fnbTableManagement = s?.fnbEnableTableManagement ?? true;
    _fnbKitchenDisplay = s?.fnbEnableKitchenDisplay ?? true;
    _fnbModifiers = s?.fnbEnableModifiers ?? true;
    _fnbReservation = s?.fnbEnableReservation ?? true;
    _fnbDefaultServiceType = s?.fnbDefaultServiceType ?? 'dine_in';
    _fnbServiceChargeCtrl = TextEditingController(text: (s?.fnbServiceChargePercent ?? 0).toString());
    _fnbAutoPrintKitchen = s?.fnbAutoPrintKitchenTicket ?? false;
    _fnbQueueNumber = s?.fnbEnableQueueNumber ?? true;

    _serviceBooking = s?.serviceEnableBooking ?? true;
    _serviceTechnician = s?.serviceEnableTechnicianAssignment ?? true;
    _serviceDuration = s?.serviceEnableDurationTracking ?? true;
    _serviceSlotMinutes = s?.serviceBookingSlotMinutes ?? 30;
    _serviceAutoQueue = s?.serviceAutoQueue ?? true;
    _serviceMaterialUsage = s?.serviceEnableMaterialUsage ?? false;
  }

  @override
  void dispose() {
    _fnbServiceChargeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prov = context.read<SettingsProvider>();
    final ok = await prov.saveBusinessType({
      'business_type': _businessType,
      'pos_allow_manual_price_edit': _posAllowManualPriceEdit,
      'fnb_enable_table_management': _fnbTableManagement,
      'fnb_enable_kitchen_display': _fnbKitchenDisplay,
      'fnb_enable_modifiers': _fnbModifiers,
      'fnb_enable_reservation': _fnbReservation,
      'fnb_default_service_type': _fnbDefaultServiceType,
      'fnb_service_charge_percent': double.tryParse(_fnbServiceChargeCtrl.text.trim()) ?? 0.0,
      'fnb_auto_print_kitchen_ticket': _fnbAutoPrintKitchen,
      'fnb_enable_queue_number': _fnbQueueNumber,
      'service_enable_booking': _serviceBooking,
      'service_enable_technician_assignment': _serviceTechnician,
      'service_enable_duration_tracking': _serviceDuration,
      'service_booking_slot_minutes': _serviceSlotMinutes,
      'service_auto_queue': _serviceAutoQueue,
      'service_enable_material_usage': _serviceMaterialUsage,
    });

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfigurasi jenis usaha berhasil diperbarui!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.errorMessage ?? 'Gagal menyimpan konfigurasi jenis usaha.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Type Selector Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Model Operasional Usaha', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                const Text('Pilih alur kerja POS yang sesuai dengan kategori bisnis Anda', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                const SizedBox(height: 14),

                _buildRadioCard('retail', 'Toko Ritel & Grosir', 'Barcode scanner, stok fisik, varian produk, harga bertingkat', LucideIcons.shoppingCart, const Color(0xFF2563EB)),
                const SizedBox(height: 8),
                _buildRadioCard('fnb', 'Resto, Kafe & F&B', 'Dine-in/takeaway, denah meja, pesanan dapur (KDS), topping modifier', LucideIcons.utensils, const Color(0xFFEA580C)),
                const SizedBox(height: 8),
                _buildRadioCard('service', 'Jasa, Salon & Bengkel', 'Booking appointment, penugasan teknisi/terapis, antrian pengerjaan', LucideIcons.scissors, const Color(0xFF059669)),
                const SizedBox(height: 8),
                _buildRadioCard('hybrid', 'Usaha Campuran (Hybrid)', 'Aktifkan seluruh modul ritel, restoran meja, dan layanan jasa sekaligus', LucideIcons.layers, const Color(0xFF7C3AED)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // POS Security
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Keamanan Kasir POS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                _buildSwitchTile(
                  title: 'Izinkan Ubah Harga Manual di POS',
                  subtitle: 'Kasir dapat mengedit harga jual barang saat transaksi',
                  value: _posAllowManualPriceEdit,
                  onChanged: (v) => setState(() => _posAllowManualPriceEdit = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // FNB Features (if fnb or hybrid)
          if (_businessType == 'fnb' || _businessType == 'hybrid') ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(LucideIcons.utensils, color: Color(0xFFEA580C), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('Fitur Resto & Kuliner (F&B)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    title: 'Manajemen Denah & Meja',
                    subtitle: 'Atur meja makan, status terisi/kosong, dan pindah meja',
                    value: _fnbTableManagement,
                    onChanged: (v) => setState(() => _fnbTableManagement = v),
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSwitchTile(
                    title: 'Kitchen Display System (KDS)',
                    subtitle: 'Kirim pesanan langsung ke layar antrian dapur',
                    value: _fnbKitchenDisplay,
                    onChanged: (v) => setState(() => _fnbKitchenDisplay = v),
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSwitchTile(
                    title: 'Menu Modifiers & Topping',
                    subtitle: 'Pilihan level pedas, es batu, saus, dan extra topping',
                    value: _fnbModifiers,
                    onChanged: (v) => setState(() => _fnbModifiers = v),
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSwitchTile(
                    title: 'Reservasi Meja',
                    subtitle: 'Fitur pemesanan meja lebih awal oleh pelanggan',
                    value: _fnbReservation,
                    onChanged: (v) => setState(() => _fnbReservation = v),
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSwitchTile(
                    title: 'Nomor Antrian Take Away',
                    subtitle: 'Cetak nomor antrian khusus pesanan bawa pulang',
                    value: _fnbQueueNumber,
                    onChanged: (v) => setState(() => _fnbQueueNumber = v),
                  ),
                  const SizedBox(height: 14),

                  _buildFormField('Biaya Service Charge F&B (%)', _fnbServiceChargeCtrl, LucideIcons.percent, keyboardType: TextInputType.number),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Service Features (if service or hybrid)
          if (_businessType == 'service' || _businessType == 'hybrid') ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(LucideIcons.scissors, color: Color(0xFF059669), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('Fitur Layanan Jasa & Perawatan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    title: 'Booking & Janji Temu',
                    subtitle: 'Kalender jadwal reservasi layanan pelanggan',
                    value: _serviceBooking,
                    onChanged: (v) => setState(() => _serviceBooking = v),
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSwitchTile(
                    title: 'Penugasan Staf / Teknisi',
                    subtitle: 'Pilih teknisi/terapis yang melayani + kalkulasi komisi',
                    value: _serviceTechnician,
                    onChanged: (v) => setState(() => _serviceTechnician = v),
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSwitchTile(
                    title: 'Monitor Antrian Layanan',
                    subtitle: 'Pantau status Menunggu, Dikerjakan, dan Selesai',
                    value: _serviceAutoQueue,
                    onChanged: (v) => setState(() => _serviceAutoQueue = v),
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSwitchTile(
                    title: 'Tracking Penggunaan Bahan/Sparepart',
                    subtitle: 'Potong stok bahan baku saat jasa dikerjakan',
                    value: _serviceMaterialUsage,
                    onChanged: (v) => setState(() => _serviceMaterialUsage = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildSaveButton(
            label: 'Simpan Jenis Usaha',
            isSaving: prov.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioCard(String val, String title, String desc, IconData icon, Color color) {
    final isSelected = _businessType == val;
    return InkWell(
      onTap: () => setState(() => _businessType = val),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: isSelected ? color : const Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 3: FORMAT NOMOR TRANSAKSI (PREFIXES)
// =========================================================================
class _PrefixesSettingsTab extends StatefulWidget {
  final PrefixesSettingsModel? settings;
  const _PrefixesSettingsTab({this.settings});

  @override
  State<_PrefixesSettingsTab> createState() => _PrefixesSettingsTabState();
}

class _PrefixesSettingsTabState extends State<_PrefixesSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _invoiceCtrl;
  late TextEditingController _poCtrl;
  late TextEditingController _grnCtrl;
  late TextEditingController _srCtrl;
  late TextEditingController _prCtrl;
  late TextEditingController _soCtrl;
  late TextEditingController _tfCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _PrefixesSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _initControllers();
    }
  }

  void _initControllers() {
    _invoiceCtrl = TextEditingController(text: widget.settings?.prefixInvoice ?? 'INV');
    _poCtrl = TextEditingController(text: widget.settings?.prefixPo ?? 'PO');
    _grnCtrl = TextEditingController(text: widget.settings?.prefixGrn ?? 'GRN');
    _srCtrl = TextEditingController(text: widget.settings?.prefixReturnSale ?? 'SR');
    _prCtrl = TextEditingController(text: widget.settings?.prefixReturnPurchase ?? 'PR');
    _soCtrl = TextEditingController(text: widget.settings?.prefixOpname ?? 'SO');
    _tfCtrl = TextEditingController(text: widget.settings?.prefixTransfer ?? 'TF');
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _poCtrl.dispose();
    _grnCtrl.dispose();
    _srCtrl.dispose();
    _prCtrl.dispose();
    _soCtrl.dispose();
    _tfCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<SettingsProvider>();
    final ok = await prov.savePrefixes({
      'prefix_invoice': _invoiceCtrl.text.trim().toUpperCase(),
      'prefix_po': _poCtrl.text.trim().toUpperCase(),
      'prefix_grn': _grnCtrl.text.trim().toUpperCase(),
      'prefix_return_sale': _srCtrl.text.trim().toUpperCase(),
      'prefix_return_purchase': _prCtrl.text.trim().toUpperCase(),
      'prefix_opname': _soCtrl.text.trim().toUpperCase(),
      'prefix_transfer': _tfCtrl.text.trim().toUpperCase(),
    });

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format nomor transaksi berhasil diperbarui!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.errorMessage ?? 'Gagal menyimpan format nomor.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Awalan (Prefix) Dokumen Transaksi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  const Text('Kode unik awalan untuk penomoran otomatis di database', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 16),

                  _buildFormField('Prefix Faktur Penjualan (Sales) *', _invoiceCtrl, LucideIcons.receipt, isRequired: true, hint: 'INV'),
                  const SizedBox(height: 12),
                  _buildFormField('Prefix Purchase Order (PO) *', _poCtrl, LucideIcons.clipboardList, isRequired: true, hint: 'PO'),
                  const SizedBox(height: 12),
                  _buildFormField('Prefix Good Receipt Note (GRN) *', _grnCtrl, LucideIcons.packageCheck, isRequired: true, hint: 'GRN'),
                  const SizedBox(height: 12),
                  _buildFormField('Prefix Retur Penjualan (Sale Return) *', _srCtrl, LucideIcons.rotateCcw, isRequired: true, hint: 'SR'),
                  const SizedBox(height: 12),
                  _buildFormField('Prefix Retur Pembelian (Purchase Return) *', _prCtrl, LucideIcons.rotateCcw, isRequired: true, hint: 'PR'),
                  const SizedBox(height: 12),
                  _buildFormField('Prefix Stok Opname (SO) *', _soCtrl, LucideIcons.clipboardCheck, isRequired: true, hint: 'SO'),
                  const SizedBox(height: 12),
                  _buildFormField('Prefix Transfer Antar Gudang (TF) *', _tfCtrl, LucideIcons.arrowLeftRight, isRequired: true, hint: 'TF'),
                  const SizedBox(height: 22),

                  _buildSaveButton(
                    label: 'Simpan Format Prefix',
                    isSaving: prov.isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 4: PAJAK & MATA UANG (VALUTA)
// =========================================================================
class _TaxCurrencySettingsTab extends StatefulWidget {
  final TaxCurrencySettingsModel? settings;
  const _TaxCurrencySettingsTab({this.settings});

  @override
  State<_TaxCurrencySettingsTab> createState() => _TaxCurrencySettingsTabState();
}

class _TaxCurrencySettingsTabState extends State<_TaxCurrencySettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _taxCtrl;
  late TextEditingController _symbolCtrl;
  late TextEditingController _codeCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _TaxCurrencySettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _initControllers();
    }
  }

  void _initControllers() {
    _taxCtrl = TextEditingController(text: (widget.settings?.defaultTaxRate ?? 11).toString());
    _symbolCtrl = TextEditingController(text: widget.settings?.currencySymbol ?? 'Rp');
    _codeCtrl = TextEditingController(text: widget.settings?.currencyCode ?? 'IDR');
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    _symbolCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<SettingsProvider>();
    final ok = await prov.saveTaxCurrency({
      'default_tax_rate': double.tryParse(_taxCtrl.text.trim()) ?? 11.0,
      'currency_symbol': _symbolCtrl.text.trim(),
      'currency_code': _codeCtrl.text.trim().toUpperCase(),
    });

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan pajak & mata uang berhasil diperbarui!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.errorMessage ?? 'Gagal menyimpan pengaturan pajak.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Konfigurasi Pajak & Valuta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 16),

                  _buildFormField('Tarif Pajak Standar PPN (%) *', _taxCtrl, LucideIcons.percent, isRequired: true, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildFormField('Simbol Mata Uang *', _symbolCtrl, LucideIcons.badgeDollarSign, isRequired: true, hint: 'Rp'),
                  const SizedBox(height: 12),
                  _buildFormField('Kode Mata Uang ISO *', _codeCtrl, LucideIcons.globe, isRequired: true, hint: 'IDR'),
                  const SizedBox(height: 22),

                  _buildSaveButton(
                    label: 'Simpan Pengaturan Pajak',
                    isSaving: prov.isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 5: TEMPLATE STRUK KASIR
// =========================================================================
class _ReceiptSettingsTab extends StatefulWidget {
  final ReceiptTemplateSettingsModel? settings;
  const _ReceiptSettingsTab({this.settings});

  @override
  State<_ReceiptSettingsTab> createState() => _ReceiptSettingsTabState();
}

class _ReceiptSettingsTabState extends State<_ReceiptSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _headerCtrl;
  late TextEditingController _footerCtrl;
  late String _paperSize;
  late bool _showLogo;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _ReceiptSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _initControllers();
    }
  }

  void _initControllers() {
    _headerCtrl = TextEditingController(text: widget.settings?.receiptHeader ?? '');
    _footerCtrl = TextEditingController(text: widget.settings?.receiptFooter ?? '');
    _paperSize = widget.settings?.receiptPaperSize ?? '58mm';
    _showLogo = widget.settings?.receiptShowLogo ?? true;
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prov = context.read<SettingsProvider>();
    final ok = await prov.saveReceipt({
      'receipt_header': _headerCtrl.text.trim(),
      'receipt_footer': _footerCtrl.text.trim(),
      'receipt_paper_size': _paperSize,
      'receipt_show_logo': _showLogo,
    });

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template struk kasir berhasil diperbarui!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.errorMessage ?? 'Gagal menyimpan template struk.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Format Cetak Struk Thermal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 16),

                  // Paper Size Picker
                  const Text('Ukuran Kertas Printer Thermal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _paperSize = '58mm'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _paperSize == '58mm' ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _paperSize == '58mm' ? AppColors.primary : const Color(0xFFCBD5E1),
                                width: _paperSize == '58mm' ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '58mm (Mini Portable)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _paperSize == '58mm' ? FontWeight.w800 : FontWeight.w600,
                                color: _paperSize == '58mm' ? AppColors.primary : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _paperSize = '80mm'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _paperSize == '80mm' ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _paperSize == '80mm' ? AppColors.primary : const Color(0xFFCBD5E1),
                                width: _paperSize == '80mm' ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '80mm (Desktop Standar)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _paperSize == '80mm' ? FontWeight.w800 : FontWeight.w600,
                                color: _paperSize == '80mm' ? AppColors.primary : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSwitchTile(
                    title: 'Tampilkan Logo di Struk',
                    subtitle: 'Cetak gambar logo usaha di bagian atas nota',
                    value: _showLogo,
                    onChanged: (v) => setState(() => _showLogo = v),
                  ),
                  const SizedBox(height: 16),

                  _buildFormField('Pesan Header Struk', _headerCtrl, LucideIcons.alignLeft, maxLines: 2, hint: 'Pesan selamat datang...'),
                  const SizedBox(height: 12),
                  _buildFormField('Pesan Footer Struk', _footerCtrl, LucideIcons.alignLeft, maxLines: 3, hint: 'Ucapan terima kasih / akun sosmed...'),
                  const SizedBox(height: 22),

                  _buildSaveButton(
                    label: 'Simpan Template Struk',
                    isSaving: prov.isSaving,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    icon: const Icon(LucideIcons.printer, size: 16),
                    label: const Text('Buka Pengaturan & Test Printer Bluetooth', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 6: BIAYA ADMIN AGEN & PPOB
// =========================================================================
class _AgentSettingsTab extends StatefulWidget {
  final AgentSettingsModel? settings;
  const _AgentSettingsTab({this.settings});

  @override
  State<_AgentSettingsTab> createState() => _AgentSettingsTabState();
}

class _AgentSettingsTabState extends State<_AgentSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _transferCtrl;
  late TextEditingController _withdrawCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _AgentSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _initControllers();
    }
  }

  void _initControllers() {
    _transferCtrl = TextEditingController(text: (widget.settings?.agentTransferAdminFee ?? 5000).toInt().toString());
    _withdrawCtrl = TextEditingController(text: (widget.settings?.agentWithdrawAdminFee ?? 5000).toInt().toString());
  }

  @override
  void dispose() {
    _transferCtrl.dispose();
    _withdrawCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<SettingsProvider>();
    final ok = await prov.saveAgent({
      'agent_transfer_admin_fee': double.tryParse(_transferCtrl.text.trim()) ?? 5000.0,
      'agent_withdraw_admin_fee': double.tryParse(_withdrawCtrl.text.trim()) ?? 5000.0,
      'transfer_tiers': widget.settings?.transferTiers.map((e) => e.toJson()).toList() ?? [],
      'withdraw_tiers': widget.settings?.withdrawTiers.map((e) => e.toJson()).toList() ?? [],
    });

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biaya admin agen berhasil disimpan!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.errorMessage ?? 'Gagal menyimpan biaya admin agen.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Biaya Admin Agen & Perbankan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  const Text('Standar biaya jasa transfer uang dan tarik tunai di kasir POS', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 16),

                  _buildFormField('Biaya Admin Transfer Bank (Rp) *', _transferCtrl, LucideIcons.send, isRequired: true, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildFormField('Biaya Admin Tarik Tunai (Rp) *', _withdrawCtrl, LucideIcons.wallet, isRequired: true, keyboardType: TextInputType.number),
                  const SizedBox(height: 22),

                  _buildSaveButton(
                    label: 'Simpan Biaya Admin',
                    isSaving: prov.isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 7: SISTEM, USER & LOGOUT
// =========================================================================
class _SystemAppTab extends StatelessWidget {
  const _SystemAppTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shift = context.watch<ShiftProvider>();
    final printer = context.watch<PrinterProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.user, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.name ?? 'Pengguna',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.user?.email ?? 'user@pospro.com',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          auth.user?.role.toUpperCase() ?? 'KASIR',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Shift Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sesi Shift Kasir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: shift.hasActiveShift ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shift.hasActiveShift ? 'AKTIF' : 'TUTUP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: shift.hasActiveShift ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                if (shift.hasActiveShift) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Modal Awal: ${CurrencyFormatter.format(shift.currentShift?.startingCash ?? 0)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Total Kas Keluar: ${CurrencyFormatter.format(shift.currentShift?.totalExpenses ?? 0)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Printer & Server URL Tile
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: printer.isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.printer,
                      color: printer.isConnected ? const Color(0xFF16A34A) : AppColors.primary,
                      size: 18,
                    ),
                  ),
                  title: const Text('Printer Bluetooth Thermal (58mm/80mm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    printer.isConnected
                        ? 'Terhubung: ${printer.connectedName ?? "Printer"} (${printer.paperSize}mm)'
                        : (printer.connectedMac != null ? 'Tersimpan: ${printer.connectedName} (Offline)' : 'Belum terhubung - Ketuk untuk setting'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: printer.isConnected ? FontWeight.w700 : FontWeight.w500,
                      color: printer.isConnected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (printer.isConnected)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Aktif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                        ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(LucideIcons.server, color: Color(0xFF2563EB)),
                  title: const Text('URL Backend API Server', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: Text(auth.serverUrl, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: const Text('Keluar dari Akun Kasir', style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// UNIFIED FORM & BUTTON HELPERS
// =========================================================================

Widget _buildFormField(
  String label,
  TextEditingController controller,
  IconData icon, {
  bool isRequired = false,
  String? hint,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
      ),
      const SizedBox(height: 5),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: isRequired
            ? (val) => val == null || val.trim().isEmpty ? 'Bagian ini wajib diisi' : null
            : null,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, size: 15, color: const Color(0xFF64748B)),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

Widget _buildSaveButton({
  required String label,
  required bool isSaving,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 44,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: isSaving
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(LucideIcons.save, size: 16, color: Colors.white),
      label: Text(
        isSaving ? 'Menyimpan...' : label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      onPressed: isSaving ? null : onPressed,
    ),
  );
}

Widget _buildSwitchTile({
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
      Switch.adaptive(
        value: value,
        activeTrackColor: AppColors.primary,
        onChanged: onChanged,
      ),
    ],
  );
}
