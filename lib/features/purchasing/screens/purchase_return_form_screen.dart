import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/purchase_receipt_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/purchasing/providers/purchasing_provider.dart';

class PurchaseReturnFormScreen extends StatefulWidget {
  final PurchaseReceiptModel? fromReceipt;

  const PurchaseReturnFormScreen({super.key, this.fromReceipt});

  @override
  State<PurchaseReturnFormScreen> createState() => _PurchaseReturnFormScreenState();
}

class _ReturnItemRow {
  int productId;
  String productName;
  int unitId;
  String unitName;
  int? receiptItemId;
  String? batchNumber;
  TextEditingController qtyCtrl;
  TextEditingController costCtrl;

  _ReturnItemRow({
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    this.receiptItemId,
    this.batchNumber,
    required this.qtyCtrl,
    required this.costCtrl,
  });

  double get qty => double.tryParse(qtyCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  double get cost => double.tryParse(costCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  double get lineSubtotal => qty * cost;
}

class _PurchaseReturnFormScreenState extends State<PurchaseReturnFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedSupplierId;
  int? _selectedWarehouseId;
  int? _selectedReceiptId;
  final TextEditingController _dateCtrl = TextEditingController();

  late TextEditingController _reasonCtrl;
  String _selectedReasonPreset = 'Barang Rusak / Cacat';

  final List<_ReturnItemRow> _items = [];
  bool _isLoading = false;

  final List<String> _reasonPresets = [
    'Barang Rusak / Cacat',
    'Kemasan Bocor / Rusak',
    'Salah Kirim Barang',
    'Mendekati / Lewat Kadaluarsa',
    'Kualitas Tidak Sesuai Standar',
    'Kelebihan Pengiriman',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dateCtrl.text = nowStr;
    _reasonCtrl = TextEditingController(text: _selectedReasonPreset);

    if (widget.fromReceipt != null) {
      final grn = widget.fromReceipt!;
      _selectedSupplierId = grn.supplierId;
      _selectedWarehouseId = grn.warehouseId;
      _selectedReceiptId = grn.id;

      for (var item in grn.items) {
        _items.add(_ReturnItemRow(
          productId: item.productId,
          productName: item.productName,
          unitId: item.unitId,
          unitName: item.unitName,
          receiptItemId: item.id,
          batchNumber: item.batchNumber,
          qtyCtrl: TextEditingController(text: item.quantityReceived.toStringAsFixed(0)),
          costCtrl: TextEditingController(text: CurrencyFormatter.formatNumber(item.unitCost)),
        ));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final masterProv = Provider.of<MasterDataProvider>(context, listen: false);
      masterProv.fetchSuppliers();
      masterProv.fetchWarehouses();
      masterProv.fetchProducts();
      masterProv.fetchUnits();
      Provider.of<PurchasingProvider>(context, listen: false).fetchReceipts();
    });
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _reasonCtrl.dispose();
    for (var item in _items) {
      item.qtyCtrl.dispose();
      item.costCtrl.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    return _items.fold(0, (sum, it) => sum + it.lineSubtotal);
  }

  void _addItemFromProduct(ProductModel product) {
    setState(() {
      _items.add(_ReturnItemRow(
        productId: product.id,
        productName: product.name,
        unitId: product.baseUnitId ?? 1,
        unitName: product.unitName ?? 'Pcs',
        qtyCtrl: TextEditingController(text: '1'),
        costCtrl: TextEditingController(text: CurrencyFormatter.formatNumber(product.costPrice)),
      ));
    });
  }

  void _showProductPicker() {
    final masterProv = Provider.of<MasterDataProvider>(context, listen: false);
    final products = masterProv.products;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = products.where((p) {
              final q = searchQuery.toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  (p.code?.toLowerCase().contains(q) ?? false) ||
                  (p.barcode?.toLowerCase().contains(q) ?? false);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.package, size: 20, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pilih Produk Retur',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: _floatingInputDecoration(
                      label: 'Cari Produk',
                      hint: 'Ketik nama / SKU / barcode...',
                      prefixIcon: LucideIcons.search,
                    ),
                    onChanged: (val) => setModalState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Produk tidak ditemukan.'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, idx) {
                              final p = filtered[idx];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(LucideIcons.package, size: 18, color: Color(0xFFDC2626)),
                                ),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                subtitle: Text('Harga Beli: ${CurrencyFormatter.format(p.costPrice)} • Satuan: ${p.unitName ?? 'Pcs'}', style: const TextStyle(fontSize: 11)),
                                trailing: const Icon(LucideIcons.plusCircle, color: Color(0xFFDC2626), size: 22),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _addItemFromProduct(p);
                                },
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

  void _loadFromReceipt(PurchaseReceiptModel grn) {
    setState(() {
      _selectedSupplierId = grn.supplierId;
      _selectedWarehouseId = grn.warehouseId;
      _selectedReceiptId = grn.id;
      _items.clear();

      for (var item in grn.items) {
        _items.add(_ReturnItemRow(
          productId: item.productId,
          productName: item.productName,
          unitId: item.unitId,
          unitName: item.unitName,
          receiptItemId: item.id,
          batchNumber: item.batchNumber,
          qtyCtrl: TextEditingController(text: item.quantityReceived.toStringAsFixed(0)),
          costCtrl: TextEditingController(text: CurrencyFormatter.formatNumber(item.unitCost)),
        ));
      }
    });
  }

  void _showReceiptPicker() {
    final purchasingProv = Provider.of<PurchasingProvider>(context, listen: false);
    final receipts = purchasingProv.receipts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.packageCheck, size: 20, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pilih Faktur / Penerimaan Barang (GRN)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: receipts.isEmpty
                    ? const Center(child: Text('Tidak ada data penerimaan barang.'))
                    : ListView.separated(
                        itemCount: receipts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final grn = receipts[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.fileCheck, size: 18, color: Color(0xFF059669)),
                            ),
                            title: Text(grn.grnNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            subtitle: Text('${grn.supplierName} • ${AppDateFormatter.format(grn.receiptDate)}', style: const TextStyle(fontSize: 11)),
                            trailing: Text(
                              CurrencyFormatter.format(grn.grandTotal),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF059669)),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _loadFromReceipt(grn);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih Supplier terlebih dahulu.')),
      );
      return;
    }

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih Gudang terlebih dahulu.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 item produk untuk diretur.')),
      );
      return;
    }

    for (var item in _items) {
      if (item.qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah retur untuk "${item.productName}" harus lebih dari 0.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final payload = {
      'purchase_receipt_id': _selectedReceiptId,
      'supplier_id': _selectedSupplierId,
      'warehouse_id': _selectedWarehouseId,
      'return_date': _dateCtrl.text.trim(),
      'reason': _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : _selectedReasonPreset,
      'items': _items.map((it) {
        return {
          'product_id': it.productId,
          'unit_id': it.unitId,
          'quantity': it.qty,
          'quantity_returned': it.qty,
          'unit_cost': it.cost,
          'batch_number': it.batchNumber,
          'purchase_receipt_item_id': it.receiptItemId,
        };
      }).toList(),
    };

    final purchasingProv = Provider.of<PurchasingProvider>(context, listen: false);
    final result = await purchasingProv.createReturn(payload);

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retur Pembelian ${result.returnNumber} berhasil diproses!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchasingProv.errorMessage ?? 'Gagal memproses Retur Pembelian.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
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
              Icon(icon, size: 18, color: const Color(0xFFDC2626)),
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
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
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
    final suppliers = masterProv.suppliers;
    final warehouses = masterProv.warehouses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buat Retur Pembelian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              _selectedReceiptId != null ? 'Ref: GRN #$_selectedReceiptId' : 'Pengembalian barang ke Supplier',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showReceiptPicker(),
            icon: const Icon(LucideIcons.fileSearch, color: Colors.white, size: 15),
            label: const Text(
              'Pilih GRN',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
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
                    const Text('TOTAL NILAI RETUR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(_totalAmount),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.rotateCcw, color: Colors.white, size: 17),
                  label: Text(
                    _isLoading ? 'Memproses...' : 'Proses Retur',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
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
            // Card 1: Supplier & Warehouse (Sesuai style Info & Harga)
            _buildCardSection(
              title: 'Informasi Supplier & Gudang',
              icon: LucideIcons.truck,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedSupplierId,
                  isExpanded: true,
                  decoration: _floatingInputDecoration(
                    label: 'Pemasok (Supplier) *',
                    hint: 'Pilih Supplier',
                    prefixIcon: LucideIcons.truck,
                  ),
                  items: suppliers.map((s) {
                    return DropdownMenuItem<int>(
                      value: s.id,
                      child: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSupplierId = val),
                  validator: (val) => val == null ? 'Wajib pilih supplier' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedWarehouseId ?? (warehouses.isNotEmpty ? warehouses.first.id : null),
                        isExpanded: true,
                        decoration: _floatingInputDecoration(
                          label: 'Gudang Asal *',
                          hint: 'Pilih Gudang',
                          prefixIcon: LucideIcons.warehouse,
                        ),
                        items: warehouses.map((w) {
                          return DropdownMenuItem<int>(
                            value: w.id,
                            child: Text(w.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedWarehouseId = val),
                        validator: (val) => val == null ? 'Wajib pilih gudang' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: _floatingInputDecoration(
                          label: 'Tanggal Retur *',
                          hint: 'YYYY-MM-DD',
                          prefixIcon: LucideIcons.calendar,
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Card 2: Reason & Notes
            _buildCardSection(
              title: 'Alasan Pengembalian (Retur)',
              icon: LucideIcons.alertCircle,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reasonPresets.map((preset) {
                    final isSelected = _selectedReasonPreset == preset;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedReasonPreset = preset;
                          if (preset != 'Lainnya') {
                            _reasonCtrl.text = preset;
                          } else {
                            _reasonCtrl.clear();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          preset,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 2,
                  decoration: _floatingInputDecoration(
                    label: 'Keterangan Alasan Retur',
                    hint: 'Detail alasan / catatan barang rusak...',
                    prefixIcon: LucideIcons.fileText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Card 3: Items List
            _buildCardSection(
              title: 'Daftar Item Diretur (${_items.length})',
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
                        const Text('Belum ada item produk dipilih', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        const Text('Pilih faktur GRN di atas atau tambahkan item produk manual.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _showProductPicker,
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Tambah Item Manual'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _showProductPicker,
                      icon: const Icon(LucideIcons.plus, size: 14, color: Color(0xFFDC2626)),
                      label: const Text('Tambah Produk Lain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return _buildItemRow(item, idx);
                  }),
                ],
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(_ReturnItemRow item, int index) {
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
                child: const Icon(LucideIcons.package, size: 16, color: Color(0xFFDC2626)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    if (item.batchNumber != null)
                      Text(
                        'Batch: ${item.batchNumber}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _items.removeAt(index));
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Qty Input
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: item.qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _floatingInputDecoration(
                    label: 'Qty Retur (${item.unitName}) *',
                    hint: '1',
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),

              // Unit Cost Input
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: item.costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _floatingInputDecoration(
                    label: 'Harga Beli Satuan *',
                    hint: '0',
                    prefixText: 'Rp ',
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal: ${CurrencyFormatter.format(item.lineSubtotal)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }
}
