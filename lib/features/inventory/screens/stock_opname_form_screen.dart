import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/stock_opname_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class StockOpnameFormScreen extends StatefulWidget {
  final StockOpnameModel? opname; // null for create

  const StockOpnameFormScreen({super.key, this.opname});

  @override
  State<StockOpnameFormScreen> createState() => _StockOpnameFormScreenState();
}

class _OpnameFormItem {
  final ProductModel product;
  double systemQty;
  double physicalQty;
  String? reason;
  final TextEditingController physicalQtyCtrl;
  final TextEditingController reasonCtrl;

  _OpnameFormItem({
    required this.product,
    required this.systemQty,
    required this.physicalQty,
    this.reason,
  })  : physicalQtyCtrl = TextEditingController(text: _formatQtyNum(physicalQty)),
        reasonCtrl = TextEditingController(text: reason ?? '');

  static String _formatQtyNum(num val) {
    final double d = val.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  double get differenceQty => physicalQty - systemQty;
  bool get hasDifference => differenceQty != 0;
  bool get isSurplus => differenceQty > 0;
  bool get isDeficit => differenceQty < 0;
}

class _StockOpnameFormScreenState extends State<StockOpnameFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();

  int? _selectedWarehouseId;
  String _status = 'draft';
  final List<_OpnameFormItem> _items = [];
  bool _isSubmitting = false;

  bool get isEditing => widget.opname != null;

  @override
  void initState() {
    super.initState();
    final nowStr = DateTime.now().toString().substring(0, 10);
    _dateCtrl.text = nowStr;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final masterProv = context.read<MasterDataProvider>();
      masterProv.fetchWarehouses();
      masterProv.fetchProducts();

      if (isEditing) {
        final op = widget.opname!;
        _selectedWarehouseId = op.warehouseId;
        _status = op.status;
        _notesCtrl.text = op.notes ?? '';
        _dateCtrl.text = op.opnameDate;

        for (var item in op.items) {
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
          _items.add(_OpnameFormItem(
            product: p,
            systemQty: item.systemQty,
            physicalQty: item.physicalQty,
            reason: item.reason,
          ));
        }
        setState(() {});
      } else {
        if (masterProv.warehouses.isNotEmpty) {
          _selectedWarehouseId = masterProv.warehouses.first.id;
          _loadProductsForWarehouse();
        }
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    for (var item in _items) {
      item.physicalQtyCtrl.dispose();
      item.reasonCtrl.dispose();
    }
    super.dispose();
  }

  void _loadProductsForWarehouse() {
    final masterProv = context.read<MasterDataProvider>();
    if (_selectedWarehouseId == null || masterProv.products.isEmpty) return;

    if (_items.isEmpty) {
      for (var p in masterProv.products) {
        double currentStock = p.stock;
        _items.add(_OpnameFormItem(
          product: p,
          systemQty: currentStock,
          physicalQty: currentStock,
        ));
      }
      setState(() {});
    }
  }

  void _addProductManual(ProductModel product) {
    if (_items.any((i) => i.product.id == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} sudah ada dalam daftar audit.')),
      );
      return;
    }

    setState(() {
      _items.insert(
        0,
        _OpnameFormItem(
          product: product,
          systemQty: product.stock,
          physicalQty: product.stock,
        ),
      );
    });
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
              return p.name.toLowerCase().contains(search.toLowerCase()) ||
                  (p.code?.toLowerCase().contains(search.toLowerCase()) ?? false);
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Produk Audit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: _floatingInputDecoration(
                      label: 'Cari Produk',
                      hint: 'Ketik nama atau kode SKU...',
                      prefixIcon: LucideIcons.search,
                    ),
                    onChanged: (val) {
                      setModalState(() => search = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, idx) {
                        final p = filtered[idx];
                        final isAdded = _items.any((i) => i.product.id == p.id);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(LucideIcons.package, size: 18, color: Color(0xFFEA580C)),
                          ),
                          title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          subtitle: Text('Stok Sistem: ${p.stock} ${p.unitName ?? 'Pcs'}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          trailing: isAdded
                              ? const Icon(LucideIcons.checkCircle2, color: Color(0xFF059669), size: 22)
                              : IconButton(
                                  icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 22),
                                  onPressed: () {
                                    _addProductManual(p);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih gudang lokasi audit terlebih dahulu!')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan setidaknya 1 item produk untuk diaudit!')));
      return;
    }

    setState(() => _isSubmitting = true);
    final stockProv = context.read<StockProvider>();

    final payload = {
      'warehouse_id': _selectedWarehouseId,
      'opname_date': _dateCtrl.text.trim(),
      'status': _status,
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      'items': _items.map((i) => i.toJson()).toList(),
    };

    bool success = false;
    if (isEditing) {
      success = await stockProv.updateOpname(widget.opname!.id, payload);
    } else {
      success = await stockProv.createOpname(payload);
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Stok Opname berhasil diperbarui.' : 'Dokumen Stok Opname berhasil dibuat.')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stockProv.errorMessage ?? 'Terjadi kesalahan saat menyimpan')),
      );
    }
  }

  String _formatQty(num? val) {
    if (val == null) return '0';
    final double d = val.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  // Consistent Card Container
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
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
          const Divider(height: 24, thickness: 0.8, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }

  // Consistent Floating Label Outlined Input Decoration
  InputDecoration _floatingInputDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
    bool isRequired = false,
  }) {
    final hasAsterisk = label.endsWith('*');
    final cleanLabel = hasAsterisk ? label.substring(0, label.length - 1).trim() : label;
    final isReq = isRequired || hasAsterisk;

    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: cleanLabel,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
          children: isReq
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : null,
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(prefixIcon, size: 16, color: const Color(0xFF94A3B8)),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
      errorStyle: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterProv = context.watch<MasterDataProvider>();
    final warehouses = masterProv.warehouses;

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
          isEditing ? 'Edit Stok Opname' : 'Buat Stok Opname Baru',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: Colors.white, size: 20),
            tooltip: 'Tambah Item Produk',
            onPressed: _showAddProductModal,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_items.length} Item Diaudit',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      '${_items.where((i) => i.hasDifference).length} Selisih Fisik',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFEA580C)),
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
                      : Row(
                          children: [
                            const Icon(LucideIcons.check, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              isEditing ? 'Perbarui Opname' : 'Simpan Opname',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ],
                        ),
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
            // Card 1: Informasi Audit & Gudang (Sesuai style Info & Harga)
            _buildCardSection(
              title: 'Informasi Dokumen & Gudang',
              icon: LucideIcons.clipboardList,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedWarehouseId,
                  isExpanded: true,
                  decoration: _floatingInputDecoration(
                    label: 'Lokasi Gudang / Cabang *',
                    hint: 'Pilih Gudang Audit',
                    prefixIcon: LucideIcons.warehouse,
                  ),
                  items: warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: isEditing
                      ? null
                      : (val) {
                          setState(() {
                            _selectedWarehouseId = val;
                            _items.clear();
                            _loadProductsForWarehouse();
                          });
                        },
                ),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: _floatingInputDecoration(
                          label: 'Tanggal Audit *',
                          hint: 'YYYY-MM-DD',
                          prefixIcon: LucideIcons.calendar,
                        ),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) {
                            _dateCtrl.text = d.toString().substring(0, 10);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        isExpanded: true,
                        decoration: _floatingInputDecoration(
                          label: 'Status Dokumen *',
                          hint: 'Pilih Status',
                          prefixIcon: LucideIcons.checkCircle2,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'draft', child: Text('Draft', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: _floatingInputDecoration(
                    label: 'Catatan / Keterangan Opname',
                    hint: 'Contoh: Audit stok akhir bulan gudang utama...',
                    prefixIcon: LucideIcons.fileText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Card 2: Items Audit Section
            _buildCardSection(
              title: 'Daftar Item Fisik & Sistem (${_items.length})',
              icon: LucideIcons.boxes,
              children: [
                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(LucideIcons.packageOpen, size: 40, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 10),
                        const Text('Belum ada item diaudit', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        const Text('Tekan tombol "+ Tambah Produk" di pojok kanan atas untuk memasukkan item.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
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
                        border: Border.all(
                          color: item.hasDifference
                              ? (item.isSurplus ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5))
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Product Name + SKU + Delete button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(LucideIcons.package, size: 16, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                                    if (item.product.code != null)
                                      Text('SKU: ${item.product.code}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _items.removeAt(idx);
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(LucideIcons.trash2, size: 17, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: Color(0xFFE2E8F0)),

                          // System vs Physical vs Diff Grid
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // System Qty Box
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Stok Sistem', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_formatQty(item.systemQty)} ${item.product.unitName ?? 'Pcs'}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Physical Input Field
                              Expanded(
                                child: TextFormField(
                                  controller: item.physicalQtyCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _floatingInputDecoration(
                                    label: 'Stok Fisik *',
                                    hint: '0',
                                    prefixText: '',
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                  onChanged: (val) {
                                    setState(() {
                                      item.physicalQty = double.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Difference Badge Box
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: item.isSurplus
                                        ? const Color(0xFFECFDF5)
                                        : (item.isDeficit ? const Color(0xFFFEE2E2) : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: item.isSurplus
                                          ? const Color(0xFF86EFAC)
                                          : (item.isDeficit ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Selisih', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.differenceQty > 0 ? '+' : ''}${_formatQty(item.differenceQty)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: item.isSurplus
                                              ? const Color(0xFF059669)
                                              : (item.isDeficit ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Reason Field (if difference exists)
                          if (item.hasDifference) ...[
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: item.reasonCtrl,
                              decoration: _floatingInputDecoration(
                                label: 'Alasan Selisih',
                                hint: 'Misal: expired, rusak, salah hitung...',
                                prefixIcon: LucideIcons.helpCircle,
                              ),
                              onChanged: (val) => item.reason = val,
                            ),
                          ],
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

extension on _OpnameFormItem {
  Map<String, dynamic> toJson() => {
        'product_id': product.id,
        'physical_qty': physicalQty,
        'reason': reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
      };
}
