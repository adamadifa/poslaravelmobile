import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/stock_batch_model.dart';
import 'package:poslaravelmobile/data/models/stock_movement_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class StockCardScreen extends StatefulWidget {
  final int? initialProductId;
  final int? initialWarehouseId;

  const StockCardScreen({
    super.key,
    this.initialProductId,
    this.initialWarehouseId,
  });

  @override
  State<StockCardScreen> createState() => _StockCardScreenState();
}

class _StockCardScreenState extends State<StockCardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProv = context.read<StockProvider>();
      final masterProv = context.read<MasterDataProvider>();

      masterProv.fetchWarehouses();
      masterProv.fetchProducts();
      masterProv.fetchRawMaterials();

      if (widget.initialProductId != null) {
        stockProv.setProductFilter(widget.initialProductId);
        _tabController.index = 2; // Jump to per-product tab
      }
      if (widget.initialWarehouseId != null) {
        stockProv.setWarehouseFilter(widget.initialWarehouseId);
      }

      stockProv.refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    final masterProv = context.read<MasterDataProvider>();
    final stockProv = context.read<StockProvider>();
    final warehouses = masterProv.warehouses;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.filter, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter Kartu Stok',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            stockProv.clearFilters();
                            _searchCtrl.clear();
                            Navigator.pop(modalCtx);
                          },
                          child: const Text('Reset', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Warehouse filter
                    const Text('Gudang / Lokasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: warehouses.any((w) => w.id == stockProv.selectedWarehouseId)
                          ? stockProv.selectedWarehouseId
                          : null,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      hint: const Text('Semua Gudang / Cabang', style: TextStyle(fontSize: 12.5)),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Semua Gudang', style: TextStyle(fontSize: 13))),
                        ...warehouses.map((w) => DropdownMenuItem<int?>(value: w.id, child: Text(w.name, style: const TextStyle(fontSize: 13)))),
                      ],
                      onChanged: (val) {
                        stockProv.setWarehouseFilter(val);
                        setModalState(() {});
                      },
                    ),

                    const SizedBox(height: 14),

                    // Date Filter Section (Aligned with Web Kartu Stok Dari & Sampai Tanggal)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rentang Periode Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        if (stockProv.startDate != null || stockProv.endDate != null)
                          GestureDetector(
                            onTap: () {
                              stockProv.setDateRange(null, null);
                              setModalState(() {});
                            },
                            child: const Text('Hapus Tanggal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quick Date Preset Chips
                    Row(
                      children: [
                        _buildDatePresetChip('Hari Ini', () {
                          final now = DateTime.now();
                          stockProv.setDateRange(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day));
                          setModalState(() {});
                        }, _isTodayRange(stockProv.startDate, stockProv.endDate)),
                        const SizedBox(width: 6),
                        _buildDatePresetChip('7 Hari', () {
                          final now = DateTime.now();
                          stockProv.setDateRange(now.subtract(const Duration(days: 6)), now);
                          setModalState(() {});
                        }, _is7DaysRange(stockProv.startDate, stockProv.endDate)),
                        const SizedBox(width: 6),
                        _buildDatePresetChip('Bulan Ini', () {
                          final now = DateTime.now();
                          stockProv.setDateRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
                          setModalState(() {});
                        }, _isThisMonthRange(stockProv.startDate, stockProv.endDate)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Custom Date Picker Trigger
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: stockProv.startDate != null && stockProv.endDate != null
                              ? DateTimeRange(start: stockProv.startDate!, end: stockProv.endDate!)
                              : null,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (c, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFFEA580C),
                                  onPrimary: Colors.white,
                                  onSurface: Color(0xFF1E293B),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          stockProv.setDateRange(picked.start, picked.end);
                          setModalState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stockProv.startDate != null && stockProv.endDate != null
                                    ? '${stockProv.startDate!.day}/${stockProv.startDate!.month}/${stockProv.startDate!.year} - ${stockProv.endDate!.day}/${stockProv.endDate!.month}/${stockProv.endDate!.year}'
                                    : 'Pilih rentang tanggal khusus (Dari - Sampai)...',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: stockProv.startDate != null ? FontWeight.w700 : FontWeight.w500,
                                  color: stockProv.startDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Product type filter tabs
                    const Text('Kategori Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTypeChip('Produk Jadi', 'products', stockProv.productTypeTab, (t) {
                          stockProv.setProductTypeTab(t);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 8),
                        _buildTypeChip('Bahan Baku (Raw)', 'raw_materials', stockProv.productTypeTab, (t) {
                          stockProv.setProductTypeTab(t);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 8),
                        _buildTypeChip('Semua Item', 'all', stockProv.productTypeTab, (t) {
                          stockProv.setProductTypeTab(t);
                          setModalState(() {});
                        }),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(modalCtx),
                        child: const Text('Terapkan Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isTodayRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return start.year == now.year && start.month == now.month && start.day == now.day &&
           end.year == now.year && end.month == now.month && end.day == now.day;
  }

  bool _is7DaysRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    final now = DateTime.now();
    final diff = end.difference(start).inDays;
    return (diff == 6 || diff == 7) && end.day == now.day && end.month == now.month && end.year == now.year;
  }

  bool _isThisMonthRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return start.year == now.year && start.month == now.month && start.day == 1 &&
           end.year == now.year && end.month == now.month;
  }

  Widget _buildDatePresetChip(String label, VoidCallback onTap, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, String selectedVal, Function(String) onTap) {
    final isSelected = selectedVal == value;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTabChip(String label, String value, String selectedVal, Function(String) onTap) {
    final isSelected = selectedVal == value;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.white : Colors.white30),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFFEA580C) : Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatQty(num? val) {
    if (val == null) return '0';
    final double d = val.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _showMovementDetail(StockMovementModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: item.typeBgColor, borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.isIncoming ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, color: item.typeColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            'Mutasi ${item.typeLabel} • ${item.createdAt}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Info Rows
                _buildInfoRow('Jumlah Mutasi', '${item.isIncoming ? '+' : '-'}${_formatQty(item.quantity)} ${item.unitName}', isBold: true, highlightColor: item.typeColor),
                const SizedBox(height: 8),
                _buildInfoRow('Perubahan Stok', '${_formatQty(item.beforeStock)} ${item.unitName} ➔ ${_formatQty(item.afterStock)} ${item.unitName}'),
                const SizedBox(height: 8),
                _buildInfoRow('Harga Pokok / HPP', CurrencyFormatter.format(item.unitCost)),
                const SizedBox(height: 8),
                _buildInfoRow('Total Nilai Mutasi', CurrencyFormatter.format(item.quantity * item.unitCost), isBold: true),
                const SizedBox(height: 8),
                _buildInfoRow('Jenis Referensi', item.referenceTypeLabel),
                const SizedBox(height: 8),
                _buildInfoRow('Lokasi Gudang', item.warehouseName),
                if (item.creatorName != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Dicatat Oleh', item.creatorName!),
                ],
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Keterangan', item.description!),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: highlightColor ?? const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEA580C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kartu Stok & Alokasi FIFO',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Audit mutasi persediaan & alokasi batch masuk/keluar',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter, color: Colors.white, size: 19),
            tooltip: 'Filter',
            onPressed: () => _showFilterModal(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
            tooltip: 'Segarkan',
            onPressed: () => stockProv.refreshAll(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(138),
          child: Column(
            children: [
              // Search input
              Container(
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  onChanged: (val) => stockProv.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Cari produk, SKU, nomor batch, referensi...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchCtrl.clear();
                              stockProv.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),

              // Quick Category Filter Pills
              Container(
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildQuickTabChip('Semua Item', 'all', stockProv.productTypeTab, (t) => stockProv.setProductTypeTab(t)),
                    const SizedBox(width: 6),
                    _buildQuickTabChip('Produk Jadi', 'products', stockProv.productTypeTab, (t) => stockProv.setProductTypeTab(t)),
                    const SizedBox(width: 6),
                    _buildQuickTabChip('Bahan Baku (Raw)', 'raw_materials', stockProv.productTypeTab, (t) => stockProv.setProductTypeTab(t)),
                  ],
                ),
              ),

              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                tabs: const [
                  Tab(text: 'Mutasi Stok'),
                  Tab(text: 'Batch FIFO Aktif'),
                  Tab(text: 'Per Produk'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMovementsTab(stockProv),
          _buildBatchesTab(stockProv),
          _buildPerProductTab(stockProv),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: STOCK MOVEMENTS (MUTASI STOK)
  // ==========================================
  Widget _buildMovementsTab(StockProvider stockProv) {
    if (stockProv.isLoading && stockProv.movements.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final movements = stockProv.movements;
    final summary = stockProv.summary;

    return RefreshIndicator(
      onRefresh: () => stockProv.fetchMovements(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: [
          // KPI Summary Cards
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL MASUK (+)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669), letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(
                        '+${_formatQty(summary.totalIn)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                ),
                Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL KELUAR (-)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626), letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(
                        '-${_formatQty(summary.totalOut)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
                if (summary.currentStock != null) ...[
                  Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SALDO STOK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(
                          _formatQty(summary.currentStock),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Active Filter / Date Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stockProv.startDate != null && stockProv.endDate != null
                        ? 'Periode: ${stockProv.startDate!.day}/${stockProv.startDate!.month}/${stockProv.startDate!.year} - ${stockProv.endDate!.day}/${stockProv.endDate!.month}/${stockProv.endDate!.year}'
                        : 'Periode: Semua Riwayat Tanggal',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: stockProv.startDate != null && stockProv.endDate != null
                          ? DateTimeRange(start: stockProv.startDate!, end: stockProv.endDate!)
                          : null,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (c, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFFEA580C),
                              onPrimary: Colors.white,
                              onSurface: Color(0xFF1E293B),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      stockProv.setDateRange(picked.start, picked.end);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text('Ubah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFEA580C))),
                  ),
                ),
                if (stockProv.startDate != null || stockProv.endDate != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => stockProv.setDateRange(null, null),
                    child: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Movement type quick filter pills
          Row(
            children: [
              _buildMovementPill('Semua Mutasi', 'all', stockProv.movementType, (t) => stockProv.setMovementTypeFilter(t)),
              const SizedBox(width: 8),
              _buildMovementPill('Masuk (+)', 'in', stockProv.movementType, (t) => stockProv.setMovementTypeFilter(t), activeColor: const Color(0xFF059669)),
              const SizedBox(width: 8),
              _buildMovementPill('Keluar (-)', 'out', stockProv.movementType, (t) => stockProv.setMovementTypeFilter(t), activeColor: const Color(0xFFDC2626)),
            ],
          ),

          const SizedBox(height: 14),

          if (movements.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(30)),
                      child: const Icon(LucideIcons.boxes, size: 28, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Belum ada riwayat mutasi stok.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    const Text('Mutasi akan otomatis tercatat saat penjualan, penerimaan, retur, atau transfer.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            )
          else
            ...movements.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildMovementCard(m),
                )),
        ],
      ),
    );
  }

  Widget _buildMovementPill(String label, String value, String selectedVal, Function(String) onTap, {Color? activeColor}) {
    final isSelected = selectedVal == value;
    final color = activeColor ?? AppColors.primary;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovementCard(StockMovementModel item) {
    return InkWell(
      onTap: () => _showMovementDetail(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: item.typeBgColor, borderRadius: BorderRadius.circular(8)),
                  child: Icon(
                    item.isIncoming ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                    color: item.typeColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.referenceTypeLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.isIncoming ? '+' : '-'}${_formatQty(item.quantity)} ${item.unitName}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: item.typeColor),
                    ),
                    Text(
                      CurrencyFormatter.format(item.unitCost),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF8FAFC)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(LucideIcons.warehouse, size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.warehouseName,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Saldo: ${_formatQty(item.beforeStock)} ➔ ${_formatQty(item.afterStock)} ${item.unitName}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: ACTIVE FIFO BATCHES
  // ==========================================
  Widget _buildBatchesTab(StockProvider stockProv) {
    if (stockProv.isLoading && stockProv.batches.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final batches = stockProv.batches;

    return RefreshIndicator(
      onRefresh: () => stockProv.fetchBatches(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: [
          // FIFO KPI Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL STOK FIFO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatQty(stockProv.totalBatchStock),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('VALUASI ASET STOK (HPP)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.format(stockProv.totalBatchValuation),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (batches.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(30)),
                      child: const Icon(LucideIcons.packageCheck, size: 28, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Belum ada batch stok FIFO aktif.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    const Text('Batch dibuat otomatis saat barang masuk dari Penerimaan (GRN).', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            )
          else
            ...batches.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildBatchCard(b),
                )),
        ],
      ),
    );
  }

  Widget _buildBatchCard(StockBatchModel batch) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.productName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            batch.batchNumber,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                          ),
                        ),
                        Text('Masuk: ${batch.entryDate}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: batch.expiryBadgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  batch.expiryStatusLabel,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: batch.expiryBadgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Remaining bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: batch.remainingRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Sisa: ${_formatQty(batch.qtyRemaining)} / ${_formatQty(batch.qtyIn)} ${batch.unitName}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'HPP: ${CurrencyFormatter.format(batch.unitCost)} (Val: ${CurrencyFormatter.format(batch.totalValuation)})',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: PER PRODUCT STOCK CARD
  // ==========================================
  Widget _buildPerProductTab(StockProvider stockProv) {
    final masterProv = context.watch<MasterDataProvider>();
    final products = masterProv.products;
    final rawMaterials = masterProv.rawMaterials;
    
    // Combine unique items (products and raw materials)
    final Map<int, ProductModel> itemMap = {};
    for (var p in products) {
      itemMap[p.id] = p;
    }
    for (var r in rawMaterials) {
      itemMap[r.id] = r;
    }
    final allItems = itemMap.values.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        // Product Selector Dropdown
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Produk / Bahan Baku untuk Kartu Stok', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: allItems.any((p) => p.id == stockProv.selectedProductId)
                    ? stockProv.selectedProductId
                    : null,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                hint: const Text('Pilih Item (Produk / Bahan Baku)...', style: TextStyle(fontSize: 12.5)),
                items: allItems.map((p) {
                  final isRaw = rawMaterials.any((r) => r.id == p.id);
                  return DropdownMenuItem<int?>(
                    value: p.id,
                    child: Row(
                      children: [
                        if (isRaw)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              'RAW',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    stockProv.setProductFilter(val);
                    stockProv.fetchProductStockCard(val);
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (stockProv.isLoadingProductCard)
          const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: AppColors.primary)))
        else if (stockProv.productCardData != null) ...[
          _buildProductCardDetail(stockProv.productCardData!),
        ] else if (stockProv.selectedProductId == null) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('Pilih salah satu produk di atas untuk melihat detail kartu stok & alokasi batchnya.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductCardDetail(ProductStockCardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Stock Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFEDD5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(8)),
                child: const Icon(LucideIcons.boxes, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(
                      'Total Stok Fisik: ${_formatQty(data.totalStock)} ${data.unitName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEA580C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Stocks by Warehouse
        if (data.stocksByWarehouse.isNotEmpty) ...[
          const Text('Stok per Gudang / Lokasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          ...data.stocksByWarehouse.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.warehouse, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.warehouseName,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatQty(s.quantity)} ${data.unitName}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
        ],

        // Active FIFO Batches
        if (data.fifoBatches.isNotEmpty) ...[
          const Text('Batch FIFO Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          ...data.fifoBatches.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildBatchCard(b))),
          const SizedBox(height: 14),
        ],

        // Recent Movements
        if (data.recentMovements.isNotEmpty) ...[
          const Text('Riwayat Mutasi Terakhir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          ...data.recentMovements.map((m) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildMovementCard(m))),
        ],
      ],
    );
  }
}
