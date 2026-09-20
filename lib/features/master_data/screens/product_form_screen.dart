import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/category_model.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/unit_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

// Helper class for dynamic Barcode Rows
class BarcodeRowData {
  int? unitId;
  final TextEditingController barcodeCtrl;

  BarcodeRowData({this.unitId, String barcode = ''})
      : barcodeCtrl = TextEditingController(text: barcode);

  void dispose() => barcodeCtrl.dispose();
}

// Helper class for dynamic Unit Conversion Rows
class ConversionRowData {
  int? fromUnitId;
  final TextEditingController ratioCtrl;

  ConversionRowData({this.fromUnitId, double ratio = 1.0})
      : ratioCtrl = TextEditingController(
          text: ratio == ratio.roundToDouble()
              ? ratio.toInt().toString()
              : ratio.toString(),
        );

  void dispose() => ratioCtrl.dispose();
}

// Helper class for dynamic Tiered Price Rows
class TieredPriceRowData {
  int? unitId;
  int? customerGroupId;
  final TextEditingController minQtyCtrl;
  final TextEditingController maxQtyCtrl;
  final TextEditingController priceCtrl;

  TieredPriceRowData({
    this.unitId,
    this.customerGroupId,
    double minQty = 1.0,
    double? maxQty,
    double price = 0.0,
  })  : minQtyCtrl = TextEditingController(
          text: minQty == minQty.roundToDouble()
              ? minQty.toInt().toString()
              : minQty.toString(),
        ),
        maxQtyCtrl = TextEditingController(
          text: maxQty != null
              ? (maxQty == maxQty.roundToDouble()
                  ? maxQty.toInt().toString()
                  : maxQty.toString())
              : '',
        ),
        priceCtrl = TextEditingController(
          text: price > 0 ? CurrencyFormatter.formatNumber(price) : '',
        );

  void dispose() {
    minQtyCtrl.dispose();
    maxQtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Basic Info Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _purchasePriceCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _descCtrl;

  int? _selectedCategoryId;
  int? _selectedBaseUnitId;
  String _selectedProductType = 'standard';
  bool _isActive = true;
  bool _isSaving = false;

  // Dynamic Lists for Clone Web Features
  final List<BarcodeRowData> _barcodeRows = [];
  final List<ConversionRowData> _conversionRows = [];
  final List<TieredPriceRowData> _tieredRows = [];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _codeCtrl = TextEditingController(text: p?.code ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _purchasePriceCtrl = TextEditingController(
      text: p != null ? CurrencyFormatter.formatNumber(p.costPrice) : '',
    );
    _sellingPriceCtrl = TextEditingController(
      text: p != null ? CurrencyFormatter.formatNumber(p.sellingPrice) : '',
    );
    _minStockCtrl = TextEditingController(text: '');
    _brandCtrl = TextEditingController(text: '');
    _descCtrl = TextEditingController(text: '');

    _selectedCategoryId = p?.categoryId;
    _selectedBaseUnitId = p?.baseUnitId;
    _isActive = true;

    // Populate existing multi-barcodes if editing
    if (p != null && p.barcodes.isNotEmpty) {
      for (final b in p.barcodes) {
        _barcodeRows.add(BarcodeRowData(unitId: b.unitId, barcode: b.barcode));
      }
    }

    // Populate existing conversions if editing
    if (p != null && p.conversions.isNotEmpty) {
      for (final c in p.conversions) {
        _conversionRows.add(
          ConversionRowData(
            fromUnitId: c.fromUnitId,
            ratio: c.conversionValue,
          ),
        );
      }
    }

    // Populate existing tiered prices if editing
    if (p != null && p.tieredPrices.isNotEmpty) {
      for (final tp in p.tieredPrices) {
        _tieredRows.add(
          TieredPriceRowData(
            unitId: tp.unitId,
            customerGroupId: tp.customerGroupId,
            minQty: tp.minQty,
            maxQty: tp.maxQty,
            price: tp.price,
          ),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MasterDataProvider>();
      if (provider.categories.isEmpty) provider.fetchCategories();
      if (provider.units.isEmpty) provider.fetchUnits();
      if (provider.customerGroups.isEmpty) provider.fetchCustomerGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _minStockCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();

    for (final r in _barcodeRows) {
      r.dispose();
    }
    for (final r in _conversionRows) {
      r.dispose();
    }
    for (final r in _tieredRows) {
      r.dispose();
    }

    super.dispose();
  }

  /// Helper untuk mendapatkan hanya satuan yang dikonfigurasikan pada produk ini (Satuan Dasar + Multi-Satuan)
  /// Sama persis seperti implementasi web `getProductConfiguredUnits`
  List<UnitModel> _getConfiguredUnits(MasterDataProvider provider, [int? currentUnitId]) {
    final configuredUnitIds = <int>{};

    // 1. Satuan dasar dari Tab 1
    if (_selectedBaseUnitId != null) {
      configuredUnitIds.add(_selectedBaseUnitId!);
    }

    // 2. Satuan konversi dari Tab 3
    for (final row in _conversionRows) {
      if (row.fromUnitId != null) {
        configuredUnitIds.add(row.fromUnitId!);
      }
    }

    // 3. Pastikan satuan baris yang sedang diedit tetap ada jika sudah terpilih
    if (currentUnitId != null) {
      configuredUnitIds.add(currentUnitId);
    }

    if (configuredUnitIds.isNotEmpty) {
      final filtered = provider.units.where((u) => configuredUnitIds.contains(u.id)).toList();
      if (filtered.isNotEmpty) return filtered;
    }

    return provider.units;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    if (_selectedBaseUnitId == null) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Satuan Dasar produk.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Format Barcodes Payload
    final barcodesPayload = _barcodeRows
        .where((r) => r.unitId != null && r.barcodeCtrl.text.trim().isNotEmpty)
        .map((r) => {
              'unit_id': r.unitId,
              'barcode': r.barcodeCtrl.text.trim(),
            })
        .toList();

    // Format Conversions Payload
    final conversionsPayload = _conversionRows
        .where((r) =>
            r.fromUnitId != null &&
            (double.tryParse(r.ratioCtrl.text.trim()) ?? 0) > 0)
        .map((r) => {
              'from_unit_id': r.fromUnitId,
              'to_unit_id': _selectedBaseUnitId,
              'conversion_value':
                  double.tryParse(r.ratioCtrl.text.trim()) ?? 1.0,
            })
        .toList();

    // Format Tiered Prices Payload
    final tieredPayload = _tieredRows
        .where((r) =>
            r.unitId != null &&
            CurrencyFormatter.parseCleanNumber(r.priceCtrl.text) > 0)
        .map((r) => {
              'unit_id': r.unitId,
              if (r.customerGroupId != null)
                'customer_group_id': r.customerGroupId,
              'min_qty': double.tryParse(r.minQtyCtrl.text.trim()) ?? 1.0,
              if (r.maxQtyCtrl.text.trim().isNotEmpty)
                'max_qty': double.tryParse(r.maxQtyCtrl.text.trim()),
              'price': CurrencyFormatter.parseCleanNumber(r.priceCtrl.text),
            })
        .toList();

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      if (_codeCtrl.text.trim().isNotEmpty) 'code': _codeCtrl.text.trim(),
      if (_barcodeCtrl.text.trim().isNotEmpty)
        'barcode': _barcodeCtrl.text.trim(),
      if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
      'base_unit_id': _selectedBaseUnitId,
      'purchase_price':
          CurrencyFormatter.parseCleanNumber(_purchasePriceCtrl.text),
      'selling_price':
          CurrencyFormatter.parseCleanNumber(_sellingPriceCtrl.text),
      if (_minStockCtrl.text.trim().isNotEmpty)
        'min_stock': double.tryParse(_minStockCtrl.text.trim()) ?? 0,
      if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
      if (_descCtrl.text.trim().isNotEmpty)
        'description': _descCtrl.text.trim(),
      'product_type': _selectedProductType,
      'is_active': _isActive,
      'barcodes': barcodesPayload,
      'conversions': conversionsPayload,
      'tiered_prices': tieredPayload,
    };

    final provider = context.read<MasterDataProvider>();
    ProductModel? res;

    if (isEditing) {
      res = await provider.updateProduct(widget.product!.id, data);
    } else {
      res = await provider.createProduct(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Produk "${res.name}" berhasil diperbarui!'
                : 'Produk "${res.name}" berhasil ditambahkan!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final err =
          provider.errorMessage ?? 'Terjadi kesalahan saat menyimpan data.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MasterDataProvider>();

    final List<CategoryModel> categoriesList = provider.categories;

    if (_selectedBaseUnitId == null && provider.units.isNotEmpty) {
      _selectedBaseUnitId = provider.units.first.id;
    }

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
          isEditing ? 'Edit Produk' : 'Tambah Produk Baru',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
              labelStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              indicatorColor: Colors.white,
              indicatorWeight: 3.0,
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 15),
                      SizedBox(width: 6),
                      Text('Info & Harga'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.scanLine, size: 15),
                      const SizedBox(width: 6),
                      Text('Multi-Barcode (${_barcodeRows.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.layers, size: 15),
                      const SizedBox(width: 6),
                      Text('Multi-Satuan (${_conversionRows.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.badgePercent, size: 15),
                      const SizedBox(width: 6),
                      Text('Multi-Harga (${_tieredRows.length})'),
                    ],
                  ),
                ),
              ],
            ),
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
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.check,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Perbarui Produk' : 'Simpan Produk',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabBasicInfo(categoriesList, provider),
            _buildTabMultiBarcode(provider),
            _buildTabMultiUnit(provider),
            _buildTabTieredPricing(provider),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: BASIC INFO
  // ==========================================
  Widget _buildTabBasicInfo(
      List<CategoryModel> categoriesList, MasterDataProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardSection(
            title: 'Informasi Utama Produk',
            icon: LucideIcons.package,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: _floatingInputDecoration(
                  label: 'Nama Produk *',
                  hint: 'Masukkan nama produk lengkap',
                  prefixIcon: LucideIcons.package,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama produk wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      decoration: _floatingInputDecoration(
                        label: 'Kode SKU',
                        hint: 'Auto-generate',
                        prefixIcon: LucideIcons.hash,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _floatingInputDecoration(
                        label: 'Barcode Utama',
                        hint: 'Scan / ketik barcode',
                        prefixIcon: LucideIcons.scan,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedCategoryId,
                      isExpanded: true,
                      decoration: _floatingInputDecoration(
                        label: 'Kategori Produk',
                        hint: 'Pilih Kategori',
                        prefixIcon: LucideIcons.tag,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tanpa Kategori (Umum)',
                              style: TextStyle(fontSize: 12)),
                        ),
                        ...categoriesList.map(
                          (cat) => DropdownMenuItem<int?>(
                            value: cat.id,
                            child: Text(cat.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedCategoryId = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedBaseUnitId,
                      isExpanded: true,
                      decoration: _floatingInputDecoration(
                        label: 'Satuan Terkecil *',
                        hint: 'Pilih Satuan',
                        prefixIcon: LucideIcons.scale,
                      ),
                      items: provider.units
                          .map(
                            (u) => DropdownMenuItem<int>(
                              value: u.id,
                              child: Text(u.displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBaseUnitId = val),
                      validator: (val) =>
                          val == null ? 'Satuan dasar wajib dipilih' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildCardSection(
            title: 'Penetapan Harga Satuan Dasar',
            icon: LucideIcons.dollarSign,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: _floatingInputDecoration(
                        label: 'Harga Beli (HPP) *',
                        hint: '0',
                        prefixText: 'Rp ',
                        prefixIcon: LucideIcons.coins,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'HPP wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: _floatingInputDecoration(
                        label: 'Harga Jual Kasir *',
                        hint: '0',
                        prefixText: 'Rp ',
                        prefixIcon: LucideIcons.badgePercent,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Harga jual wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _floatingInputDecoration(
                        label: 'Min. Stok Peringatan',
                        hint: 'Contoh: 5',
                        prefixIcon: LucideIcons.alertCircle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _brandCtrl,
                      decoration: _floatingInputDecoration(
                        label: 'Merek / Brand',
                        hint: 'Contoh: Unilever',
                        prefixIcon: LucideIcons.badgeCheck,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildCardSection(
            title: 'Tipe & Pengaturan',
            icon: LucideIcons.sliders,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedProductType,
                isExpanded: true,
                decoration: _floatingInputDecoration(
                  label: 'Tipe Produk',
                  hint: 'Pilih Tipe',
                  prefixIcon: LucideIcons.layers,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'standard',
                      child: Text('Barang Fisik / Standar',
                          style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(
                      value: 'food',
                      child: Text('Makanan (Food)',
                          style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(
                      value: 'beverage',
                      child: Text('Minuman (Beverage)',
                          style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(
                      value: 'service',
                      child: Text('Jasa / Layanan (Service)',
                          style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProductType = val);
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: _floatingInputDecoration(
                  label: 'Deskripsi / Catatan',
                  hint: 'Keterangan produk tambahan...',
                  prefixIcon: LucideIcons.fileText,
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Produk Aktif',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tampilkan di kasir dan katalog POS',
                          style: TextStyle(
                              fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MULTI BARCODE
  // ==========================================
  Widget _buildTabMultiBarcode(MasterDataProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.scanLine, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Barcode tambahan berbeda untuk setiap kemasan / satuan (Contoh: Barcode 1 Dus vs Barcode 1 Pcs). Kasir langsung otomatis mendeteksi satuan yang sesuai saat scan.',
                    style: TextStyle(
                        fontSize: 11.5, color: Color(0xFF92400E), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Barcode Tambahan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () {
                  final configured = _getConfiguredUnits(provider);
                  setState(() {
                    _barcodeRows.add(
                      BarcodeRowData(
                        unitId: _selectedBaseUnitId ??
                            (configured.isNotEmpty
                                ? configured.first.id
                                : null),
                      ),
                    );
                  });
                },
                icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                label: const Text(
                  'Tambah Barcode',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_barcodeRows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.scan, size: 36, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada barcode tambahan',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gunakan jika barang memiliki kemasan multipack/dus dengan barcode berbeda',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _barcodeRows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final row = _barcodeRows[idx];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '#${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Barcode Satuan Tambahan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                row.dispose();
                                _barcodeRows.removeAt(idx);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.trash2,
                                      size: 14, color: Color(0xFFEF4444)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                          height: 18, thickness: 0.8, color: Color(0xFFF1F5F9)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: DropdownButtonFormField<int>(
                              initialValue: row.unitId,
                              isExpanded: true,
                              decoration: _floatingInputDecoration(
                                label: 'Satuan Jual *',
                                hint: 'Pilih Satuan',
                                prefixIcon: LucideIcons.scale,
                              ),
                              items: _getConfiguredUnits(provider, row.unitId)
                                  .map(
                                    (u) => DropdownMenuItem<int>(
                                      value: u.id,
                                      child: Text(
                                        u.id == _selectedBaseUnitId
                                            ? '${u.name} (Dasar)'
                                            : u.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => row.unitId = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              controller: row.barcodeCtrl,
                              decoration: _floatingInputDecoration(
                                label: 'Kode Barcode *',
                                hint: 'Scan / ketik barcode',
                                prefixIcon: LucideIcons.scan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: MULTI SATUAN (CONVERSIONS)
  // ==========================================
  Widget _buildTabMultiUnit(MasterDataProvider provider) {
    final baseUnitMatches = provider.units.where((u) => u.id == _selectedBaseUnitId);
    final baseName = baseUnitMatches.isNotEmpty ? baseUnitMatches.first.name : 'Pcs';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.layers, color: Color(0xFF0D9488), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Konversi satuan bertingkat. 1 Satuan Besar = Berapa Satuan Terkecil ($baseName)? Contoh: 1 Dus = 40 $baseName, 1 Pak = 10 $baseName.',
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF115E59), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Multi-Satuan (Konversi)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _conversionRows.add(
                      ConversionRowData(
                        fromUnitId: provider.units
                            .firstWhere((u) => u.id != _selectedBaseUnitId,
                                orElse: () => provider.units.first)
                            .id,
                        ratio: 10.0,
                      ),
                    );
                  });
                },
                icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                label: const Text(
                  'Tambah Satuan',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_conversionRows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.scale, size: 36, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada multi-satuan',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Produk saat ini hanya dijual dalam satuan dasar saja',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _conversionRows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final row = _conversionRows[idx];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '#${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Rumus Konversi Satuan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                row.dispose();
                                _conversionRows.removeAt(idx);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.trash2,
                                      size: 14, color: Color(0xFFEF4444)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                          height: 18, thickness: 0.8, color: Color(0xFFF1F5F9)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: DropdownButtonFormField<int>(
                              initialValue: row.fromUnitId,
                              isExpanded: true,
                              decoration: _floatingInputDecoration(
                                label: '1 Satuan Besar *',
                                hint: 'Pilih Satuan',
                                prefixIcon: LucideIcons.package,
                              ),
                              items: provider.units
                                  .map(
                                    (u) => DropdownMenuItem<int>(
                                      value: u.id,
                                      child: Text(u.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => row.fromUnitId = val),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 14, left: 6, right: 6),
                            child: Text('=',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF94A3B8))),
                          ),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: row.ratioCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: _floatingInputDecoration(
                                label: 'Isi ($baseName) *',
                                hint: '40',
                                prefixIcon: LucideIcons.hash,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: MULTI HARGA (TIERED PRICING)
  // ==========================================
  Widget _buildTabTieredPricing(MasterDataProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.badgePercent,
                    color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Harga grosir bertingkat (Tier). Contoh: Beli ≥ 12 Pcs harga jadi Rp 2.500, atau harga khusus untuk Customer Member VIP.',
                    style: TextStyle(
                        fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Harga Grosir / Berjenjang',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () {
                  final configured = _getConfiguredUnits(provider);
                  setState(() {
                    _tieredRows.add(
                      TieredPriceRowData(
                        unitId: _selectedBaseUnitId ??
                            (configured.isNotEmpty
                                ? configured.first.id
                                : null),
                        minQty: 10.0,
                        price: (CurrencyFormatter.parseCleanNumber(
                                    _sellingPriceCtrl.text)) *
                            0.9,
                      ),
                    );
                  });
                },
                icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                label: const Text(
                  'Tambah Tier',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_tieredRows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.tag, size: 36, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada harga grosir / tier',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kasir akan selalu menggunakan harga jual standar untuk transaksi',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tieredRows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final row = _tieredRows[idx];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '#${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Konfigurasi Tier Grosir',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                row.dispose();
                                _tieredRows.removeAt(idx);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.trash2,
                                      size: 14, color: Color(0xFFEF4444)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                          height: 18, thickness: 0.8, color: Color(0xFFF1F5F9)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: row.unitId,
                              isExpanded: true,
                              decoration: _floatingInputDecoration(
                                label: 'Satuan Jual *',
                                hint: 'Pilih Satuan',
                                prefixIcon: LucideIcons.scale,
                              ),
                              items: _getConfiguredUnits(provider, row.unitId)
                                  .map(
                                    (u) => DropdownMenuItem<int>(
                                      value: u.id,
                                      child: Text(
                                        u.id == _selectedBaseUnitId
                                            ? '${u.displayName} (Dasar)'
                                            : u.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => row.unitId = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              initialValue: row.customerGroupId,
                              isExpanded: true,
                              decoration: _floatingInputDecoration(
                                label: 'Target Pelanggan',
                                hint: 'Semua Pelanggan',
                                prefixIcon: LucideIcons.users,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Semua Pelanggan',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                ...provider.customerGroups.map(
                                  (g) => DropdownMenuItem<int?>(
                                    value: g['id'] as int?,
                                    child: Text(g['name']?.toString() ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => row.customerGroupId = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: row.minQtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _floatingInputDecoration(
                                label: 'Min Qty *',
                                hint: '10',
                                prefixIcon: LucideIcons.layers,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: row.maxQtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _floatingInputDecoration(
                                label: 'Maks Qty',
                                hint: 'Tak terhingga',
                                prefixIcon: LucideIcons.infinity,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 7,
                            child: TextFormField(
                              controller: row.priceCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                ThousandsSeparatorInputFormatter(),
                              ],
                              decoration: _floatingInputDecoration(
                                label: 'Harga Khusus *',
                                hint: '0',
                                prefixText: 'Rp ',
                                prefixIcon: LucideIcons.coins,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
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
            color: Color(0xFF475569), // slate-600
          ),
          children: isReq
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFEF4444), // rose-500
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
