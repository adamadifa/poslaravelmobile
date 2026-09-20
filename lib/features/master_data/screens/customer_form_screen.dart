import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/customer_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _creditLimitCtrl = TextEditingController();

  int? _selectedGroupId;
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchCustomerGroups();
    });
    _initForm();
  }

  void _initForm() {
    if (widget.customer != null) {
      final c = widget.customer!;
      _nameCtrl.text = c.name;
      _codeCtrl.text = c.code ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _emailCtrl.text = c.email ?? '';
      _cityCtrl.text = c.city ?? '';
      _addressCtrl.text = c.address ?? '';
      if (c.creditLimit > 0) {
        _creditLimitCtrl.text = c.creditLimit.toInt().toString();
      }
      _selectedGroupId = c.customerGroupId;
      _isActive = c.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _creditLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi formulir dengan benar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final rawLimit = _creditLimitCtrl.text.replaceAll('.', '').replaceAll(',', '').trim();
      final creditLimit = double.tryParse(rawLimit) ?? 0;

      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'code': _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        'customer_group_id': _selectedGroupId,
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'credit_limit': creditLimit,
        'is_active': _isActive,
      };

      final provider = context.read<MasterDataProvider>();
      CustomerModel? result;

      if (isEdit) {
        result = await provider.updateCustomer(widget.customer!.id, payload);
      } else {
        result = await provider.createCustomer(payload);
      }

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Data pelanggan berhasil diperbarui.' : 'Pelanggan baru berhasil didaftarkan.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final err = provider.errorMessage ?? 'Gagal menyimpan data pelanggan.';
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
    final groups = context.watch<MasterDataProvider>().customerGroups;

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
          isEdit ? 'Edit Pelanggan / Member' : 'Tambah Pelanggan / Member',
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
            onPressed: _isSaving ? null : _saveCustomer,
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
                        isEdit ? 'Simpan Perubahan' : 'Simpan Pelanggan',
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
              // CARD 1: INFORMASI UTAMA & MEMBER
              _buildCardSection(
                title: 'Informasi Utama & Member',
                icon: LucideIcons.userCheck,
                children: [
                  _buildOutsetInput(
                    label: 'Nama Pelanggan *',
                    hint: 'Contoh: Budi Santoso / Toko Makmur',
                    icon: LucideIcons.user,
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama pelanggan wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Kode Pelanggan (Opsional)',
                    hint: 'Kosongkan untuk otomatis (CUST-0001)',
                    icon: LucideIcons.hash,
                    controller: _codeCtrl,
                  ),
                  const SizedBox(height: 14),

                  // DROPDOWN GRUP MEMBER
                  _buildDropdownGroup(groups),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 2: KONTAK & ALAMAT
              _buildCardSection(
                title: 'Kontak & Alamat',
                icon: LucideIcons.phoneCall,
                children: [
                  _buildOutsetInput(
                    label: 'No. Telepon / WhatsApp',
                    hint: 'Contoh: 081234567890',
                    icon: LucideIcons.phone,
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Alamat Email (Opsional)',
                    hint: 'Contoh: customer@mail.com',
                    icon: LucideIcons.mail,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Kota / Wilayah',
                    hint: 'Contoh: Jakarta Selatan, Surabaya...',
                    icon: LucideIcons.mapPin,
                    controller: _cityCtrl,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetTextArea(
                    label: 'Alamat Pengiriman (Opsional)',
                    hint: 'Jalan, No Rumah/Ruko, RT/RW, Kecamatan...',
                    icon: LucideIcons.map,
                    controller: _addressCtrl,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 3: FINANSIAL & STATUS
              _buildCardSection(
                title: 'Finansial & Status',
                icon: LucideIcons.creditCard,
                children: [
                  _buildOutsetInput(
                    label: 'Limit Kredit / Piutang (Rp)',
                    hint: '0 (Tidak ada batas / Pembayaran Tunai)',
                    icon: LucideIcons.banknote,
                    controller: _creditLimitCtrl,
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
                              Text('Status Member Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Dapat dipilih di transaksi kasir & berhak diskon', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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

  Widget _buildDropdownGroup(List<Map<String, dynamic>> groups) {
    return FormField<int>(
      initialValue: _selectedGroupId,
      builder: (state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Grup Pelanggan / Member',
            labelStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: const Icon(LucideIcons.users, size: 16, color: Color(0xFF64748B)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedGroupId,
              isExpanded: true,
              hint: const Text(
                'Pilih Grup / Umum (Tanpa Diskon)',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Umum / Non-Member (0%)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                ...groups.map((g) {
                  final id = int.tryParse(g['id'].toString());
                  final name = g['name'] ?? '';
                  final disc = g['discount_percent'] != null ? '${g['discount_percent']}%' : '0%';
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(
                      '$name (Diskon $disc)',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedGroupId = val;
                });
                state.didChange(val);
              },
            ),
          ),
        );
      },
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
