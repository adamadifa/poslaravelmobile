import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/dining_table_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class DiningTableFormScreen extends StatefulWidget {
  final DiningTableModel? table;

  const DiningTableFormScreen({super.key, this.table});

  @override
  State<DiningTableFormScreen> createState() => _DiningTableFormScreenState();
}

class _DiningTableFormScreenState extends State<DiningTableFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tableNumberCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _capacityCtrl = TextEditingController(text: '4');
  final TextEditingController _sortOrderCtrl = TextEditingController(text: '0');

  int? _selectedWarehouseId;
  String _status = 'available';
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.table != null;

  final List<String> _commonAreas = ['Indoor AC', 'Outdoor Garden', 'VIP Room', 'Lantai 1', 'Lantai 2', 'Balkon / Rooftop', 'Bar Counter'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchWarehouses();
    });
    _initForm();
  }

  void _initForm() {
    if (widget.table != null) {
      final t = widget.table!;
      _tableNumberCtrl.text = t.tableNumber;
      _areaCtrl.text = t.area ?? '';
      _capacityCtrl.text = t.capacity.toString();
      _sortOrderCtrl.text = t.sortOrder.toString();
      _selectedWarehouseId = t.warehouseId;
      _status = t.status;
      _isActive = t.isActive;
    }
  }

  @override
  void dispose() {
    _tableNumberCtrl.dispose();
    _areaCtrl.dispose();
    _capacityCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi nomor meja dan area.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 4;
      final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;

      final payload = <String, dynamic>{
        'table_number': _tableNumberCtrl.text.trim(),
        'warehouse_id': _selectedWarehouseId,
        'area': _areaCtrl.text.trim(),
        'capacity': capacity,
        'status': _status,
        'sort_order': sortOrder,
        'is_active': _isActive,
      };

      final provider = context.read<MasterDataProvider>();
      DiningTableModel? result;

      if (isEdit) {
        result = await provider.updateTable(widget.table!.id, payload);
      } else {
        result = await provider.createTable(payload);
      }

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Data meja makan berhasil diperbarui.' : 'Meja makan baru berhasil disimpan.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final err = provider.errorMessage ?? 'Gagal menyimpan data meja.';
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
    final warehouses = context.watch<MasterDataProvider>().warehouses;

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
          isEdit ? 'Edit Meja Makan' : 'Tambah Meja Resto',
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
            onPressed: _isSaving ? null : _saveTable,
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
                        isEdit ? 'Simpan Perubahan' : 'Simpan Meja',
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
              // CARD 1: INFORMASI NOMOR & AREA MEJA
              _buildCardSection(
                title: 'Nomor Meja & Zona Area',
                icon: LucideIcons.utensils,
                children: [
                  _buildOutsetInput(
                    label: 'Nomor / Kode Meja *',
                    hint: 'Contoh: T01, T02, OUT-01, VIP-1',
                    icon: LucideIcons.hash,
                    controller: _tableNumberCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nomor meja wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Zona / Area Meja *',
                    hint: 'Contoh: Indoor AC, Outdoor Garden, VIP Room',
                    icon: LucideIcons.mapPin,
                    controller: _areaCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Area meja wajib diisi' : null,
                  ),
                  const SizedBox(height: 8),

                  // PRESET CHIPS AREA
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _commonAreas.map((areaName) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _areaCtrl.text = areaName;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _areaCtrl.text == areaName ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _areaCtrl.text == areaName ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '+ $areaName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _areaCtrl.text == areaName ? AppColors.primary : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // LOKASI CABANG / OUTLET
                  if (warehouses.isNotEmpty) ...[
                    FormField<int?>(
                      initialValue: _selectedWarehouseId,
                      builder: (state) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Cabang / Outlet Resto',
                            labelStyle: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            prefixIcon: const Icon(LucideIcons.store, size: 16, color: Color(0xFF64748B)),
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
                              value: _selectedWarehouseId,
                              isExpanded: true,
                              hint: const Text('Semua Cabang / Default Utama', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Cabang Default (Utama)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                ),
                                ...warehouses.map((w) {
                                  return DropdownMenuItem<int?>(
                                    value: w.id,
                                    child: Text(
                                      '${w.name} ${w.isDefault ? "(Default)" : ""}',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedWarehouseId = val);
                                state.didChange(val);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // CARD 2: KAPASITAS & URUTAN
              _buildCardSection(
                title: 'Kapasitas & Tata Letak',
                icon: LucideIcons.users,
                children: [
                  _buildOutsetInput(
                    label: 'Kapasitas Tamu (Jumlah Kursi) *',
                    hint: 'Contoh: 2, 4, 6, 8',
                    icon: LucideIcons.users,
                    controller: _capacityCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),

                  _buildOutsetInput(
                    label: 'Urutan Tampilan Denah (Sort Order)',
                    hint: '0 (Semakin kecil semakin awal)',
                    icon: LucideIcons.arrowDownUp,
                    controller: _sortOrderCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CARD 3: STATUS MEJA & AKTIF
              _buildCardSection(
                title: 'Status Meja & Ketersediaan',
                icon: LucideIcons.sliders,
                children: [
                  // DROPDOWN STATUS
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Kondisi / Status Meja',
                      labelStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      prefixIcon: const Icon(LucideIcons.activity, size: 16, color: Color(0xFF64748B)),
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
                      child: DropdownButton<String>(
                        value: _status,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'available', child: Text('🟢 Kosong / Tersedia (Available)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                          DropdownMenuItem(value: 'occupied', child: Text('🔴 Terisi / Sedang Makan (Occupied)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                          DropdownMenuItem(value: 'reserved', child: Text('🟡 Dipesan / Reservasi (Reserved)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                          DropdownMenuItem(value: 'cleaning', child: Text('🧹 Sedang Dibersihkan (Cleaning)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
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
                              Text('Status Meja Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('Tersedia untuk pilihan dine-in di POS Kasir Resto', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
}
