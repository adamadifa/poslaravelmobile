import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class RawMaterialFormScreen extends StatefulWidget {
  final ProductModel? rawMaterial;

  const RawMaterialFormScreen({super.key, this.rawMaterial});

  @override
  State<RawMaterialFormScreen> createState() => _RawMaterialFormScreenState();
}

class _RawMaterialFormScreenState extends State<RawMaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _purchasePriceCtrl = TextEditingController();
  final TextEditingController _minStockCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedBaseUnitId;
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.rawMaterial != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MasterDataProvider>();
      provider.fetchCategories();
      provider.fetchUnits();
    });

    _initForm();
  }

  void _initForm() {
    if (widget.rawMaterial != null) {
      final p = widget.rawMaterial!;
      _nameCtrl.text = p.name;
      _codeCtrl.text = p.code ?? '';
      _selectedCategoryId = p.categoryId;
      _selectedBaseUnitId = p.baseUnitId;
      _purchasePriceCtrl.text = _formatNumber(p.costPrice > 0 ? p.costPrice : p.sellingPrice);
      _descriptionCtrl.text = p.defaultNotes.isNotEmpty ? p.defaultNotes.join(', ') : '';
    }
  }

  String _formatNumber(double value) {
    if (value == 0) return '0';
    if (value % 1 == 0) {
      return NumberFormat('#,###', 'id_ID').format(value.toInt());
    }
    return NumberFormat('#,###.##', 'id_ID').format(value);
  }

  double _parseNumber(String text) {
    final clean = text.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _brandCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _minStockCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveRawMaterial() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi formulir dengan benar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedBaseUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satuan dasar takaran wajib dipilih!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'product_type': 'raw_material',
        if (_codeCtrl.text.trim().isNotEmpty) 'code': _codeCtrl.text.trim(),
        'base_unit_id': _selectedBaseUnitId,
        'purchase_price': _parseNumber(_purchasePriceCtrl.text),
        'cost_price': _parseNumber(_purchasePriceCtrl.text),
        'selling_price': 0,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
        if (_minStockCtrl.text.trim().isNotEmpty) 'min_stock': _parseNumber(_minStockCtrl.text),
        if (_descriptionCtrl.text.trim().isNotEmpty) 'description': _descriptionCtrl.text.trim(),
        'is_active': _isActive,
      };

      final provider = context.read<MasterDataProvider>();
      ProductModel? result;

      if (isEdit) {
        result = await provider.updateProduct(widget.rawMaterial!.id, payload);
      } else {
        result = await provider.createProduct(payload);
      }

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Bahan baku berhasil diperbarui.' : 'Bahan baku baru berhasil disimpan.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final err = provider.errorMessage ?? 'Gagal menyimpan data bahan baku.';
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
    final provider = context.watch<MasterDataProvider>();
    final units = provider.units;
    final categories = provider.categories;

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
          isEdit ? 'Edit Bahan Baku' : 'Tambah Bahan Baku',
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
            onPressed: _isSaving ? null : _saveRawMaterial,
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
                        isEdit ? 'Simpan Perubahan' : 'Simpan Bahan Baku',
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
              // CARD 1: INFORMASI UTAMA BAHAN BAKU
              _buildCardSection(
                title: 'Informasi Utama Bahan Baku',
                icon: LucideIcons.box,
                children: [
                  _buildOutsetInput(
                    label: 'Nama Bahan Baku *',
                    hint: 'Contoh: Biji Kopi Espresso Blend / Fresh Milk',
                    icon: LucideIcons.box,
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama bahan baku wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildOutsetInput(
                          label: 'Kode SKU (Opsional)',
                          hint: 'Auto: RAW-00001',
                          icon: LucideIcons.hash,
                          controller: _codeCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOutsetInput(
                          label: 'Merk / Brand',
                          hint: 'Greenfields / Monin',
                          icon: LucideIcons.bookmark,
                          controller: _brandCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Kategori Dropdown (Full Width)
                  _buildOutsetDropdown<int>(
                    label: 'Kategori Bahan',
                    icon: LucideIcons.tag,
                    value: _selectedCategoryId,
                    items: [
                      ...categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(
                            c.name,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    hint: 'Kategori',
                  ),
                  const SizedBox(height: 14),

                  // Satuan Dasar Dropdown (Full Width)
                  _buildOutsetDropdown<int>(
                    label: 'Satuan Takaran *',
                    icon: LucideIcons.scale,
                    value: _selectedBaseUnitId,
                    items: units.map((u) {
                      return DropdownMenuItem<int>(
                        value: u.id,
                        child: Text(
                          '${u.name} (${u.shortName})',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBaseUnitId = val),
                    hint: 'Satuan',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 2: BIAYA HPP & STOK ALERT
              _buildCardSection(
                title: 'Harga Modal & Stok Minimum',
                icon: LucideIcons.coins,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildOutsetInput(
                          label: 'Harga Beli (HPP per Satuan) *',
                          hint: 'Contoh: 280',
                          icon: LucideIcons.dollarSign,
                          controller: _purchasePriceCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ThousandSeparatorInputFormatter(),
                          ],
                          prefixText: 'Rp ',
                          validator: (v) => v == null || v.trim().isEmpty ? 'HPP wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOutsetInput(
                          label: 'Batas Minimum Stok (Alert)',
                          hint: 'Contoh: 500',
                          icon: LucideIcons.alertCircle,
                          controller: _minStockCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ThousandSeparatorInputFormatter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 3: CATATAN & STATUS
              _buildCardSection(
                title: 'Pengaturan & Catatan',
                icon: LucideIcons.sliders,
                children: [
                  _buildOutsetInput(
                    label: 'Catatan Penyimpanan / Supplier',
                    hint: 'Contoh: Simpan di chiller suhu 4°C, vendor supplier langganan...',
                    icon: LucideIcons.alignLeft,
                    controller: _descriptionCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),

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
                              Text('Status Bahan Baku Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Bahan siap dipakai dalam peracikan resep', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
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

  // --- REUSABLE OUTSET FLOATING LABEL WIDGETS ---

  Widget _buildOutsetInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        prefixText: prefixText,
        prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildOutsetDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _ThousandSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final clean = newValue.text.replaceAll('.', '').replaceAll(',', '');
    final number = int.tryParse(clean);
    if (number == null) return oldValue;

    final formatted = _formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
