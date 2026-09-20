import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/stock_adjustment_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class _AdjustFormItem {
  final ProductModel product;
  double quantity;
  double unitCost;
  final TextEditingController qtyCtrl;
  final TextEditingController costCtrl;

  _AdjustFormItem({
    required this.product,
    this.quantity = 1,
    double? unitCost,
  })  : unitCost = unitCost ?? product.costPrice,
        qtyCtrl = TextEditingController(text: '1'),
        costCtrl = TextEditingController(text: (unitCost ?? product.costPrice).toInt().toString());

  double get totalCost => quantity * unitCost;

  void dispose() {
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
}

class StockAdjustmentFormScreen extends StatefulWidget {
  final StockAdjustmentModel? adjustment; // null = create mode

  const StockAdjustmentFormScreen({super.key, this.adjustment});

  @override
  State<StockAdjustmentFormScreen> createState() => _StockAdjustmentFormScreenState();
}

class _StockAdjustmentFormScreenState extends State<StockAdjustmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  int? _selectedWarehouseId;
  String _type = 'addition'; // 'addition' | 'reduction'
  String _action = 'draft'; // 'draft' | 'approve'
  bool _isSubmitting = false;

  final List<_AdjustFormItem> _items = [];

  bool get isEditing => widget.adjustment != null;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateTime.now().toString().substring(0, 10);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final masterProv = context.read<MasterDataProvider>();
      masterProv.fetchWarehouses();
      masterProv.fetchProducts();

      if (isEditing) {
        final adj = widget.adjustment!;
        _selectedWarehouseId = adj.warehouseId;
        _type = adj.type;
        _reasonCtrl.text = adj.reason;
        _notesCtrl.text = adj.notes ?? '';
        _dateCtrl.text = adj.adjustmentDate.length >= 10 ? adj.adjustmentDate.substring(0, 10) : adj.adjustmentDate;

        for (final item in adj.items) {
          final p = masterProv.products.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => ProductModel(
              id: item.productId,
              name: item.productName,
              costPrice: item.unitCost,
              sellingPrice: 0,
              unitName: item.unitName,
            ),
          );
          final fi = _AdjustFormItem(product: p, quantity: item.quantity, unitCost: item.unitCost);
          fi.qtyCtrl.text = _formatNum(item.quantity);
          fi.costCtrl.text = item.unitCost.toInt().toString();
          _items.add(fi);
        }
        setState(() {});
      } else if (masterProv.warehouses.isNotEmpty) {
        _selectedWarehouseId = masterProv.warehouses.first.id;
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _reasonCtrl.dispose();
    _dateCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String _formatNum(num val) {
    final d = val.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _showAddProductModal() {
    final masterProv = context.read<MasterDataProvider>();
    final products = masterProv.products;
    String search = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = products.where((p) {
              final q = search.toLowerCase();
              return p.name.toLowerCase().contains(q) || (p.code?.toLowerCase().contains(q) ?? false);
            }).toList();

            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pilih Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                        IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    child: TextField(
                      decoration: _inputDecoration(label: 'Cari Produk', hint: 'Nama atau kode SKU...', icon: LucideIcons.search),
                      onChanged: (val) => setModalState(() => search = val),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, idx) {
                        final p = filtered[idx];
                        final isAdded = _items.any((i) => i.product.id == p.id);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          leading: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(LucideIcons.package, size: 18, color: Color(0xFFEA580C)),
                          ),
                          title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          subtitle: Text('Stok: ${_formatNum(p.stock)} ${p.unitName ?? 'Pcs'}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          trailing: isAdded
                              ? const Icon(LucideIcons.checkCircle2, color: Color(0xFF059669), size: 22)
                              : IconButton(
                                  icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 22),
                                  onPressed: () {
                                    setState(() {
                                      _items.insert(0, _AdjustFormItem(product: p));
                                    });
                                    Navigator.pop(ctx);
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouseId == null) {
      _showSnack('Pilih gudang terlebih dahulu!');
      return;
    }
    if (_items.isEmpty) {
      _showSnack('Tambahkan minimal 1 produk untuk disesuaikan!');
      return;
    }

    setState(() => _isSubmitting = true);
    final stockProv = context.read<StockProvider>();

    final payload = {
      'warehouse_id': _selectedWarehouseId,
      'adjustment_date': _dateCtrl.text.trim(),
      'type': _type,
      'reason': _reasonCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      'action': _action,
      'items': _items.map((i) => {
            'product_id': i.product.id,
            'quantity': i.quantity,
            'unit_cost': i.unitCost,
          }).toList(),
    };

    bool success;
    if (isEditing) {
      success = await stockProv.updateAdjustment(widget.adjustment!.id, payload);
    } else {
      success = await stockProv.createAdjustment(payload);
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      _showSnack(isEditing ? 'Penyesuaian stok berhasil diperbarui.' : 'Dokumen penyesuaian stok berhasil disimpan.');
      Navigator.pop(context);
    } else if (mounted) {
      _showSnack(stockProv.errorMessage ?? 'Terjadi kesalahan saat menyimpan.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputDecoration({required String label, required String hint, IconData? icon, bool required = false}) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          children: required ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold))] : null,
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      prefixIcon: icon != null ? Padding(padding: const EdgeInsets.only(left: 12, right: 8), child: Icon(icon, size: 16, color: const Color(0xFF94A3B8))) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.3)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6)),
      errorStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ]),
          const Divider(height: 24, thickness: 0.8, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterProv = context.watch<MasterDataProvider>();
    final warehouses = masterProv.warehouses;

    double totalVal = _items.fold(0.0, (s, i) => s + i.totalCost);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(isEditing ? 'Edit Penyesuaian Stok' : 'Buat Penyesuaian Stok',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: Colors.white, size: 20),
            tooltip: 'Tambah Produk',
            onPressed: _showAddProductModal,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), offset: Offset(0, -4), blurRadius: 10)],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_items.length} Produk', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    Text(
                      'Total: Rp ${totalVal.toInt()}',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _type == 'addition' ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : Row(children: [
                          const Icon(LucideIcons.check, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(isEditing ? 'Perbarui' : 'Simpan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                        ]),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card 1: Informasi Dokumen
            _buildCard(
              title: 'Informasi Penyesuaian',
              icon: LucideIcons.slidersHorizontal,
              children: [
                // Gudang
                DropdownButtonFormField<int>(
                  initialValue: _selectedWarehouseId,
                  isExpanded: true,
                  decoration: _inputDecoration(label: 'Lokasi Gudang', hint: 'Pilih Gudang', icon: LucideIcons.warehouse, required: true),
                  items: warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, style: const TextStyle(fontSize: 13)))).toList(),
                  validator: (v) => v == null ? 'Wajib dipilih' : null,
                  onChanged: (val) => setState(() => _selectedWarehouseId = val),
                ),
                const SizedBox(height: 14),

                // Tanggal
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  decoration: _inputDecoration(label: 'Tanggal Penyesuaian', hint: 'YYYY-MM-DD', icon: LucideIcons.calendar, required: true),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _dateCtrl.text = d.toString().substring(0, 10));
                  },
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // Jenis penyesuaian
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jenis Penyesuaian *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeToggle(
                            label: 'Penambahan (+)',
                            icon: LucideIcons.plusCircle,
                            isSelected: _type == 'addition',
                            color: const Color(0xFF059669),
                            bgColor: const Color(0xFFECFDF5),
                            onTap: () => setState(() => _type = 'addition'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeToggle(
                            label: 'Pengurangan (-)',
                            icon: LucideIcons.minusCircle,
                            isSelected: _type == 'reduction',
                            color: const Color(0xFFDC2626),
                            bgColor: const Color(0xFFFEE2E2),
                            onTap: () => setState(() => _type = 'reduction'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Alasan
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: _inputDecoration(label: 'Alasan / Keterangan', hint: 'Contoh: stok rusak, koreksi sistem, temuan audit...', icon: LucideIcons.helpCircle, required: true),
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // Catatan
                TextFormField(
                  controller: _notesCtrl,
                  decoration: _inputDecoration(label: 'Catatan Tambahan', hint: 'Opsional...', icon: LucideIcons.fileText),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                // Action: simpan sebagai draft atau langsung approve
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aksi Simpan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeToggle(
                            label: 'Simpan Draft',
                            icon: LucideIcons.fileEdit,
                            isSelected: _action == 'draft',
                            color: const Color(0xFF64748B),
                            bgColor: const Color(0xFFF1F5F9),
                            onTap: () => setState(() => _action = 'draft'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeToggle(
                            label: 'Langsung Setujui',
                            icon: LucideIcons.checkCircle,
                            isSelected: _action == 'approve',
                            color: AppColors.primary,
                            bgColor: AppColors.primary.withValues(alpha: 0.08),
                            onTap: () => setState(() => _action = 'approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Card 2: Item Produk
            _buildCard(
              title: 'Produk yang Disesuaikan (${_items.length})',
              icon: LucideIcons.boxes,
              children: [
                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(LucideIcons.packageOpen, size: 40, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 10),
                        const Text('Belum ada produk ditambahkan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _showAddProductModal,
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Tambah Produk'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                                child: const Icon(LucideIcons.package, size: 16, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                                    Text(
                                      'Stok saat ini: ${_formatNum(item.product.stock)} ${item.product.unitName ?? 'Pcs'}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() {
                                  item.dispose();
                                  _items.removeAt(idx);
                                }),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(LucideIcons.trash2, size: 17, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: item.qtyCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration(label: 'Jumlah *', hint: '0', required: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Wajib';
                                    if ((double.tryParse(v) ?? 0) <= 0) return '>0';
                                    return null;
                                  },
                                  onChanged: (val) => setState(() => item.quantity = double.tryParse(val) ?? 0),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: item.costCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration(label: 'Harga Modal', hint: '0', icon: LucideIcons.tag),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                  onChanged: (val) => setState(() => item.unitCost = double.tryParse(val) ?? 0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: Rp ${item.totalCost.toInt()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _type == 'addition' ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isSelected ? color : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isSelected ? color : const Color(0xFF94A3B8)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
