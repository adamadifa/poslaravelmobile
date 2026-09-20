import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/discount_model.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class DiscountFormScreen extends StatefulWidget {
  final DiscountModel? discount;

  const DiscountFormScreen({super.key, this.discount});

  @override
  State<DiscountFormScreen> createState() => _DiscountFormScreenState();
}

class _DiscountFormScreenState extends State<DiscountFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _buyQtyCtrl;
  late TextEditingController _getQtyCtrl;
  late TextEditingController _descCtrl;

  String _selectedType = 'percentage_item';
  int? _selectedCustomerGroupId;
  int? _selectedRewardProductId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCombinable = false;
  bool _isActive = true;
  List<int> _selectedProductIds = [];

  bool _isSubmitting = false;

  final List<Map<String, String>> _types = [
    {'key': 'percentage_item', 'label': 'Diskon % per Item'},
    {'key': 'fixed_item', 'label': 'Potongan Rp per Item'},
    {'key': 'percentage_invoice', 'label': 'Diskon % Total Nota'},
    {'key': 'fixed_invoice', 'label': 'Potongan Rp Total Nota'},
    {'key': 'buy_x_get_y', 'label': 'Buy X Get Y (Beli X Dapat Y)'},
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.discount;

    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _codeCtrl = TextEditingController(text: d?.code ?? '');
    _descCtrl = TextEditingController(text: d?.description ?? '');

    if (d != null) {
      _selectedType = d.type;
      _valueCtrl = TextEditingController(
        text: d.value > 0
            ? (d.type.contains('percentage')
                ? d.value.toStringAsFixed(d.value.truncateToDouble() == d.value ? 0 : 1)
                : CurrencyFormatter.formatNumber(d.value))
            : '',
      );
      _minOrderCtrl = TextEditingController(
        text: d.minOrderAmount > 0 ? CurrencyFormatter.formatNumber(d.minOrderAmount) : '',
      );
      _maxDiscountCtrl = TextEditingController(
        text: d.maxDiscountAmount > 0 ? CurrencyFormatter.formatNumber(d.maxDiscountAmount) : '',
      );
      _buyQtyCtrl = TextEditingController(
        text: d.buyQty > 0 ? d.buyQty.toStringAsFixed(0) : '1',
      );
      _getQtyCtrl = TextEditingController(
        text: d.getQty > 0 ? d.getQty.toStringAsFixed(0) : '1',
      );
      _selectedCustomerGroupId = d.customerGroupId;
      _selectedRewardProductId = d.rewardProductId;
      _isCombinable = d.isCombinable;
      _isActive = d.isActive;
      _selectedProductIds = List<int>.from(d.productIds);

      if (d.startDate != null && d.startDate!.isNotEmpty) {
        _startDate = DateTime.tryParse(d.startDate!);
      }
      if (d.endDate != null && d.endDate!.isNotEmpty) {
        _endDate = DateTime.tryParse(d.endDate!);
      }
    } else {
      _valueCtrl = TextEditingController();
      _minOrderCtrl = TextEditingController();
      _maxDiscountCtrl = TextEditingController();
      _buyQtyCtrl = TextEditingController(text: '1');
      _getQtyCtrl = TextEditingController(text: '1');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchCustomerGroups();
      context.read<MasterDataProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _buyQtyCtrl.dispose();
    _getQtyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  double _parseNumber(String text) {
    if (text.isEmpty) return 0;
    final cleaned = text.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
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
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  void _showProductSelectorModal(List<ProductModel> products) {
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pilih Produk Promo',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${_selectedProductIds.length} produk terpilih',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
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
                          hintText: 'Cari produk...',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  // Product list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (c, idx) {
                        final p = filtered[idx];
                        final isSelected = _selectedProductIds.contains(p.id);
                        return CheckboxListTile(
                          activeColor: AppColors.primary,
                          dense: true,
                          value: isSelected,
                          title: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            CurrencyFormatter.format(p.sellingPrice),
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                _selectedProductIds.add(p.id);
                              } else {
                                _selectedProductIds.remove(p.id);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),

                  // Bottom Done Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(modalCtx),
                        child: const Text(
                          'Selesai Memilih',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
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

    setState(() => _isSubmitting = true);

    final isPercentage = _selectedType.contains('percentage');
    final isBuyXGetY = _selectedType == 'buy_x_get_y';

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim().isNotEmpty ? _codeCtrl.text.trim().toUpperCase() : null,
      'type': _selectedType,
      'value': !isBuyXGetY ? _parseNumber(_valueCtrl.text) : 0,
      'min_order_amount': _parseNumber(_minOrderCtrl.text),
      'max_discount_amount': isPercentage ? _parseNumber(_maxDiscountCtrl.text) : 0,
      'buy_qty': isBuyXGetY ? _parseNumber(_buyQtyCtrl.text) : null,
      'get_qty': isBuyXGetY ? _parseNumber(_getQtyCtrl.text) : null,
      'reward_product_id': isBuyXGetY ? _selectedRewardProductId : null,
      'customer_group_id': _selectedCustomerGroupId,
      'start_date': _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      'end_date': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      'is_combinable': _isCombinable,
      'is_active': _isActive,
      'description': _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      'product_ids': _selectedProductIds,
    };

    final provider = context.read<MasterDataProvider>();
    bool success = false;

    if (widget.discount != null) {
      final res = await provider.updateDiscount(widget.discount!.id, data);
      success = res != null;
    } else {
      final res = await provider.createDiscount(data);
      success = res != null;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.discount != null ? 'Promo berhasil diperbarui.' : 'Promo baru berhasil ditambahkan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan promo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.discount != null;
    final isPercentage = _selectedType.contains('percentage');
    final isBuyXGetY = _selectedType == 'buy_x_get_y';
    final isItemBased = _selectedType == 'percentage_item' || _selectedType == 'fixed_item' || isBuyXGetY;

    final customerGroups = context.watch<MasterDataProvider>().customerGroups;
    final products = context.watch<MasterDataProvider>().products;

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
          isEdit ? 'Edit Promo & Diskon' : 'Tambah Promo & Diskon',
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
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.check, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? 'Perbarui Promo' : 'Simpan Promo',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: INFORMASI UTAMA PROMO
              _buildCardSection(
                title: 'Informasi Utama Promo',
                icon: LucideIcons.badgePercent,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _floatingInputDecoration(
                      label: 'Nama Promo / Diskon *',
                      hint: 'cth: Diskon Gajian 15% atau Promo Member VIP',
                      prefixIcon: LucideIcons.badgePercent,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama promo wajib diisi';
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
                            label: 'Kode Kupon',
                            hint: 'cth: GAJIAN15',
                            prefixIcon: LucideIcons.ticket,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          isExpanded: true,
                          decoration: _floatingInputDecoration(
                            label: 'Tipe Promo *',
                            hint: 'Pilih Tipe',
                            prefixIcon: LucideIcons.layers,
                          ),
                          items: _types.map((t) {
                            return DropdownMenuItem<String>(
                              value: t['key'],
                              child: Text(
                                t['label']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedType = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 2: NILAI POTONGAN & KETENTUAN
              _buildCardSection(
                title: 'Nilai Potongan & Syarat Belanja',
                icon: LucideIcons.dollarSign,
                children: [
                  if (!isBuyXGetY) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _valueCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: isPercentage
                                ? []
                                : [ThousandsSeparatorInputFormatter()],
                            decoration: _floatingInputDecoration(
                              label: isPercentage ? 'Besaran Diskon (%) *' : 'Nominal Potongan (Rp) *',
                              hint: isPercentage ? '15' : '15.000',
                              prefixIcon: isPercentage ? LucideIcons.percent : LucideIcons.coins,
                              prefixText: isPercentage ? null : 'Rp ',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Nilai potongan wajib diisi';
                              final num = _parseNumber(v);
                              if (num <= 0) return 'Nilai harus > 0';
                              if (isPercentage && num > 100) return 'Maksimal 100%';
                              return null;
                            },
                          ),
                        ),
                        if (isPercentage) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _maxDiscountCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [ThousandsSeparatorInputFormatter()],
                              decoration: _floatingInputDecoration(
                                label: 'Maks. Diskon (Rp)',
                                hint: 'Tanpa batas',
                                prefixIcon: LucideIcons.shieldAlert,
                                prefixText: 'Rp ',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    // Buy X Get Y Qty Inputs
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _buyQtyCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _floatingInputDecoration(
                              label: 'Beli Jumlah (Qty) *',
                              hint: '2',
                              prefixIcon: LucideIcons.shoppingBag,
                            ),
                            validator: (v) => _parseNumber(v ?? '') <= 0 ? 'Min 1' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _getQtyCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _floatingInputDecoration(
                              label: 'Gratis Jumlah (Qty) *',
                              hint: '1',
                              prefixIcon: LucideIcons.gift,
                            ),
                            validator: (v) => _parseNumber(v ?? '') <= 0 ? 'Min 1' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<int?>(
                      initialValue: _selectedRewardProductId,
                      isExpanded: true,
                      decoration: _floatingInputDecoration(
                        label: 'Produk Hadiah Gratis',
                        hint: 'Sama dengan produk dibeli',
                        prefixIcon: LucideIcons.gift,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sama dengan produk dibeli', style: TextStyle(fontSize: 12)),
                        ),
                        ...products.map((p) {
                          return DropdownMenuItem<int?>(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }),
                      ],
                      onChanged: (val) => setState(() => _selectedRewardProductId = val),
                    ),
                    const SizedBox(height: 14),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minOrderCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: _floatingInputDecoration(
                            label: 'Min. Belanja (Rp)',
                            hint: '0',
                            prefixIcon: LucideIcons.shoppingCart,
                            prefixText: 'Rp ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _selectedCustomerGroupId,
                          isExpanded: true,
                          decoration: _floatingInputDecoration(
                            label: 'Target Pelanggan',
                            hint: 'Semua',
                            prefixIcon: LucideIcons.users,
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Semua Pelanggan', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                            ),
                            ...customerGroups.map((g) {
                              return DropdownMenuItem<int?>(
                                value: g['id'],
                                child: Text(
                                  '${g['name']} (${g['discount_percent'] ?? 0}%)',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) => setState(() => _selectedCustomerGroupId = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 3: PRODUK KHUSUS (Jika Item-Based)
              if (isItemBased) ...[
                _buildCardSection(
                  title: 'Produk Tertarget',
                  icon: LucideIcons.box,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedProductIds.isEmpty
                              ? 'Berlaku untuk SEMUA produk'
                              : '${_selectedProductIds.length} produk khusus terpilih',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedProductIds.isEmpty ? const Color(0xFF64748B) : AppColors.primary,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            backgroundColor: const Color(0xFFEFF6FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showProductSelectorModal(products),
                          icon: const Icon(LucideIcons.plus, size: 14, color: Color(0xFF2563EB)),
                          label: Text(
                            _selectedProductIds.isEmpty ? 'Pilih Produk' : 'Ubah Produk',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedProductIds.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedProductIds.map((pId) {
                          final p = products.firstWhere(
                            (prod) => prod.id == pId,
                            orElse: () => ProductModel(
                              id: pId,
                              name: 'Produk #$pId',
                              costPrice: 0,
                              sellingPrice: 0,
                              stock: 0,
                            ),
                          );
                          return Chip(
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            backgroundColor: const Color(0xFFF1F5F9),
                            deleteIcon: const Icon(LucideIcons.x, size: 12, color: Color(0xFF64748B)),
                            onDeleted: () {
                              setState(() {
                                _selectedProductIds.remove(pId);
                              });
                            },
                            label: Text(
                              p.name,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // SECTION 4: PERIODE & PENGATURAN
              _buildCardSection(
                title: 'Masa Berlaku & Pengaturan',
                icon: LucideIcons.calendar,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: true),
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: _floatingInputDecoration(
                              label: 'Tanggal Mulai',
                              hint: 'Langsung Aktif',
                              prefixIcon: LucideIcons.calendar,
                            ),
                            child: Text(
                              _startDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                  : 'Langsung Aktif',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _startDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: false),
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: _floatingInputDecoration(
                              label: 'Tanggal Berakhir',
                              hint: 'Tanpa Batas',
                              prefixIcon: LucideIcons.calendar,
                            ),
                            child: Text(
                              _endDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                  : 'Tanpa Batas',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _endDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Switch Combinable
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Dapat Digabung Promo Lain',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    subtitle: const Text(
                      'Izinkan kasir memasang kupon ini bersama diskon manual atau promo lainnya.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: _isCombinable,
                    onChanged: (val) => setState(() => _isCombinable = val),
                  ),
                  const Divider(height: 12, color: Color(0xFFF1F5F9)),

                  // Switch Active
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Status Promo Aktif',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    subtitle: const Text(
                      'Promo dapat dipilih dan diterapkan pada saat transaksi kasir.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _floatingInputDecoration(
                      label: 'Catatan / Syarat Ketentuan',
                      hint: 'Tuliskan rincian promo untuk informasi kasir...',
                      prefixIcon: LucideIcons.fileText,
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
