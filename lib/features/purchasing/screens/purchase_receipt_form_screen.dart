import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/purchase_order_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/purchasing/providers/purchasing_provider.dart';

class PurchaseReceiptFormScreen extends StatefulWidget {
  final PurchaseOrderModel? fromOrder;

  const PurchaseReceiptFormScreen({super.key, this.fromOrder});

  @override
  State<PurchaseReceiptFormScreen> createState() => _PurchaseReceiptFormScreenState();
}

class _GRNItemRow {
  int productId;
  String productName;
  int unitId;
  String unitName;
  int? poItemId;
  TextEditingController qtyCtrl;
  TextEditingController costCtrl;
  TextEditingController batchCtrl;

  _GRNItemRow({
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    this.poItemId,
    required this.qtyCtrl,
    required this.costCtrl,
    required this.batchCtrl,
  });

  double get qty => double.tryParse(qtyCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  double get cost => double.tryParse(costCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  double get lineSubtotal => qty * cost;
}

class _PurchaseReceiptFormScreenState extends State<PurchaseReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedSupplierId;
  int? _selectedWarehouseId;
  int? _selectedPoId;
  DateTime _receiptDate = DateTime.now();

  late TextEditingController _invoiceNumCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _notesCtrl;

  final List<_GRNItemRow> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoiceNumCtrl = TextEditingController();
    _taxCtrl = TextEditingController(text: '0');
    _notesCtrl = TextEditingController();

    if (widget.fromOrder != null) {
      final po = widget.fromOrder!;
      _selectedSupplierId = po.supplierId;
      _selectedWarehouseId = po.warehouseId;
      _selectedPoId = po.id;
      _taxCtrl.text = CurrencyFormatter.format(po.taxAmount);

      for (var item in po.items) {
        _items.add(_GRNItemRow(
          productId: item.productId,
          productName: item.productName,
          unitId: item.unitId,
          unitName: item.unitName,
          poItemId: item.id,
          qtyCtrl: TextEditingController(text: item.quantityOrdered.toStringAsFixed(0)),
          costCtrl: TextEditingController(text: CurrencyFormatter.format(item.unitPrice)),
          batchCtrl: TextEditingController(),
        ));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final masterProv = Provider.of<MasterDataProvider>(context, listen: false);
      masterProv.fetchSuppliers();
      masterProv.fetchWarehouses();
      masterProv.fetchProducts();
      masterProv.fetchUnits();
      Provider.of<PurchasingProvider>(context, listen: false).fetchOrders();
    });
  }

  @override
  void dispose() {
    _invoiceNumCtrl.dispose();
    _taxCtrl.dispose();
    _notesCtrl.dispose();
    for (var item in _items) {
      item.qtyCtrl.dispose();
      item.costCtrl.dispose();
      item.batchCtrl.dispose();
    }
    super.dispose();
  }

  double get _itemsSubtotal {
    return _items.fold(0, (sum, it) => sum + it.lineSubtotal);
  }

  double get _taxAmount {
    return double.tryParse(_taxCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  double get _grandTotal {
    return _itemsSubtotal + _taxAmount;
  }

  void _addItemFromProduct(ProductModel product) {
    setState(() {
      _items.add(_GRNItemRow(
        productId: product.id,
        productName: product.name,
        unitId: product.baseUnitId ?? 1,
        unitName: product.unitName ?? 'Pcs',
        qtyCtrl: TextEditingController(text: '1'),
        costCtrl: TextEditingController(text: CurrencyFormatter.format(product.costPrice)),
        batchCtrl: TextEditingController(),
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
          builder: (context, setModalState) {
            final filtered = products.where((p) =>
              p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (p.code != null && p.code!.toLowerCase().contains(searchQuery.toLowerCase())) ||
              (p.barcode != null && p.barcode!.toLowerCase().contains(searchQuery.toLowerCase()))
            ).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pilih Produk Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        onChanged: (v) => setModalState(() => searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Cari nama atau barcode...',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (c, idx) {
                        final p = filtered[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          subtitle: Text('HPP: ${CurrencyFormatter.format(p.costPrice)} • Satuan: ${p.unitName ?? 'Pcs'}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _addItemFromProduct(p);
                            },
                            child: const Text('Pilih', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
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
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih supplier terlebih dahulu')));
      return;
    }
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih gudang penerima')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan setidaknya 1 produk')));
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'supplier_id': _selectedSupplierId,
      'warehouse_id': _selectedWarehouseId,
      'purchase_order_id': _selectedPoId,
      'supplier_invoice_number': _invoiceNumCtrl.text.trim().isEmpty ? null : _invoiceNumCtrl.text.trim(),
      'receipt_date': DateFormat('yyyy-MM-dd').format(_receiptDate),
      'tax_amount': _taxAmount,
      'notes': _notesCtrl.text.trim(),
      'items': _items.map((it) => {
        'product_id': it.productId,
        'purchase_order_item_id': it.poItemId,
        'unit_id': it.unitId,
        'quantity_received': it.qty,
        'unit_cost': it.cost,
        'batch_number': it.batchCtrl.text.trim().isEmpty ? null : it.batchCtrl.text.trim(),
      }).toList(),
    };

    final prov = Provider.of<PurchasingProvider>(context, listen: false);
    final success = await prov.createReceipt(payload);

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penerimaan barang berhasil disimpan! Stok bertambah.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.errorMessage ?? 'Gagal memproses penerimaan barang')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterProv = Provider.of<MasterDataProvider>(context);
    final purchProv = Provider.of<PurchasingProvider>(context);

    final suppliers = masterProv.suppliers;
    final warehouses = masterProv.warehouses;
    final units = masterProv.units;
    final poList = purchProv.orders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Form Penerimaan Barang (GRN)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SECTION 1: DOKUMEN & SUMBER
              _buildCardSection(
                title: 'Informasi Penerimaan & Gudang',
                icon: LucideIcons.truck,
                children: [
                  // PO Referensi (Opsional)
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedPoId,
                    isExpanded: true,
                    decoration: _floatingInputDecoration(
                      label: 'Referensi Purchase Order (PO)',
                      hint: 'Pilih PO jika ada (Opsional)',
                      prefixIcon: LucideIcons.fileText,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          '-- Penerimaan Langsung (Tanpa PO) --',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                      ...poList.map((po) => DropdownMenuItem<int?>(
                        value: po.id,
                        child: Text(
                          '${po.poNumber} (${po.supplierName})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedPoId = val;
                        if (val != null) {
                          final match = poList.firstWhere((p) => p.id == val);
                          _selectedSupplierId = match.supplierId;
                          _selectedWarehouseId = match.warehouseId;
                          _taxCtrl.text = CurrencyFormatter.format(match.taxAmount);

                          _items.clear();
                          for (var item in match.items) {
                            _items.add(_GRNItemRow(
                              productId: item.productId,
                              productName: item.productName,
                              unitId: item.unitId,
                              unitName: item.unitName,
                              poItemId: item.id,
                              qtyCtrl: TextEditingController(text: item.quantityOrdered.toStringAsFixed(0)),
                              costCtrl: TextEditingController(text: CurrencyFormatter.format(item.unitPrice)),
                              batchCtrl: TextEditingController(),
                            ));
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Supplier
                  DropdownButtonFormField<int>(
                    initialValue: _selectedSupplierId,
                    isExpanded: true,
                    decoration: _floatingInputDecoration(
                      label: 'Supplier / Pemasok *',
                      hint: 'Pilih Supplier',
                      prefixIcon: LucideIcons.building,
                    ),
                    items: suppliers.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedSupplierId = val),
                    validator: (v) => v == null ? 'Wajib dipilih' : null,
                  ),
                  const SizedBox(height: 12),

                  // Warehouse
                  DropdownButtonFormField<int>(
                    initialValue: _selectedWarehouseId,
                    isExpanded: true,
                    decoration: _floatingInputDecoration(
                      label: 'Gudang Tujuan Masuk *',
                      hint: 'Pilih Lokasi Gudang',
                      prefixIcon: LucideIcons.warehouse,
                    ),
                    items: warehouses.map((w) => DropdownMenuItem(
                      value: w.id,
                      child: Text(w.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedWarehouseId = val),
                    validator: (v) => v == null ? 'Wajib dipilih' : null,
                  ),
                  const SizedBox(height: 12),

                  // Tanggal Penerimaan & No Surat Jalan / Faktur
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _receiptDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) setState(() => _receiptDate = picked);
                          },
                          child: InputDecorator(
                            decoration: _floatingInputDecoration(
                              label: 'Tgl Terima *',
                              hint: 'Pilih Tanggal',
                              prefixIcon: LucideIcons.calendar,
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_receiptDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceNumCtrl,
                          decoration: _floatingInputDecoration(
                            label: 'No. SJ / Faktur Supplier',
                            hint: 'Contoh: SJ-9981',
                            prefixIcon: LucideIcons.hash,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 2: DAFTAR PRODUK MASUK
              _buildCardSection(
                title: 'Daftar Barang Diterima',
                icon: LucideIcons.boxes,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_items.length} item dipilih', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      TextButton.icon(
                        onPressed: _showProductPicker,
                        icon: const Icon(LucideIcons.plusCircle, size: 14, color: AppColors.primary),
                        label: const Text('Tambah Produk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(LucideIcons.packageOpen, size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 6),
                          Text('Belum ada item barang masuk', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = _items[idx];
                      return _buildGRNItemCard(item, idx, units);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 3: PAJAK & CATATAN
              _buildCardSection(
                title: 'Pajak & Catatan',
                icon: LucideIcons.calculator,
                children: [
                  TextFormField(
                    controller: _taxCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final val = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      final formatted = CurrencyFormatter.format(val);
                      if (_taxCtrl.text != formatted) {
                        _taxCtrl.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                      setState(() {});
                    },
                    decoration: _floatingInputDecoration(
                      label: 'Pajak Masukan / PPN (Rp)',
                      hint: '0',
                      prefixIcon: LucideIcons.receipt,
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: _floatingInputDecoration(
                      label: 'Catatan Tambahan',
                      hint: 'Kondisi barang, catatan driver, dll...',
                      prefixIcon: LucideIcons.messageSquare,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // RINGKASAN TOTAL
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Nilai Barang:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(CurrencyFormatter.format(_itemsSubtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pajak (PPN):', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(CurrencyFormatter.format(_taxAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total Masuk:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        Text(
                          CurrencyFormatter.format(_grandTotal),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan & Masukkan Stok', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _buildGRNItemCard(_GRNItemRow item, int index, List<dynamic> units) {
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
                child: Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
                onPressed: () => setState(() => _items.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Qty & Satuan
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => setState(() {}),
                  decoration: _floatingInputDecoration(label: 'Qty Terima *', hint: '1'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: units.any((u) => u.id == item.unitId) ? item.unitId : null,
                  isExpanded: true,
                  decoration: _floatingInputDecoration(label: 'Satuan *', hint: 'Pilih'),
                  items: units.map((u) => DropdownMenuItem<int>(
                    value: u.id,
                    child: Text(u.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final u = units.firstWhere((x) => x.id == val);
                      setState(() {
                        item.unitId = val;
                        item.unitName = u.name;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Harga Beli / HPP & Batch Number
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.costCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final val = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    final formatted = CurrencyFormatter.format(val);
                    if (item.costCtrl.text != formatted) {
                      item.costCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    setState(() {});
                  },
                  decoration: _floatingInputDecoration(
                    label: 'Harga Beli (HPP) *',
                    hint: '0',
                    prefixIcon: LucideIcons.coins,
                    prefixText: 'Rp ',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.batchCtrl,
                  decoration: _floatingInputDecoration(
                    label: 'No. Batch / Lot',
                    hint: 'Opsional',
                    prefixIcon: LucideIcons.scan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal Masuk:', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              Text(
                CurrencyFormatter.format(item.lineSubtotal),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
              ),
            ],
          ),
        ],
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
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
          const Divider(height: 24, thickness: 0.8, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }

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
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          children: isReq ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold))] : null,
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.3)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6)),
    );
  }
}
