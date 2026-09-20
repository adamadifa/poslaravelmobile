import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/supplier_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class SupplierFormScreen extends StatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _taxIdCtrl = TextEditingController();
  final TextEditingController _termDaysCtrl = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  void _initForm() {
    if (widget.supplier != null) {
      final s = widget.supplier!;
      _nameCtrl.text = s.name;
      _codeCtrl.text = s.code ?? '';
      _contactPersonCtrl.text = s.contactPerson ?? '';
      _phoneCtrl.text = s.phone ?? '';
      _emailCtrl.text = s.email ?? '';
      _cityCtrl.text = s.city ?? '';
      _addressCtrl.text = s.address ?? '';
      _taxIdCtrl.text = s.taxId ?? '';
      if (s.paymentTermDays > 0) {
        _termDaysCtrl.text = s.paymentTermDays.toString();
      }
      _isActive = s.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _taxIdCtrl.dispose();
    _termDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
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
      final termDays = int.tryParse(_termDaysCtrl.text.trim()) ?? 0;

      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'code': _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        'contact_person': _contactPersonCtrl.text.trim().isEmpty ? null : _contactPersonCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'tax_id': _taxIdCtrl.text.trim().isEmpty ? null : _taxIdCtrl.text.trim(),
        'payment_term_days': termDays,
        'is_active': _isActive,
      };

      final provider = context.read<MasterDataProvider>();
      SupplierModel? result;

      if (isEdit) {
        result = await provider.updateSupplier(widget.supplier!.id, payload);
      } else {
        result = await provider.createSupplier(payload);
      }

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Data pemasok berhasil diperbarui.' : 'Pemasok baru berhasil disimpan.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final err = provider.errorMessage ?? 'Gagal menyimpan data pemasok.';
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
          isEdit ? 'Edit Pemasok (Supplier)' : 'Tambah Pemasok Baru',
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
            onPressed: _isSaving ? null : _saveSupplier,
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
                        isEdit ? 'Simpan Perubahan' : 'Simpan Pemasok',
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
              // CARD 1: INFORMASI PERUSAHAAN / PEMASOK
              _buildCardSection(
                title: 'Informasi Pemasok / Distributor',
                icon: LucideIcons.truck,
                children: [
                  _buildOutsetInput(
                    label: 'Nama Pemasok / PT / CV *',
                    hint: 'Contoh: PT Sumber Makmur Sentosa',
                    icon: LucideIcons.building,
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama pemasok wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Kode Pemasok (Opsional)',
                    hint: 'Kosongkan untuk otomatis (SUPP-0001)',
                    icon: LucideIcons.hash,
                    controller: _codeCtrl,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Nama PIC / Kontak Person',
                    hint: 'Contoh: Bpk. Hendra Wijaya (Sales)',
                    icon: LucideIcons.user,
                    controller: _contactPersonCtrl,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 2: KONTAK & LOKASI
              _buildCardSection(
                title: 'Kontak & Alamat Kantor / Gudang',
                icon: LucideIcons.phoneCall,
                children: [
                  _buildOutsetInput(
                    label: 'No. Telepon / WhatsApp',
                    hint: 'Contoh: 081234567890 / 021-5551234',
                    icon: LucideIcons.phone,
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Alamat Email',
                    hint: 'Contoh: order@pemasok.co.id',
                    icon: LucideIcons.mail,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Kota / Wilayah',
                    hint: 'Contoh: Jakarta Barat, Surabaya...',
                    icon: LucideIcons.mapPin,
                    controller: _cityCtrl,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetTextArea(
                    label: 'Alamat Lengkap',
                    hint: 'Kawasan Industri, Pergudangan Blok A No. 12...',
                    icon: LucideIcons.map,
                    controller: _addressCtrl,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 3: NPWP & SYARAT PEMBAYARAN
              _buildCardSection(
                title: 'NPWP & Termin Pembayaran (TOP)',
                icon: LucideIcons.creditCard,
                children: [
                  _buildOutsetInput(
                    label: 'Nomor NPWP / Pajak',
                    hint: 'Contoh: 01.234.567.8-901.000',
                    icon: LucideIcons.fileText,
                    controller: _taxIdCtrl,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Termin Pembayaran / Tempo (Hari)',
                    hint: '0 (Cash / Tunai Saat Terima Barang)',
                    icon: LucideIcons.calendar,
                    controller: _termDaysCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                              Text('Status Pemasok Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Tersedia untuk modul pembelian & penerimaan stok PO', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
