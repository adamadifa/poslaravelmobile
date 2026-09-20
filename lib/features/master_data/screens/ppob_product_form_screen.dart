import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';
import 'package:poslaravelmobile/data/models/ppob_product_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class PpobProductFormScreen extends StatefulWidget {
  final PpobProductModel? product;

  const PpobProductFormScreen({super.key, this.product});

  @override
  State<PpobProductFormScreen> createState() => _PpobProductFormScreenState();
}

class _PpobProductFormScreenState extends State<PpobProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _providerCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _descCtrl;

  String _selectedCategory = 'pulsa';
  int? _selectedAccountId;
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.product != null;

  final List<Map<String, String>> _categories = [
    {'key': 'pulsa', 'label': 'Pulsa Reguler'},
    {'key': 'paket_data', 'label': 'Paket Data / Kuota'},
    {'key': 'token_pln', 'label': 'Token Listrik PLN'},
    {'key': 'ewallet', 'label': 'Top Up E-Wallet'},
    {'key': 'tagihan', 'label': 'Tagihan Pascabayar (BPJS, PDAM, dll)'},
    {'key': 'other', 'label': 'Lainnya / Voucher Game'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _codeCtrl = TextEditingController(text: p?.code ?? '');
    _providerCtrl = TextEditingController(text: p?.provider ?? '');
    _costPriceCtrl = TextEditingController(text: p != null ? p.costPrice.toInt().toString() : '0');
    _sellingPriceCtrl = TextEditingController(text: p != null ? p.sellingPrice.toInt().toString() : '0');
    _descCtrl = TextEditingController(text: p?.description ?? '');

    if (p != null) {
      _selectedCategory = p.category;
      _selectedAccountId = p.defaultAccountId;
      _isActive = p.isActive;
    }

    _costPriceCtrl.addListener(() => setState(() {}));
    _sellingPriceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _providerCtrl.dispose();
    _costPriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  double get _currentMargin {
    final cost = double.tryParse(_costPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final sell = double.tryParse(_sellingPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    return sell - cost;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi data wajib dengan benar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'category': _selectedCategory,
        'provider': _providerCtrl.text.trim().isNotEmpty ? _providerCtrl.text.trim() : null,
        'code': _codeCtrl.text.trim().isNotEmpty ? _codeCtrl.text.trim() : null,
        'cost_price': double.tryParse(_costPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
        'selling_price': double.tryParse(_sellingPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
        'default_account_id': _selectedAccountId,
        'is_active': _isActive ? 1 : 0,
        'description': _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      };

      final provider = context.read<MasterDataProvider>();
      bool ok = false;

      if (isEdit) {
        ok = await provider.updatePpobProduct(widget.product!.id, payload);
      } else {
        ok = await provider.storePpobProduct(payload);
      }

      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Produk PPOB berhasil diperbarui.' : 'Produk PPOB baru berhasil disimpan.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final err = provider.errorMessage ?? 'Gagal menyimpan produk PPOB.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<MasterDataProvider>().accounts;
    final margin = _currentMargin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Produk PPOB' : 'Tambah Produk PPOB Baru',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            onPressed: _isSaving ? null : _saveProduct,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.check, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isEdit ? 'Simpan Perubahan' : 'Simpan Produk PPOB',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CARD 1: INFORMASI PRODUK
              _buildCardSection(
                title: 'Informasi Produk PPOB',
                icon: LucideIcons.smartphone,
                children: [
                  // Dropdown Kategori
                  _buildDropdownCategory(),
                  const SizedBox(height: 14),

                  // Provider / Operator
                  _buildOutsetInput(
                    label: 'Provider / Operator',
                    hint: 'Contoh: Telkomsel, Indosat, PLN, DANA, GoPay',
                    icon: LucideIcons.building,
                    controller: _providerCtrl,
                  ),
                  const SizedBox(height: 14),

                  // Nama Produk
                  _buildOutsetInput(
                    label: 'Nama Produk PPOB *',
                    hint: 'Contoh: Telkomsel 50.000 / Token PLN 100.000',
                    icon: LucideIcons.tag,
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama produk wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Kode Produk
                  _buildOutsetInput(
                    label: 'Kode Produk (Opsional)',
                    hint: 'Kosongkan untuk generate otomatis (PPOB-XXX-0000)',
                    icon: LucideIcons.hash,
                    controller: _codeCtrl,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 2: PENETAPAN HARGA & MARGIN
              _buildCardSection(
                title: 'Penetapan Harga & Margin Keuntungan',
                icon: LucideIcons.coins,
                children: [
                  // Harga Modal / HPP
                  _buildOutsetInput(
                    label: 'Harga Modal / HPP Server (Rp) *',
                    hint: 'Contoh: 50150',
                    icon: LucideIcons.dollarSign,
                    controller: _costPriceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.trim().isEmpty ? 'Harga modal wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Harga Jual Kasir
                  _buildOutsetInput(
                    label: 'Harga Jual ke Pelanggan / Kasir (Rp) *',
                    hint: 'Contoh: 52000',
                    icon: LucideIcons.receipt,
                    controller: _sellingPriceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.trim().isEmpty ? 'Harga jual kasir wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Live Margin Preview Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: margin >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: margin >= 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                margin >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                                size: 18,
                                color: margin >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      margin >= 0 ? 'Estimasi Margin Keuntungan' : 'Estimasi Kerugian (Jual < Modal)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: margin >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'Keuntungan bersih per 1x transaksi',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${margin >= 0 ? '+' : ''}${CurrencyFormatter.format(margin)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: margin >= 0 ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Akun Kas / Deposit
                  _buildDropdownAccount(accounts),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 3: STATUS & KETERANGAN
              _buildCardSection(
                title: 'Pengaturan Status & Keterangan',
                icon: LucideIcons.sliders,
                children: [
                  // Active Switch Tile
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status Produk Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Tersedia untuk transaksi kasir PPOB', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetTextArea(
                    label: 'Catatan / Keterangan',
                    hint: 'Informasi tambahan untuk produk PPOB ini (opsional)...',
                    icon: LucideIcons.fileText,
                    controller: _descCtrl,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownCategory() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
      decoration: InputDecoration(
        labelText: 'Kategori PPOB *',
        labelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(LucideIcons.layers, size: 16, color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: _categories.map((c) {
        return DropdownMenuItem<String>(
          value: c['key'],
          child: Text(
            c['label']!,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedCategory = val);
      },
    );
  }

  Widget _buildDropdownAccount(List<AccountModel> accounts) {
    return DropdownButtonFormField<int?>(
      initialValue: _selectedAccountId,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
      decoration: InputDecoration(
        labelText: 'Akun Kas / Saldo Deposit Terkait',
        labelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(LucideIcons.wallet, size: 16, color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text(
            'Pilih Akun Kas / Deposit (Opsional)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...accounts.map((acc) {
          return DropdownMenuItem<int?>(
            value: acc.id,
            child: Text(
              '${acc.name} (${acc.typeLabel})',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (val) => setState(() => _selectedAccountId = val),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOutsetInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildOutsetTextArea({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
