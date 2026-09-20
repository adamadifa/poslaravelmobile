import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class AccountFormScreen extends StatefulWidget {
  final AccountModel? account;

  const AccountFormScreen({super.key, this.account});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _accountHolderCtrl;
  late TextEditingController _openingBalanceCtrl;
  late TextEditingController _alertMinBalanceCtrl;
  late TextEditingController _descCtrl;

  String _selectedType = 'cash';
  bool _isDefault = false;
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.account != null;

  final List<Map<String, String>> _types = [
    {'key': 'cash', 'label': 'Kas Fisik Laci (Cash)'},
    {'key': 'bank', 'label': 'Bank Operasional'},
    {'key': 'bank_agent', 'label': 'Agen Bank / Mesin EDC (BRILink, dsb)'},
    {'key': 'ppob_provider', 'label': 'Deposit PPOB (Pulsa, Token, Tagihan)'},
    {'key': 'other', 'label': 'Lainnya / Dompet Digital'},
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.account;

    _codeCtrl = TextEditingController(text: acc?.accountCode ?? _generateSuggestedCode('cash'));
    _nameCtrl = TextEditingController(text: acc?.name ?? '');
    _bankNameCtrl = TextEditingController(text: acc?.bankName ?? '');
    _accountNumberCtrl = TextEditingController(text: acc?.accountNumber ?? '');
    _accountHolderCtrl = TextEditingController(text: acc?.accountHolder ?? '');
    _openingBalanceCtrl = TextEditingController(
      text: acc != null ? acc.openingBalance.toInt().toString() : '0',
    );
    _alertMinBalanceCtrl = TextEditingController(
      text: acc != null ? acc.alertMinimumBalance.toInt().toString() : '0',
    );
    _descCtrl = TextEditingController(text: acc?.description ?? '');

    if (acc != null) {
      _selectedType = acc.type;
      _isDefault = acc.isDefault;
      _isActive = acc.isActive;
    }
  }

  String _generateSuggestedCode(String type) {
    final now = DateTime.now();
    final suffix = now.millisecondsSinceEpoch.toString().substring(9);
    switch (type) {
      case 'cash':
        return 'KAS-$suffix';
      case 'bank':
        return 'BANK-$suffix';
      case 'bank_agent':
        return 'AGEN-$suffix';
      case 'ppob_provider':
        return 'PPOB-$suffix';
      default:
        return 'ACC-$suffix';
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    _openingBalanceCtrl.dispose();
    _alertMinBalanceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
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
        'account_code': _codeCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'type': _selectedType,
        'bank_name': _bankNameCtrl.text.trim().isNotEmpty ? _bankNameCtrl.text.trim() : null,
        'account_number': _accountNumberCtrl.text.trim().isNotEmpty ? _accountNumberCtrl.text.trim() : null,
        'account_holder': _accountHolderCtrl.text.trim().isNotEmpty ? _accountHolderCtrl.text.trim() : null,
        'opening_balance': double.tryParse(_openingBalanceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
        'alert_minimum_balance': double.tryParse(_alertMinBalanceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
        'is_default': _isDefault ? 1 : 0,
        'is_active': _isActive ? 1 : 0,
        'description': _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      };

      final provider = context.read<MasterDataProvider>();
      bool ok = false;

      if (isEdit) {
        ok = await provider.updateAccount(widget.account!.id, payload);
      } else {
        ok = await provider.storeAccount(payload);
      }

      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Data akun kas berhasil diperbarui.' : 'Akun kas baru berhasil disimpan.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final err = provider.errorMessage ?? 'Gagal menyimpan akun kas & bank.';
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
    final isBankOrAgent = _selectedType == 'bank' || _selectedType == 'bank_agent';

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
          isEdit ? 'Edit Akun Kas & Bank' : 'Tambah Akun Kas & Bank',
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
            onPressed: _isSaving ? null : _saveAccount,
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
                        isEdit ? 'Simpan Perubahan' : 'Simpan Akun Kas',
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
              // CARD 1: INFORMASI UTAMA AKUN
              _buildCardSection(
                title: 'Informasi Utama Akun',
                icon: LucideIcons.wallet,
                children: [
                  // Dropdown Tipe Akun
                  _buildDropdownType(),
                  const SizedBox(height: 14),

                  // Nama Akun
                  _buildOutsetInput(
                    label: 'Nama Akun Kas / Bank *',
                    hint: 'Contoh: Kas Laci Kasir 1, Bank BCA Operasional',
                    icon: LucideIcons.tag,
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama akun wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Kode Akun
                  _buildOutsetInput(
                    label: 'Kode Akun *',
                    hint: 'Contoh: KAS-01, BCA-01',
                    icon: LucideIcons.hash,
                    controller: _codeCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Kode akun wajib diisi' : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 2: DETAIL REKENING & BANK (Jika Bank / EDC / PPOB)
              if (isBankOrAgent || _selectedType == 'ppob_provider' || _selectedType == 'other') ...[
                _buildCardSection(
                  title: 'Detail Rekening / Provider',
                  icon: LucideIcons.creditCard,
                  children: [
                    _buildOutsetInput(
                      label: _selectedType == 'ppob_provider' ? 'Nama Provider PPOB' : 'Nama Bank',
                      hint: _selectedType == 'ppob_provider' ? 'Contoh: Digiflazz, VIP Payment' : 'Contoh: Bank BCA, BRI, Mandiri',
                      icon: LucideIcons.building2,
                      controller: _bankNameCtrl,
                    ),
                    const SizedBox(height: 14),

                    _buildOutsetInput(
                      label: _selectedType == 'ppob_provider' ? 'ID Akun / Member ID' : 'Nomor Rekening',
                      hint: 'Contoh: 1234567890',
                      icon: LucideIcons.creditCard,
                      controller: _accountNumberCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    _buildOutsetInput(
                      label: 'Atas Nama Pemilik Rekening (A/N)',
                      hint: 'Contoh: PT Toko Berkah / Budi Santoso',
                      icon: LucideIcons.userCheck,
                      controller: _accountHolderCtrl,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // CARD 3: SALDO & PERINGATAN
              _buildCardSection(
                title: 'Saldo Awal & Batas Peringatan',
                icon: LucideIcons.coins,
                children: [
                  if (!isEdit) ...[
                    _buildOutsetInput(
                      label: 'Saldo Awal (Rp) *',
                      hint: '0',
                      icon: LucideIcons.dollarSign,
                      controller: _openingBalanceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v == null || v.trim().isEmpty ? 'Saldo awal wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  _buildOutsetInput(
                    label: 'Peringatan Saldo Minimum (Rp)',
                    hint: '0 (Tidak ada peringatan)',
                    icon: LucideIcons.alertTriangle,
                    controller: _alertMinBalanceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Sistem akan menampilkan status peringatan jika saldo berada di bawah batas ini.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 4: PENGATURAN STATUS & CATATAN
              _buildCardSection(
                title: 'Pengaturan Akun & Catatan',
                icon: LucideIcons.sliders,
                children: [
                  // Default Account Switch Tile
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.star, color: Color(0xFFEA580C), size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jadikan Akun Utama (POS)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Akun default kasir saat menerima pembayaran tunai', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isDefault,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isDefault = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Active Status Switch Tile
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
                              Text('Status Akun Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Tersedia untuk transaksi kasir & keuangan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                    hint: 'Keterangan tambahan untuk akun kas ini (opsional)...',
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

  Widget _buildDropdownType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
          decoration: InputDecoration(
            labelText: 'Tipe Akun *',
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
          items: _types.map((t) {
            return DropdownMenuItem<String>(
              value: t['key'],
              child: Text(
                t['label']!,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedType = val;
                if (!isEdit) {
                  _codeCtrl.text = _generateSuggestedCode(val);
                }
              });
            }
          },
        ),
      ],
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
