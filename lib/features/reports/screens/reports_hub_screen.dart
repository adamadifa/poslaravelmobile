import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/widgets/app_sidebar_drawer.dart';
import 'package:poslaravelmobile/data/models/report_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/reports/providers/report_provider.dart';

class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> with SingleTickerProviderStateMixin {
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<Map<String, dynamic>> _reportCategories = const [
    {'title': 'Penjualan', 'icon': LucideIcons.receipt},
    {'title': 'Pembelian', 'icon': LucideIcons.truck},
    {'title': 'Stok & Opname', 'icon': LucideIcons.boxes},
    {'title': 'Laba & Arus Kas', 'icon': LucideIcons.lineChart},
    {'title': 'Hutang & Piutang', 'icon': LucideIcons.coins},
    {'title': 'Shift Kasir', 'icon': LucideIcons.userCheck},
  ];

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _initTabController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchWarehouses();
      context.read<ReportProvider>().setCategoryIndex(0);
    });
  }

  void _initTabController() {
    _tabController?.dispose();
    _tabController = TabController(length: _reportCategories.length, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        final prov = context.read<ReportProvider>();
        if (prov.currentCategoryIndex != _tabController!.index) {
          prov.setCategoryIndex(_tabController!.index);
        }
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    _initTabController();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = context.watch<ReportProvider>();
    final masterProv = context.watch<MasterDataProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        title: const Text(
          'Laporan & Analitik Bisnis',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: _reportCategories.map((cat) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat['icon'] as IconData, size: 15),
                      const SizedBox(width: 6),
                      Text(cat['title'] as String),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar (Period & Outlet)
          _buildFilterBar(context, reportProv, masterProv),

          // Main Content Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesReportTab(reportProv),
                _buildPurchasesReportTab(reportProv),
                _buildStockAndOpnamesTab(reportProv),
                _buildProfitAndCashFlowsTab(reportProv),
                _buildPayablesAndReceivablesTab(reportProv),
                _buildCashierShiftsTab(reportProv),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, ReportProvider reportProv, MasterDataProvider masterProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip(reportProv, ReportPeriod.today, 'Hari Ini'),
                      const SizedBox(width: 6),
                      _buildPeriodChip(reportProv, ReportPeriod.last7Days, '7 Hari'),
                      const SizedBox(width: 6),
                      _buildPeriodChip(reportProv, ReportPeriod.thisMonth, 'Bulan Ini'),
                      const SizedBox(width: 6),
                      _buildPeriodChip(reportProv, ReportPeriod.thisYear, 'Tahun Ini'),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _pickCustomDateRange(context, reportProv),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: reportProv.selectedPeriod == ReportPeriod.custom
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: reportProv.selectedPeriod == ReportPeriod.custom
                                  ? AppColors.primary
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 13,
                                color: reportProv.selectedPeriod == ReportPeriod.custom
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                reportProv.selectedPeriod == ReportPeriod.custom
                                    ? reportProv.dateRangeLabel
                                    : 'Custom',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: reportProv.selectedPeriod == ReportPeriod.custom
                                      ? AppColors.primary
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 16, color: Color(0xFF64748B)),
                tooltip: 'Segarkan Data',
                onPressed: () => reportProv.refreshCurrentCategory(),
              ),
            ],
          ),
          if (masterProv.warehouses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.store, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                const Text(
                  'Outlet/Gudang:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: reportProv.selectedWarehouseId,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF64748B)),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Outlet & Gudang'),
                          ),
                          ...masterProv.warehouses.map((w) {
                            return DropdownMenuItem<int?>(
                              value: w.id,
                              child: Text(w.name),
                            );
                          }),
                        ],
                        onChanged: (val) => reportProv.setWarehouse(val),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(ReportProvider reportProv, ReportPeriod period, String title) {
    final isSelected = reportProv.selectedPeriod == period;
    return InkWell(
      onTap: () => reportProv.setPeriod(period),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context, ReportProvider reportProv) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: reportProv.startDate, end: reportProv.endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      reportProv.setPeriod(ReportPeriod.custom, customStart: picked.start, customEnd: picked.end);
    }
  }

  // ==================== TAB 1: PENJUALAN ====================
  Widget _buildSalesReportTab(ReportProvider prov) {
    if (prov.isLoadingSales) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final data = prov.salesData;
    if (data == null) {
      return _buildEmptyState('Tidak ada data penjualan untuk periode ini.', () => prov.fetchSalesReport());
    }

    final kpis = data.kpis;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => prov.fetchSalesReport(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sub-Tab Switcher (Ringkasan, Produk, Kategori, Pelanggan)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildSubTabButton(prov, 0, 'Ringkasan'),
                _buildSubTabButton(prov, 1, 'Produk & Margin'),
                _buildSubTabButton(prov, 2, 'Kategori'),
                _buildSubTabButton(prov, 3, 'Pelanggan'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (prov.salesSubTabIndex == 0) ...[
            // Total Revenue Highlight Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL OMZET PENJUALAN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFFFEDD5), letterSpacing: 0.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${kpis.totalTransactions} Transaksi',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(kpis.totalSales),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat('Laba Kotor', currencyFormat.format(kpis.grossProfit), textColor: const Color(0xFF86EFAC)),
                        Container(width: 1, height: 24, color: Colors.white24),
                        _buildMiniStat('Margin', '${kpis.profitMarginPercent.toStringAsFixed(1)}%', textColor: Colors.white),
                        Container(width: 1, height: 24, color: Colors.white24),
                        _buildMiniStat('Rerata Bon', currencyFormat.format(kpis.averageOrderValue), textColor: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Secondary KPI Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Tunai (Cash)',
                    value: currencyFormat.format(kpis.totalCash),
                    icon: LucideIcons.banknote,
                    iconColor: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Non Tunai / QRIS',
                    value: currencyFormat.format(kpis.totalNonCash),
                    icon: LucideIcons.creditCard,
                    iconColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFDBEAFE),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Diskon',
                    value: currencyFormat.format(kpis.totalDiscount),
                    icon: LucideIcons.tag,
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total HPP (Modal)',
                    value: currencyFormat.format(kpis.totalHpp),
                    icon: LucideIcons.boxes,
                    iconColor: const Color(0xFF64748B),
                    bgColor: const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top Selling Snippet
            _buildSectionTitle('Top 5 Produk Terlaris'),
            const SizedBox(height: 8),
            if (prov.topProducts.isEmpty)
              _buildEmptyMini('Belum ada data produk terjual.')
            else
              ...prov.topProducts.take(5).map((p) => _buildProductPerformanceItem(p)),
          ] else if (prov.salesSubTabIndex == 1) ...[
            _buildSectionTitle('Semua Penjualan per Produk & Margin'),
            const SizedBox(height: 8),
            if (prov.topProducts.isEmpty)
              _buildEmptyMini('Tidak ada transaksi produk pada periode ini.')
            else
              ...prov.topProducts.map((p) => _buildProductPerformanceItem(p)),
          ] else if (prov.salesSubTabIndex == 2) ...[
            _buildSectionTitle('Performa Kategori Produk'),
            const SizedBox(height: 8),
            if (prov.categoryPerformance.isEmpty)
              _buildEmptyMini('Belum ada data kategori.')
            else
              ...prov.categoryPerformance.map((c) => _buildCategoryPerformanceItem(c)),
          ] else if (prov.salesSubTabIndex == 3) ...[
            _buildSectionTitle('Penjualan per Pelanggan (Customer)'),
            const SizedBox(height: 8),
            if (prov.customerSales.isEmpty)
              _buildEmptyMini('Belum ada data pelanggan tercatat.')
            else
              ...prov.customerSales.map((cust) => _buildCustomerSaleItem(cust)),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(ReportProvider prov, int index, String label) {
    final isSelected = prov.salesSubTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => prov.setSalesSubTabIndex(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductPerformanceItem(ProductPerformanceModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.packageCheck, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.productName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${p.totalQty.toStringAsFixed(0)} terjual • Margin: ${p.marginPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(p.totalRevenue),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Text(
                'Laba: ${currencyFormat.format(p.grossProfit)}',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceItem(CategoryPerformanceModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.categoryName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                Text(
                  '${c.totalQty.toStringAsFixed(0)} item terjual',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(c.totalRevenue),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Text(
                'Margin ${c.marginPercent.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFEA580C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSaleItem(CustomerSalesReportModel cust) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.user, size: 18, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cust.customerName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                Text(
                  '${cust.totalOrders} order • Telp: ${cust.customerPhone}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(cust.totalSpent),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Text(
                'Terakhir: ${cust.lastOrderDate}',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: PEMBELIAN (PO) ====================
  Widget _buildPurchasesReportTab(ReportProvider prov) {
    if (prov.isLoadingPurchases) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final p = prov.purchasesData;
    if (p == null) {
      return _buildEmptyState('Tidak ada data pembelian untuk periode ini.', () => prov.refreshCurrentCategory());
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => prov.refreshCurrentCategory(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Purchases Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PEMBELIAN & PENGADAAN (PO)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFBFDBFE), letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${p.totalOrders} Order PO',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(p.totalPurchases),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Total diskon pengadaan: ${currencyFormat.format(p.totalDiscount)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Pengadaan per Supplier'),
          const SizedBox(height: 8),
          if (p.supplierBreakdown.isEmpty)
            _buildEmptyMini('Tidak ada transaksi supplier.')
          else
            ...p.supplierBreakdown.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.truck, size: 18, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.supplierName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            '${s.totalPoCount} purchase order',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(s.totalAmount),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== TAB 3: STOK & OPNAME ====================
  Widget _buildStockAndOpnamesTab(ReportProvider prov) {
    if (prov.isLoadingValuation) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final val = prov.valuationData;
    if (val == null) {
      return _buildEmptyState('Tidak ada data valuasi persediaan.', () => prov.refreshCurrentCategory());
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => prov.refreshCurrentCategory(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Valuation Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL VALUASI ASSET STOK (HPP)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${val.totalProducts} Jenis Produk',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(val.totalValuationCost),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Total Stok Fisik', '${val.totalStockQty.toStringAsFixed(0)} unit', textColor: Colors.white),
                      Container(width: 1, height: 24, color: Colors.white24),
                      _buildMiniStat('Potensi Omzet', currencyFormat.format(val.totalPotentialRevenue), textColor: const Color(0xFFFDE047)),
                      Container(width: 1, height: 24, color: Colors.white24),
                      _buildMiniStat('Potensi Laba', currencyFormat.format(val.potentialProfit), textColor: const Color(0xFF86EFAC)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Inventory Alerts
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 20, color: Color(0xFFDC2626)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${val.outOfStockItems}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                          const Text('Stok Habis (0)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF991B1B))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 20, color: Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${val.lowStockItems}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                          const Text('Stok Menipis', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Hasil Stok Opname (Fisik vs Sistem)'),
          const SizedBox(height: 8),
          if (prov.stockOpnames.isEmpty)
            _buildEmptyMini('Belum ada riwayat audit stok opname.')
          else
            ...prov.stockOpnames.map((o) {
              final isDiff = o.totalDifferenceQty != 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDiff ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDiff ? LucideIcons.fileWarning : LucideIcons.fileCheck,
                        size: 18,
                        color: isDiff ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.opnameNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          Text('${o.warehouseName} • Oleh: ${o.conductorName} • ${o.opnameDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${o.totalDifferenceQty >= 0 ? "+" : ""}${o.totalDifferenceQty.toStringAsFixed(0)} qty',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDiff ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                        ),
                        Text(
                          currencyFormat.format(o.totalDifferenceCost),
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== TAB 4: LABA RUGI & ARUS KAS ====================
  Widget _buildProfitAndCashFlowsTab(ReportProvider prov) {
    if (prov.isLoadingPL) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final pl = prov.profitLossData;
    if (pl == null) {
      return _buildEmptyState('Tidak ada data laba rugi untuk periode ini.', () => prov.refreshCurrentCategory());
    }

    final isProfit = pl.isProfitable;
    final cf = prov.cashFlowsData;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => prov.refreshCurrentCategory(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Net Profit Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isProfit ? const Color(0xFF059669) : const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isProfit ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isProfit ? 'LABA BERSIH (NET PROFIT)' : 'RUGI BERSIH (NET LOSS)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Margin: ${pl.netMarginPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(pl.netProfit),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  isProfit ? 'Performa bisnis dalam kondisi sehat dan menguntungkan.' : 'Total pengeluaran melebihi pendapatan bisnis.',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // P&L Breakdown Table
          _buildSectionTitle('Laporan Laba Rugi Komprehensif (P&L)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildPLRowHeader('1. PENDAPATAN OPERASIONAL', const Color(0xFF1E293B)),
                _buildPLRowItem('Penjualan Kotor (Gross Sales)', currencyFormat.format(pl.grossSales)),
                if (pl.discounts > 0)
                  _buildPLRowItem('Diskon Penjualan', '- ${currencyFormat.format(pl.discounts)}', valueColor: const Color(0xFFDC2626)),
                _buildPLRowItem('Penjualan Bersih (Net Sales)', currencyFormat.format(pl.netSales), isBold: true),
                if (pl.extraIncome > 0)
                  _buildPLRowItem('Pendapatan Lain-lain', '+ ${currencyFormat.format(pl.extraIncome)}', valueColor: const Color(0xFF16A34A)),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildPLRowHeader('2. HARGA POKOK PENJUALAN (HPP)', const Color(0xFF1E293B)),
                _buildPLRowItem('Total HPP Modal Produk Terjual', '- ${currencyFormat.format(pl.totalHpp)}', valueColor: const Color(0xFFDC2626)),
                _buildPLRowItem('Laba Kotor (Gross Profit)', currencyFormat.format(pl.grossProfit), isBold: true, valueColor: const Color(0xFF16A34A)),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildPLRowHeader('3. BEBAN OPERASIONAL (EXPENSES)', const Color(0xFF1E293B)),
                if (pl.expenseBreakdown.isEmpty)
                  _buildPLRowItem('Tidak ada beban operasional', 'Rp 0')
                else
                  ...pl.expenseBreakdown.map((exp) => _buildPLRowItem('Beban ${exp.category}', '- ${currencyFormat.format(exp.amount)}', valueColor: const Color(0xFFDC2626))),
                _buildPLRowItem('Total Beban Operasional', '- ${currencyFormat.format(pl.totalExpenses)}', isBold: true, valueColor: const Color(0xFFDC2626)),

                const Divider(height: 1, thickness: 2, color: Color(0xFFE2E8F0)),
                _buildPLRowItem(
                  'LABA / (RUGI) BERSIH',
                  currencyFormat.format(pl.netProfit),
                  isBold: true,
                  valueColor: isProfit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  bgColor: const Color(0xFFF8FAFC),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cash Flows Mini Summary
          if (cf != null) ...[
            _buildSectionTitle('Buku Arus Kas & Rekening Bank'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Kas Masuk',
                    value: currencyFormat.format(cf.totalIncome),
                    icon: LucideIcons.arrowDownLeft,
                    iconColor: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Kas Keluar',
                    value: currencyFormat.format(cf.totalExpense),
                    icon: LucideIcons.arrowUpRight,
                    iconColor: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEE2E2),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== TAB 5: HUTANG & PIUTANG (AP & AR) ====================
  Widget _buildPayablesAndReceivablesTab(ReportProvider prov) {
    if (prov.isLoadingAPAR) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final ap = prov.payablesData;
    final ar = prov.receivablesData;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => prov.refreshCurrentCategory(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AP & AR Big Balance Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.receipt, size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 6),
                          Text('Hutang Supplier (AP)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(ap?.totalOutstanding ?? 0),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.coins, size: 14, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text('Piutang Penjualan (AR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(ar?.totalOutstanding ?? 0),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Daftar Piutang Customer Belum Lunas'),
          const SizedBox(height: 8),
          if (ar == null || ar.receivables.isEmpty)
            _buildEmptyMini('Tidak ada piutang customer aktif.')
          else
            ...ar.receivables.take(5).map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          Text('${item.invoiceNumber} • ${item.daysOutstanding} hari', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.outstandingAmount),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),
          _buildSectionTitle('Daftar Hutang Supplier Belum Lunas'),
          const SizedBox(height: 8),
          if (ap == null || ap.payables.isEmpty)
            _buildEmptyMini('Tidak ada hutang supplier aktif.')
          else
            ...ap.payables.take(5).map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.supplierName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          Text('PO: ${item.poNumber} • ${item.daysOutstanding} hari', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.outstandingAmount),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== TAB 6: SHIFT KASIR ====================
  Widget _buildCashierShiftsTab(ReportProvider prov) {
    if (prov.isLoadingShifts) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final s = prov.shiftData;
    if (s == null) {
      return _buildEmptyState('Tidak ada data shift kasir untuk periode ini.', () => prov.refreshCurrentCategory());
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => prov.refreshCurrentCategory(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Shift',
                  value: '${s.totalShifts}',
                  icon: LucideIcons.userCheck,
                  iconColor: AppColors.primary,
                  bgColor: const Color(0xFFFFF7ED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Selisih Kas',
                  value: currencyFormat.format(s.totalCashDifference),
                  icon: LucideIcons.scale,
                  iconColor: s.totalCashDifference < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  bgColor: s.totalCashDifference < 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Riwayat Sesi Shift Kasir'),
          const SizedBox(height: 8),
          if (s.shifts.isEmpty)
            _buildEmptyMini('Belum ada riwayat shift kasir.')
          else
            ...s.shifts.map((shift) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: shift.status == 'closed' ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        shift.status == 'closed' ? LucideIcons.lock : LucideIcons.unlock,
                        size: 18,
                        color: shift.status == 'closed' ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shift.cashierName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          Text('${shift.warehouseName} • Buka: ${shift.openedAt}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(shift.totalSales),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        if (shift.cashDifference != 0)
                          Text(
                            'Selisih: ${currencyFormat.format(shift.cashDifference)}',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: shift.cashDifference < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== HELPER BUILDERS ====================
  Widget _buildPLRowHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: Text(
        title,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildPLRowItem(String title, String value, {bool isBold = false, Color? valueColor, Color? bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: bgColor ?? Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {required Color textColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildEmptyMini(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      ),
    );
  }

  Widget _buildEmptyState(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.barChart2, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
