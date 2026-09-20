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

class PurchaseOrderFormScreen extends StatefulWidget {
  final PurchaseOrderModel? order;

  const PurchaseOrderFormScreen({super.key, this.order});

  @override
  State<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _POItemRow {
  int productId;
  String productName;
  int unitId;
  String unitName;
  TextEditingController qtyCtrl;
  TextEditingController priceCtrl;
  TextEditingController discCtrl;

  _POItemRow({
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.discCtrl,
  });

  double get qty => double.tryParse(qtyCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  double get price => double.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  double get discPercent => double.tryParse(discCtrl.text.replaceAll(',', '.')) ?? 0;
  double get discAmount => (qty * price) * (discPercent / 100);
  double get lineSubtotal => (qty * price) - discAmount;
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedSupplierId;
  int? _selectedWarehouseId;
  DateTime _orderDate = DateTime.now();
  DateTime? _expectedDate;
  String _selectedStatus = 'draft';

  late TextEditingController _discountCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _shippingCtrl;
  late TextEditingController _notesCtrl;

  final List<_POItemRow> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final o = widget.order;

    _discountCtrl = TextEditingController(
      text: (o != null && o.discountAmount > 0) ? CurrencyFormatter.formatNumber(o.discountAmount) : '',
    );
    _taxCtrl = TextEditingController(
      text: (o != null && o.taxAmount > 0) ? CurrencyFormatter.formatNumber(o.taxAmount) : '',
    );
    _shippingCtrl = TextEditingController(
      text: (o != null && o.shippingCost > 0) ? CurrencyFormatter.formatNumber(o.shippingCost) : '',
    );
    _notesCtrl = TextEditingController(text: o?.notes ?? '');

    if (o != null) {
      _selectedSupplierId = o.supplierId;
      _selectedWarehouseId = o.warehouseId;
      _selectedStatus = o.status == 'sent' ? 'sent' : 'draft';
      if (o.orderDate.isNotEmpty) {
        _orderDate = DateTime.tryParse(o.orderDate) ?? DateTime.now();
      }
      if (o.expectedDate != null && o.expectedDate!.isNotEmpty) {
        _expectedDate = DateTime.tryParse(o.expectedDate!);
      }

      for (var it in o.items) {
        _items.add(_POItemRow(
          productId: it.productId,
          productName: it.productName,
          unitId: it.unitId,
          unitName: it.unitName,
          qtyCtrl: TextEditingController(text: it.quantityOrdered.toStringAsFixed(it.quantityOrdered.truncateToDouble() == it.quantityOrdered ? 0 : 2)),
          priceCtrl: TextEditingController(text: CurrencyFormatter.formatNumber(it.unitPrice)),
          discCtrl: TextEditingController(text: it.discountPercent > 0 ? it.discountPercent.toStringAsFixed(0) : ''),
        ));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mProvider = context.read<MasterDataProvider>();
      mProvider.fetchSuppliers();
      mProvider.fetchWarehouses();
      mProvider.fetchProducts();
      mProvider.fetchUnits();

      if (widget.order == null && mProvider.warehouses.isNotEmpty) {
        final defWh = mProvider.warehouses.firstWhere((w) => w.isDefault, orElse: () => mProvider.warehouses.first);
        setState(() {
          _selectedWarehouseId = defWh.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _taxCtrl.dispose();
    _shippingCtrl.dispose();
    _notesCtrl.dispose();
    for (var it in _items) {
      it.qtyCtrl.dispose();
      it.priceCtrl.dispose();
      it.discCtrl.dispose();
    }
    super.dispose();
  }

  double _parseNumber(String text) {
    if (text.isEmpty) return 0;
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  double get _itemsSubtotal {
    double total = 0;
    for (var it in _items) {
      total += it.lineSubtotal;
    }
    return total;
  }

  double get _grandTotal {
    final sub = _itemsSubtotal;
    final disc = _parseNumber(_discountCtrl.text);
    final tax = _parseNumber(_taxCtrl.text);
    final ship = _parseNumber(_shippingCtrl.text);
    final total = sub - disc + tax + ship;
    return total > 0 ? total : 0;
  }

  Future<void> _pickDate({required bool isOrderDate}) async {
    final initialDate = isOrderDate ? _orderDate : (_expectedDate ?? _orderDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOrderDate) {
          _orderDate = picked;
          if (_expectedDate != null && _expectedDate!.isBefore(_orderDate)) {
            _expectedDate = _orderDate;
          }
        } else {
          _expectedDate = picked;
        }
      });
    }
  }

  void _showAddProductModal(List<ProductModel> products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final TextEditingController searchCtrl = TextEditingController();
            List<ProductModel> filtered = List.from(products);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Modal Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Produk yang Dipesan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Search box in modal
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (q) {
                          setModalState(() {
                            if (q.isEmpty) {
                              filtered = List.from(products);
                            } else {
                              filtered = products
                                  .where((p) => p.name.toLowerCase().contains(q.toLowerCase()))
                                  .toList();
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Cari produk / bahan baku...',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  // Products List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (c, idx) {
                        final p = filtered[idx];
                        final isAlreadyAdded = _items.any((it) => it.productId == p.id);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          title: Text(
                            p.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'HPP: ${CurrencyFormatter.format(p.costPrice)} • Satuan: ${p.unitName ?? 'Pcs'}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          trailing: isAlreadyAdded
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Sudah Ada', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _items.add(_POItemRow(
                                        productId: p.id,
                                        productName: p.name,
                                        unitId: p.baseUnitId ?? 1,
                                        unitName: p.unitName ?? 'Pcs',
                                        qtyCtrl: TextEditingController(text: '1'),
                                        priceCtrl: TextEditingController(text: CurrencyFormatter.formatNumber(p.costPrice)),
                                        discCtrl: TextEditingController(),
                                      ));
                                    });
                                    Navigator.pop(modalCtx);
                                  },
                                  child: const Text('+ Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pemasok / supplier terlebih dahulu.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gudang penerimaan terlebih dahulu.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 barang pada pesanan.'), backgroundColor: AppColors.error),
      );
      return;
    }

    for (var it in _items) {
      if (it.qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kuantiti barang "${it.productName}" harus lebih dari 0.'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'supplier_id': _selectedSupplierId,
      'warehouse_id': _selectedWarehouseId,
      'order_date': DateFormat('yyyy-MM-dd').format(_orderDate),
      'expected_date': _expectedDate != null ? DateFormat('yyyy-MM-dd').format(_expectedDate!) : null,
      'status': _selectedStatus,
      'discount_amount': _parseNumber(_discountCtrl.text),
      'tax_amount': _parseNumber(_taxCtrl.text),
      'shipping_cost': _parseNumber(_shippingCtrl.text),
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      'items': _items.map((it) => {
        'product_id': it.productId,
        'unit_id': it.unitId,
        'quantity_ordered': it.qty,
        'unit_price': it.price,
        'discount_percent': it.discPercent,
      }).toList(),
    };

    final provider = context.read<PurchasingProvider>();
    bool success = false;

    if (widget.order != null) {
      final res = await provider.updateOrder(widget.order!.id, payload);
      success = res != null;
    } else {
      final res = await provider.createOrder(payload);
      success = res != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.order != null ? 'Purchase Order berhasil diperbarui.' : 'Purchase Order baru berhasil dibuat.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan Purchase Order.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.order != null;
    final suppliers = context.watch<MasterDataProvider>().suppliers;
    final warehouses = context.watch<MasterDataProvider>().warehouses;
    final products = context.watch<MasterDataProvider>().products;
    final units = context.watch<MasterDataProvider>().units;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Purchase Order' : 'Buat Purchase Order (PO)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
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
              // Total summary in bottom bar
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PEMBELIAN',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                    ),
                    Text(
                      CurrencyFormatter.format(_grandTotal),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Submit button
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.check, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isEdit ? 'Perbarui PO' : 'Simpan PO',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ],
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
              // SECTION 1: INFORMASI UTAMA PO
              _buildCardSection(
                title: 'Informasi Pemasok & Pengiriman',
                icon: LucideIcons.truck,
                children: [
                  // Supplier Dropdown
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedSupplierId,
                    isExpanded: true,
                    decoration: _floatingInputDecoration(
                      label: 'Pemasok / Supplier *',
                      hint: 'Pilih Supplier',
                      prefixIcon: LucideIcons.truck,
                    ),
                    items: suppliers.map((s) {
                      return DropdownMenuItem<int?>(
                        value: s.id,
                        child: Text(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSupplierId = val),
                    validator: (v) => v == null ? 'Pemasok wajib dipilih' : null,
                  ),
                  const SizedBox(height: 14),

                  // Warehouse Dropdown
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedWarehouseId,
                    isExpanded: true,
                    decoration: _floatingInputDecoration(
                      label: 'Gudang Tujuan Penerimaan *',
                      hint: 'Pilih Gudang',
                      prefixIcon: LucideIcons.warehouse,
                    ),
                    items: warehouses.map((w) {
                      return DropdownMenuItem<int?>(
                        value: w.id,
                        child: Text(
                          '${w.name} ${w.isDefault ? '(Utama)' : ''}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedWarehouseId = val),
                    validator: (v) => v == null ? 'Gudang tujuan wajib dipilih' : null,
                  ),
                  const SizedBox(height: 14),

                  // Order & Expected Dates
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isOrderDate: true),
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: _floatingInputDecoration(
                              label: 'Tanggal Pesan *',
                              hint: 'Pilih Tanggal',
                              prefixIcon: LucideIcons.calendar,
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_orderDate),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isOrderDate: false),
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: _floatingInputDecoration(
                              label: 'Estimasi Datang',
                              hint: 'Tgl Datang',
                              prefixIcon: LucideIcons.calendarClock,
                            ),
                            child: Text(
                              _expectedDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_expectedDate!)
                                  : 'Belum Ditentukan',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _expectedDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Status PO Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    isExpanded: true,
                    decoration: _floatingInputDecoration(
                      label: 'Status Purchase Order *',
                      hint: 'Pilih Status',
                      prefixIcon: LucideIcons.flag,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'draft',
                        child: Text(
                          'Draft (Disimpan Sementara)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'sent',
                        child: Text(
                          'Sent (Terkirim ke Supplier)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 2: DAFTAR BARANG YANG DIPESAN
              _buildCardSection(
                title: 'Daftar Barang & Bahan Baku',
                icon: LucideIcons.package,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_items.length} item barang terdaftar',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          backgroundColor: const Color(0xFFEFF6FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showAddProductModal(products),
                        icon: const Icon(LucideIcons.plus, size: 14, color: Color(0xFF2563EB)),
                        label: const Text(
                          '+ Tambah Barang',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(LucideIcons.box, size: 30, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            const Text(
                              'Belum ada barang pada pesanan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tekan "+ Tambah Barang" untuk memilih produk dari katalog.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final item = _items[idx];
                        return _buildItemRowCard(item, idx, units);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 3: BIAYA TAMBAHAN & RINGKASAN
              _buildCardSection(
                title: 'Rincian Biaya & Catatan',
                icon: LucideIcons.calculator,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          onChanged: (_) => setState(() {}),
                          decoration: _floatingInputDecoration(
                            label: 'Diskon Faktur (Rp)',
                            hint: '0',
                            prefixIcon: LucideIcons.tag,
                            prefixText: 'Rp ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _taxCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          onChanged: (_) => setState(() {}),
                          decoration: _floatingInputDecoration(
                            label: 'Pajak / PPN (Rp)',
                            hint: '0',
                            prefixIcon: LucideIcons.receipt,
                            prefixText: 'Rp ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _shippingCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: _floatingInputDecoration(
                      label: 'Biaya Ongkos Kirim (Rp)',
                      hint: '0',
                      prefixIcon: LucideIcons.truck,
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: _floatingInputDecoration(
                      label: 'Catatan Pesanan',
                      hint: 'Instruksi pengiriman atau catatan untuk supplier...',
                      prefixIcon: LucideIcons.fileText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grand Total Live Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal Barang', CurrencyFormatter.format(_itemsSubtotal)),
                        if (_parseNumber(_discountCtrl.text) > 0)
                          _buildSummaryRow('Diskon Faktur', '- ${CurrencyFormatter.format(_parseNumber(_discountCtrl.text))}', isDiscount: true),
                        if (_parseNumber(_taxCtrl.text) > 0)
                          _buildSummaryRow('Pajak PPN', '+ ${CurrencyFormatter.format(_parseNumber(_taxCtrl.text))}'),
                        if (_parseNumber(_shippingCtrl.text) > 0)
                          _buildSummaryRow('Biaya Pengiriman', '+ ${CurrencyFormatter.format(_parseNumber(_shippingCtrl.text))}'),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                            Text(CurrencyFormatter.format(_grandTotal), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRowCard(_POItemRow item, int index, List units) {
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
          // Item Name & Delete Button
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _items.removeAt(index);
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.trash2, size: 13, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Qty & Unit
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: _floatingInputDecoration(
                    label: 'Kuantiti *',
                    hint: '1',
                    prefixIcon: LucideIcons.hash,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  initialValue: item.unitId,
                  isExpanded: true,
                  decoration: _floatingInputDecoration(
                    label: 'Satuan',
                    hint: 'Satuan',
                    prefixIcon: LucideIcons.scale,
                  ),
                  items: units.map<DropdownMenuItem<int>>((u) {
                    return DropdownMenuItem<int>(
                      value: u.id,
                      child: Text(u.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => item.unitId = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Unit Price & Discount %
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: item.priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: _floatingInputDecoration(
                    label: 'Harga Beli (Satuan) *',
                    hint: '0',
                    prefixIcon: LucideIcons.coins,
                    prefixText: 'Rp ',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.discCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: _floatingInputDecoration(
                    label: 'Diskon %',
                    hint: '0',
                    prefixIcon: LucideIcons.percent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal Item:', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              Text(
                CurrencyFormatter.format(item.lineSubtotal),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDiscount ? const Color(0xFF059669) : const Color(0xFF1E293B),
            ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
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
}
