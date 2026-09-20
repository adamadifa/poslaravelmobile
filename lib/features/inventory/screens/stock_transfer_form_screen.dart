import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/stock_transfer_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class StockTransferFormScreen extends StatefulWidget {
  final StockTransferModel? transfer; // null for new create

  const StockTransferFormScreen({super.key, this.transfer});

  @override
  State<StockTransferFormScreen> createState() => _StockTransferFormScreenState();
}

class _TransferFormItem {
  final ProductModel product;
  double availableStock;
  double qty;
  String? batchNumber;
  final TextEditingController qtyCtrl;
  final TextEditingController notesCtrl;

  _TransferFormItem({
    required this.product,
    required this.availableStock,
    required this.qty,
    this.batchNumber,
    String? notes,
  })  : qtyCtrl = TextEditingController(text: _formatQtyNum(qty)),
        notesCtrl = TextEditingController(text: notes ?? '');

  static String _formatQtyNum(num val) {
    final double d = val.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}

class _StockTransferFormScreenState extends State<StockTransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();

  int? _fromWarehouseId;
  int? _toWarehouseId;
  bool _directDispatch = true; // Langsung kirim (status: in_transit) atau draft
  final List<_TransferFormItem> _items = [];
  bool _isSubmitting = false;

  bool get isEditing => widget.transfer != null;

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
        final tr = widget.transfer!;
        _fromWarehouseId = tr.fromWarehouseId;
        _toWarehouseId = tr.toWarehouseId;
        _notesCtrl.text = tr.notes ?? '';
        _dateCtrl.text = tr.transferDate;
        _directDispatch = tr.isInTransit;

        for (var item in tr.items) {
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
          _items.add(_TransferFormItem(
            product: p,
            availableStock: item.quantitySent,
            qty: item.quantitySent,
            batchNumber: item.batchNumber,
          ));
        }
        setState(() {});
      } else {
        if (masterProv.warehouses.length >= 2) {
          _fromWarehouseId = masterProv.warehouses[0].id;
          _toWarehouseId = masterProv.warehouses[1].id;
        } else if (masterProv.warehouses.isNotEmpty) {
          _fromWarehouseId = masterProv.warehouses[0].id;
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    for (var item in _items) {
      item.qtyCtrl.dispose();
      item.notesCtrl.dispose();
    }
    super.dispose();
  }

  String _formatQty(num? val) {
    if (val == null) return '0';
    final double d = val.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _addItem(ProductModel product) {
    if (_items.any((i) => i.product.id == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} sudah ada dalam daftar transfer.')),
      );
      return;
    }

    setState(() {
      _items.add(_TransferFormItem(
        product: product,
        availableStock: product.stock,
        qty: 1,
      ));
    });
  }

  void _showAddProductModal() {
    final masterProv = context.read<MasterDataProvider>();
    final products = masterProv.products;
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = products.where((p) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return p.name.toLowerCase().contains(q) || (p.code != null && p.code!.toLowerCase().contains(q)) || (p.barcode != null && p.barcode!.toLowerCase().contains(q));
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.packagePlus, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Pilih Produk Ditransfer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari nama produk atau barcode...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setModalState(() => query = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('Tidak ada produk ditemukan', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (c, i) {
                              final p = filtered[i];
                              final isAlreadyAdded = _items.any((item) => item.product.id == p.id);

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                subtitle: Text(
                                  'Kode: ${p.code ?? p.barcode ?? '-'} • Stok: ${_formatQty(p.stock)} ${p.unitName ?? 'Unit'}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                                trailing: isAlreadyAdded
                                    ? const Chip(
                                        label: Text('Ditambahkan', style: TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                        backgroundColor: Color(0xFFEEF2FF),
                                        padding: EdgeInsets.zero,
                                      )
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onPressed: () {
                                          _addItem(p);
                                          Navigator.pop(modalCtx);
                                        },
                                        child: const Text('Pilih', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
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

  Future<void> _submitForm() async {
    if (_fromWarehouseId == null || _toWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gudang asal dan gudang tujuan.')),
      );
      return;
    }

    if (_fromWarehouseId == _toWarehouseId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gudang asal dan gudang tujuan tidak boleh sama!')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 produk untuk ditransfer.')),
      );
      return;
    }

    for (var item in _items) {
      if (item.qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah transfer untuk ${item.product.name} harus lebih dari 0.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'from_warehouse_id': _fromWarehouseId,
        'to_warehouse_id': _toWarehouseId,
        'transfer_date': _dateCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        'status': _directDispatch ? 'in_transit' : 'draft',
        'items': _items.map((i) {
          return {
            'product_id': i.product.id,
            'quantity': i.qty,
            'unit_id': i.product.baseUnitId,
            'batch_number': i.batchNumber?.trim().isNotEmpty == true ? i.batchNumber!.trim() : null,
            'notes': i.notesCtrl.text.trim().isNotEmpty ? i.notesCtrl.text.trim() : null,
          };
        }).toList(),
      };

      final stockProv = context.read<StockProvider>();
      final success = await stockProv.createTransfer(payload);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _directDispatch
                  ? 'Transfer berhasil dibuat dan barang telah diposting dalam pengiriman!'
                  : 'Draft transfer berhasil disimpan.',
            ),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(stockProv.errorMessage ?? 'Gagal menyimpan transfer')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Helper Card Section
  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // Floating Input Decoration consistent with Product Form
  InputDecoration _floatingInputDecoration({
    required String label,
    required IconData prefixIcon,
    String? hintText,
    bool isRequired = false,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 18),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterProv = context.watch<MasterDataProvider>();
    final warehouses = masterProv.warehouses;

    double totalQty = 0;
    for (var i in _items) {
      totalQty += i.qty;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Dokumen Transfer' : 'Transfer Antar Gudang',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const Text(
              'Form pemindahan stok antar lokasi',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
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
                    const Text('Total Transfer', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    Text(
                      '${_items.length} Item (${_formatQty(totalQty)} Unit)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_directDispatch ? LucideIcons.truck : LucideIcons.save, size: 17, color: Colors.white),
                label: Text(
                  _directDispatch ? 'Kirim Transfer' : 'Simpan Draft',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Section 1: Lokasi & Rute Gudang
            _buildCardSection(
              icon: LucideIcons.mapPin,
              title: 'Lokasi & Rute Transfer',
              child: Column(
                children: [
                  // Gudang Asal
                  DropdownButtonFormField<int?>(
                    initialValue: _fromWarehouseId,
                    decoration: _floatingInputDecoration(
                      label: 'Gudang Asal (Pengirim)',
                      prefixIcon: LucideIcons.arrowUpRight,
                      isRequired: true,
                    ),
                    items: warehouses.map((w) {
                      return DropdownMenuItem<int?>(
                        value: w.id,
                        child: Text(w.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _fromWarehouseId = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gudang Tujuan
                  DropdownButtonFormField<int?>(
                    initialValue: _toWarehouseId,
                    decoration: _floatingInputDecoration(
                      label: 'Gudang Tujuan (Penerima)',
                      prefixIcon: LucideIcons.arrowDownLeft,
                      isRequired: true,
                    ),
                    items: warehouses.map((w) {
                      return DropdownMenuItem<int?>(
                        value: w.id,
                        child: Text(w.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _toWarehouseId = val);
                    },
                  ),

                  if (_fromWarehouseId != null && _toWarehouseId != null && _fromWarehouseId == _toWarehouseId)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.alertCircle, size: 15, color: Color(0xFFDC2626)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Gudang asal dan tujuan tidak boleh sama.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Informasi Dokumen & Jadwal
            _buildCardSection(
              icon: LucideIcons.calendar,
              title: 'Informasi Dokumen & Jadwal',
              child: Column(
                children: [
                  TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    decoration: _floatingInputDecoration(
                      label: 'Tanggal Transfer',
                      prefixIcon: LucideIcons.calendar,
                      isRequired: true,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: _floatingInputDecoration(
                      label: 'Catatan Pengiriman',
                      prefixIcon: LucideIcons.fileText,
                      hintText: 'Contoh: Titipan pengiriman via armada logistik A...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Option: Langsung Kirim / Simpan Draft
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _directDispatch ? LucideIcons.truck : LucideIcons.fileClock,
                          size: 20,
                          color: _directDispatch ? AppColors.primary : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _directDispatch ? 'Langsung Kirim (In Transit)' : 'Simpan Sebagai Draft',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                              ),
                              Text(
                                _directDispatch
                                    ? 'Stok gudang asal akan langsung dipotong dan berstatus dalam perjalanan.'
                                    : 'Stok belum dipotong sampai transfer dikirimkan.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _directDispatch,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _directDispatch = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 3: Daftar Produk Ditransfer
            _buildCardSection(
              icon: LucideIcons.boxes,
              title: 'Daftar Produk (${_items.length})',
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                label: const Text('Pilih Produk', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
                onPressed: _showAddProductModal,
              ),
              child: _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.packagePlus, size: 36, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum Ada Produk Ditambahkan',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Klik tombol "Pilih Produk" di atas untuk menambahkan barang',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final item = _items[idx];
                        return _buildItemRow(item, idx);
                      },
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(_TransferFormItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stok Tersedia: ${_formatQty(item.availableStock)} ${item.product.unitName ?? 'Unit'}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 17, color: Color(0xFFEF4444)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() => _items.removeAt(index));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _floatingInputDecoration(
                    label: 'Qty Transfer',
                    prefixIcon: LucideIcons.layers,
                    isRequired: true,
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                    item.qty = d;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.batchNumber,
                  decoration: _floatingInputDecoration(
                    label: 'Batch No (Opsional)',
                    prefixIcon: LucideIcons.tag,
                    hintText: 'Auto FIFO',
                  ),
                  onChanged: (val) {
                    item.batchNumber = val;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
