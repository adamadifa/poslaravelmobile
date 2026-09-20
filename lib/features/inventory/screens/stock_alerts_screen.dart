import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/stock_alert_model.dart';
import 'package:poslaravelmobile/data/models/stock_batch_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_card_screen.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_order_form_screen.dart';

class StockAlertsScreen extends StatefulWidget {
  const StockAlertsScreen({super.key});

  @override
  State<StockAlertsScreen> createState() => _StockAlertsScreenState();
}

class _StockAlertsScreenState extends State<StockAlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProv = context.read<StockProvider>();
      final masterProv = context.read<MasterDataProvider>();

      masterProv.fetchWarehouses();
      stockProv.fetchAlerts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
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
                          'Filter Peringatan Stok',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            stockProv.setAlertWarehouseFilter(null);
                            stockProv.setAlertProductTypeTab('all');
                            stockProv.setAlertDaysThreshold(30);
                            stockProv.setAlertSearch('');
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
                      initialValue: warehouses.any((w) => w.id == stockProv.alertWarehouseId)
                          ? stockProv.alertWarehouseId
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      hint: const Text('Semua Gudang / Cabang', style: TextStyle(fontSize: 12.5)),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Semua Gudang', style: TextStyle(fontSize: 13))),
                        ...warehouses.map((w) => DropdownMenuItem<int?>(
                              value: w.id,
                              child: Text(w.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) {
                        stockProv.setAlertWarehouseFilter(val);
                        setModalState(() {});
                      },
                    ),

                    const SizedBox(height: 14),

                    // Product type filter tabs
                    const Text('Kategori Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTypeChip('Semua Item', 'all', stockProv.alertProductTypeTab, (t) {
                          stockProv.setAlertProductTypeTab(t);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 8),
                        _buildTypeChip('Produk Jadi', 'products', stockProv.alertProductTypeTab, (t) {
                          stockProv.setAlertProductTypeTab(t);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 8),
                        _buildTypeChip('Bahan Baku', 'raw_materials', stockProv.alertProductTypeTab, (t) {
                          stockProv.setAlertProductTypeTab(t);
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

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final alertsData = stockProv.alertsData;
    final summary = alertsData?.summary;

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
              'Peringatan Stok & Kedaluwarsa',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Monitoring stok menipis & deteksi dini expired batch',
              style: TextStyle(fontSize: 10.5, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter, color: Colors.white, size: 19),
            tooltip: 'Filter',
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
            tooltip: 'Segarkan',
            onPressed: () => stockProv.fetchAlerts(),
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
                  onChanged: (val) => stockProv.setAlertSearch(val),
                  decoration: InputDecoration(
                    hintText: 'Cari produk, bahan baku, SKU, batch...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchCtrl.clear();
                              stockProv.setAlertSearch('');
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
                    _buildQuickTabChip('Semua Item', 'all', stockProv.alertProductTypeTab, (t) => stockProv.setAlertProductTypeTab(t)),
                    const SizedBox(width: 6),
                    _buildQuickTabChip('Produk Jadi', 'products', stockProv.alertProductTypeTab, (t) => stockProv.setAlertProductTypeTab(t)),
                    const SizedBox(width: 6),
                    _buildQuickTabChip('Bahan Baku (Raw)', 'raw_materials', stockProv.alertProductTypeTab, (t) => stockProv.setAlertProductTypeTab(t)),
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
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Stok Menipis'),
                        if (summary != null && summary.totalLowStock > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${summary.totalLowStock}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Kedaluwarsa (Batch)'),
                        if (summary != null && summary.totalExpiring > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${summary.totalExpiring}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLowStockTab(stockProv),
          _buildExpiringBatchesTab(stockProv),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: LOW STOCK PRODUCTS & RAW MATERIALS
  // ==========================================
  Widget _buildLowStockTab(StockProvider stockProv) {
    if (stockProv.isLoadingAlerts && stockProv.alertsData == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final items = stockProv.alertsData?.lowStockProducts ?? [];
    final summary = stockProv.alertsData?.summary;

    return RefreshIndicator(
      onRefresh: () => stockProv.fetchAlerts(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: [
          // KPI Summary Cards
          if (summary != null)
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
                        const Text('PERLU RESTOCK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFD97706), letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${summary.totalLowStock} Item',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                          ),
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
                        const Text('STOK HABIS (0)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626), letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${summary.outOfStockCount} Item',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(30)),
                      child: const Icon(LucideIcons.checkCircle2, size: 28, color: Color(0xFF16A34A)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Semua Stok Aman!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    const Text(
                      'Tidak ada produk atau bahan baku yang berada di bawah batas minimum.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildLowStockCard(item),
                )),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(LowStockItemModel item) {
    final isRaw = item.productType == 'raw_material';
    final isOut = item.isOutOfStock;
    final ratio = item.minStock > 0 ? (item.currentStock / item.minStock).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isOut ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOut ? LucideIcons.alertOctagon : LucideIcons.alertTriangle,
                  color: isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                              'BAHAN BAKU',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.code != null && item.code!.isNotEmpty) ...[
                          Text(item.code!, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 4),
                          const Text('•', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 4),
                        ],
                        Text(item.categoryName ?? 'Umum', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isOut ? const Color(0xFFFECACA) : const Color(0xFFFDE68A)),
                ),
                child: Text(
                  isOut ? 'HABIS' : 'MENIPIS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stock level ratio progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: isOut
                  ? const Color(0xFFDC2626)
                  : ratio < 0.5
                      ? const Color(0xFFEA580C)
                      : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 8),

          // Stock Info Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stok Saat Ini', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(
                      '${_formatQty(item.currentStock)} ${item.unitName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Batas Min', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(
                      '${_formatQty(item.minStock)} ${item.unitName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Kekurangan (Defisit)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(
                      '-${_formatQty(item.deficit)} ${item.unitName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.fileText, size: 14, color: Color(0xFF475569)),
                  label: const Text('Kartu Stok', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockCardScreen(initialProductId: item.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.shoppingBag, size: 14, color: Colors.white),
                  label: const Text('Buat PO', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PurchaseOrderFormScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: EXPIRING / EXPIRED FIFO BATCHES
  // ==========================================
  Widget _buildExpiringBatchesTab(StockProvider stockProv) {
    if (stockProv.isLoadingAlerts && stockProv.alertsData == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final batches = stockProv.alertsData?.expiringBatches ?? [];
    final summary = stockProv.alertsData?.summary;

    return RefreshIndicator(
      onRefresh: () => stockProv.fetchAlerts(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: [
          // Expiry KPI Card
          if (summary != null)
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
                        const Text('SUDAH KEDALUWARSA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626), letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${summary.expiredCount} Batch',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                          ),
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
                        const Text('MENDEKATI EXPIRED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFD97706), letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${summary.expiringSoonCount} Batch',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
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
                        const Text('VALUASI TERANCAM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(summary.expiringValuation),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Days threshold quick pills
          Row(
            children: [
              _buildExpiryFilterPill('30 Hari', 30, stockProv.alertDaysThreshold, (d) => stockProv.setAlertDaysThreshold(d)),
              const SizedBox(width: 6),
              _buildExpiryFilterPill('60 Hari', 60, stockProv.alertDaysThreshold, (d) => stockProv.setAlertDaysThreshold(d)),
              const SizedBox(width: 6),
              _buildExpiryFilterPill('90 Hari', 90, stockProv.alertDaysThreshold, (d) => stockProv.setAlertDaysThreshold(d)),
            ],
          ),

          const SizedBox(height: 14),

          if (batches.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(30)),
                      child: const Icon(LucideIcons.checkCheck, size: 28, color: Color(0xFF16A34A)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Tidak Ada Batch Kedaluwarsa!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(
                      'Semua batch barang berada dalam masa simpan aman (di atas ${stockProv.alertDaysThreshold} hari).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...batches.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildExpiringBatchCard(b),
                )),
        ],
      ),
    );
  }

  Widget _buildExpiryFilterPill(String label, int days, int selectedDays, Function(int) onTap) {
    final isSelected = selectedDays == days;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(days),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEA580C) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0)),
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

  Widget _buildExpiringBatchCard(StockBatchModel batch) {
    final isExp = batch.isExpired;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isExp ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
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
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
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
                        Text('Gudang: ${batch.warehouseName}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
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

          // Detail box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sisa Stok Batch', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(
                      '${_formatQty(batch.qtyRemaining)} ${batch.unitName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Tanggal Expired', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(
                      batch.expiryDate ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isExp ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Nilai Valuasi (HPP)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(
                      CurrencyFormatter.format(batch.totalValuation),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Action button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(LucideIcons.fileText, size: 14, color: Color(0xFF475569)),
              label: const Text('Lihat Kartu Stok Produk', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockCardScreen(initialProductId: batch.productId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
