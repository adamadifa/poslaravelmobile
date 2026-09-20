import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/unit_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class UnitFormScreen extends StatefulWidget {
  final UnitModel? unit;

  const UnitFormScreen({super.key, this.unit});

  @override
  State<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends State<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _shortNameCtrl = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  void _initForm() {
    if (widget.unit != null) {
      final u = widget.unit!;
      _nameCtrl.text = u.name;
      _shortNameCtrl.text = u.shortName ?? '';
      _isActive = u.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUnit() async {
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
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'short_name': _shortNameCtrl.text.trim(),
        'is_active': _isActive,
      };

      final provider = context.read<MasterDataProvider>();
      UnitModel? result;

      if (isEdit) {
        result = await provider.updateUnit(widget.unit!.id, payload);
      } else {
        result = await provider.createUnit(payload);
      }

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Satuan berhasil diperbarui.' : 'Satuan baru berhasil disimpan.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final err = provider.errorMessage ?? 'Gagal menyimpan data satuan.';
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
          isEdit ? 'Edit Satuan Unit' : 'Tambah Satuan Unit',
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
            onPressed: _isSaving ? null : _saveUnit,
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
                        isEdit ? 'Simpan Perubahan' : 'Simpan Satuan',
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
              // CARD 1: INFORMASI SATUAN
              _buildCardSection(
                title: 'Informasi Satuan (Unit)',
                icon: LucideIcons.scale,
                children: [
                  _buildOutsetInput(
                    label: 'Nama Satuan *',
                    hint: 'Contoh: Karton, Lusin, Botol, Pcs, Gram',
                    icon: LucideIcons.scale,
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama satuan wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Simbol / Singkatan *',
                    hint: 'Contoh: krt, lsn, btl, pcs, gr',
                    icon: LucideIcons.hash,
                    controller: _shortNameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Simbol/singkatan satuan wajib diisi' : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 2: PENGATURAN STATUS
              _buildCardSection(
                title: 'Pengaturan Status',
                icon: LucideIcons.sliders,
                children: [
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
                              Text('Status Satuan Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Tersedia untuk pilihan produk & konversi multi-satuan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
}
