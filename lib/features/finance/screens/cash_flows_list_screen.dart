import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';
import 'package:poslaravelmobile/data/models/cash_flow_model.dart';
import 'package:poslaravelmobile/features/finance/providers/cash_flow_provider.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class CashFlowsListScreen extends StatefulWidget {
  const CashFlowsListScreen({super.key});

  @override
  State<CashFlowsListScreen> createState() => _CashFlowsListScreenState();
}

class _CashFlowsListScreenState extends State<CashFlowsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _dateFilterMode = 'all'; // all, today, 7days, this_month

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashFlowProvider>().fetchCashFlows(refresh: true);
      context.read<CashFlowProvider>().fetchCategories();
      context.read<MasterDataProvider>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyDateFilter(String mode) {
    setState(() => _dateFilterMode = mode);
    final now = DateTime.now();
    String? start;
    String? end;

    if (mode == 'today') {
      start = DateFormat('yyyy-MM-dd').format(now);
      end = DateFormat('yyyy-MM-dd').format(now);
    } else if (mode == '7days') {
      start = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 6)));
      end = DateFormat('yyyy-MM-dd').format(now);
    } else if (mode == 'this_month') {
      start = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
      end = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));
    }

    context.read<CashFlowProvider>().setDateRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final cashFlowProvider = context.watch<CashFlowProvider>();
    final masterProvider = context.watch<MasterDataProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arus Kas Masuk & Keluar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Buku kas masuk, beban operasional, & mutasi',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
            onPressed: () => cashFlowProvider.fetchCashFlows(refresh: true),
            tooltip: 'Segarkan Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await cashFlowProvider.fetchCashFlows(refresh: true);
          await cashFlowProvider.fetchCategories();
          await masterProvider.fetchAccounts();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top Summary Hero Card
            SliverToBoxAdapter(
              child: _buildSummaryHero(cashFlowProvider.summary),
            ),

            // Filter Bar (Type Tabs, Account & Search)
            SliverToBoxAdapter(
              child: _buildFilterSection(cashFlowProvider, masterProvider.accounts),
            ),

            // Cash Flow List Items
            if (cashFlowProvider.isLoading && cashFlowProvider.cashFlows.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (cashFlowProvider.cashFlows.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = cashFlowProvider.cashFlows[index];
                      return _buildCashFlowCard(item);
                    },
                    childCount: cashFlowProvider.cashFlows.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plusCircle, color: Colors.white),
        label: const Text(
          'Catat Arus Kas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddEditCashFlowSheet(context),
      ),
    );
  }

  Widget _buildSummaryHero(CashFlowSummary summary) {
    final isNetPositive = summary.netFlow >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33EA580C),
            blurRadius: 14,
            offset: Offset(0, 6),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.wallet, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TOTAL ARUS KAS BERSIH',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNetPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isNetPositive ? 'Surplus' : 'Defisit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary.formattedNetFlow,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.arrowDownLeft, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kas Masuk',
                              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.formattedIncome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.arrowUpRight, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kas Keluar',
                              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.formattedExpense,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(CashFlowProvider provider, List<AccountModel> accounts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Account selector in one row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari nomor / kategori / ket...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF64748B)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchCtrl.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onSubmitted: (val) => provider.setSearchQuery(val.trim()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Account Filter Dropdown Button
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: provider.selectedAccountId != null
                        ? AppColors.primary
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: provider.selectedAccountId,
                    hint: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.landmark, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text('Semua Akun', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    icon: const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF64748B)),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Semua Akun Kas / Bank', style: TextStyle(fontSize: 13)),
                      ),
                      ...accounts.map(
                        (acc) => DropdownMenuItem<int?>(
                          value: acc.id,
                          child: Text(acc.name, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                    onChanged: (val) => provider.setAccountFilter(val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Date Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateChip('Semua Waktu', 'all'),
                const SizedBox(width: 6),
                _buildDateChip('Hari Ini', 'today'),
                const SizedBox(width: 6),
                _buildDateChip('7 Hari Terakhir', '7days'),
                const SizedBox(width: 6),
                _buildDateChip('Bulan Ini', 'this_month'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Type Segmented Filter (Semua, Kas Masuk, Kas Keluar)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildTypeTab('Semua', 'all', provider),
                _buildTypeTab('Kas Masuk (+)', 'income', provider),
                _buildTypeTab('Kas Keluar (-)', 'expense', provider),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, String mode) {
    final isSelected = _dateFilterMode == mode;
    return InkWell(
      onTap: () => _applyDateFilter(mode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, String type, CashFlowProvider provider) {
    final isSelected = provider.selectedType == type;
    Color activeColor = Colors.white;
    Color textColor = const Color(0xFF0F172A);

    if (isSelected) {
      if (type == 'income') {
        textColor = const Color(0xFF059669);
      } else if (type == 'expense') {
        textColor = const Color(0xFFDC2626);
      } else {
        textColor = AppColors.primary;
      }
    } else {
      textColor = const Color(0xFF64748B);
    }

    return Expanded(
      child: InkWell(
        onTap: () => provider.setTypeFilter(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowCard(CashFlowModel item) {
    final isIncome = item.isIncome;
    final color = isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final bgColor = isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showDetailSheet(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Badge
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Main Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '${isIncome ? '+' : '-'} ${item.formattedAmount}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.account?.name ?? 'Akun Kas',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                item.formattedDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.description!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.cashFlowNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    if (item.isAutomatic)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.lock, size: 10, color: Color(0xFF64748B)),
                            SizedBox(width: 3),
                            Text(
                              'Otomatis Sistem',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: const Text(
                          'Manual',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.arrowDownUp,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Transaksi Arus Kas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Catat pemasukan atau pengeluaran operasional bisnis dengan tombol di bawah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DETAIL BOTTOM SHEET
  // ==========================================
  void _showDetailSheet(BuildContext context, CashFlowModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CashFlowDetailSheet(
        item: item,
        onEdit: () {
          Navigator.pop(ctx);
          _showAddEditCashFlowSheet(context, editItem: item);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDeleteCashFlow(context, item);
        },
      ),
    );
  }

  // ==========================================
  // ADD / EDIT BOTTOM SHEET
  // ==========================================
  void _showAddEditCashFlowSheet(BuildContext context, {CashFlowModel? editItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditCashFlowSheet(editItem: editItem),
    );
  }

  // ==========================================
  // CONFIRM DELETE
  // ==========================================
  void _confirmDeleteCashFlow(BuildContext parentContext, CashFlowModel item) {
    showDialog(
      context: parentContext,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Hapus Transaksi?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi arus kas ${item.cashFlowNumber} sebesar ${item.formattedAmount}?\n\nSaldo akun ${item.account?.name ?? 'terkait'} akan otomatis disesuaikan kembali.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(parentContext);
              Navigator.pop(dialogCtx);
              final provider = parentContext.read<CashFlowProvider>();
              final success = await provider.deleteCashFlow(item.id);
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi arus kas berhasil dihapus dan saldo disesuaikan'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Gagal menghapus arus kas'),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              }
            },
            child: const Text('Hapus Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// DETAIL SHEET WIDGET
// ==========================================================
class _CashFlowDetailSheet extends StatelessWidget {
  final CashFlowModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CashFlowDetailSheet({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = item.isIncome;
    final color = isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail ${item.typeLabel}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isIncome ? '+' : '-'} ${item.formattedAmount}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Nomor Transaksi', item.cashFlowNumber),
          _buildDetailRow('Tanggal', item.formattedDate),
          _buildDetailRow('Akun Kas / Bank', item.account?.name ?? '-'),
          if (item.account?.bankName != null && item.account!.bankName!.isNotEmpty)
            _buildDetailRow('Nama Bank', item.account!.bankName!),
          if (item.description != null && item.description!.isNotEmpty)
            _buildDetailRow('Keterangan', item.description!),
          if (item.creatorName != null)
            _buildDetailRow('Dicatat Oleh', item.creatorName!),
          _buildDetailRow(
            'Tipe Mutasi',
            item.isAutomatic ? 'Otomatis oleh Sistem' : 'Transaksi Manual',
          ),
          const SizedBox(height: 24),
          if (!item.isAutomatic)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onDelete,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onEdit,
                    icon: const Icon(LucideIcons.edit3, size: 16),
                    label: const Text('Edit Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transaksi otomatis tercatat melalui sistem modul (POS / Pengadaan / Shift) dan tidak dapat diubah manual.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// ADD / EDIT FORM SHEET WIDGET
// ==========================================================
class _AddEditCashFlowSheet extends StatefulWidget {
  final CashFlowModel? editItem;

  const _AddEditCashFlowSheet({this.editItem});

  @override
  State<_AddEditCashFlowSheet> createState() => _AddEditCashFlowSheetState();
}

class _AddEditCashFlowSheetState extends State<_AddEditCashFlowSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type; // income | expense
  int? _selectedAccountId;
  late TextEditingController _categoryCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  late DateTime _transactionDate;

  @override
  void initState() {
    super.initState();
    final edit = widget.editItem;
    _type = edit?.type ?? 'expense';
    _selectedAccountId = edit?.accountId;
    _categoryCtrl = TextEditingController(text: edit?.category ?? '');
    _amountCtrl = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(0) : '',
    );
    _descCtrl = TextEditingController(text: edit?.description ?? '');
    _transactionDate = edit?.transactionDate ?? DateTime.now();

    // Default to first active account if new and not selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedAccountId == null) {
        final accounts = context.read<MasterDataProvider>().accounts;
        if (accounts.isNotEmpty) {
          final defaultAcc = accounts.firstWhere(
            (a) => a.isDefault,
            orElse: () => accounts.first,
          );
          setState(() => _selectedAccountId = defaultAcc.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterProvider = context.watch<MasterDataProvider>();
    final cashFlowProvider = context.watch<CashFlowProvider>();
    final isEditing = widget.editItem != null;

    final categories = _type == 'income'
        ? cashFlowProvider.incomeCategories
        : cashFlowProvider.expenseCategories;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Transaksi Arus Kas' : 'Catat Arus Kas Baru',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Type Switcher (Kas Masuk / Kas Keluar)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: isEditing
                            ? null
                            : () {
                                setState(() {
                                  _type = 'income';
                                  _categoryCtrl.clear();
                                });
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _type == 'income' ? const Color(0xFF059669) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.arrowDownLeft,
                                  size: 16,
                                  color: _type == 'income' ? Colors.white : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kas Masuk (Income)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _type == 'income' ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: isEditing
                            ? null
                            : () {
                                setState(() {
                                  _type = 'expense';
                                  _categoryCtrl.clear();
                                });
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _type == 'expense' ? const Color(0xFFDC2626) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.arrowUpRight,
                                  size: 16,
                                  color: _type == 'expense' ? Colors.white : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kas Keluar (Expense)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _type == 'expense' ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Akun Kas / Bank
              DropdownButtonFormField<int>(
                initialValue: _selectedAccountId,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Akun Kas / Bank *',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: const Icon(LucideIcons.landmark, size: 18, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                hint: const Text('Pilih Akun Kas / Bank', maxLines: 1, overflow: TextOverflow.ellipsis),
                items: masterProvider.accounts
                    .map(
                      (a) => DropdownMenuItem<int>(
                        value: a.id,
                        child: Text(
                          '${a.name} (${CurrencyFormatter.format(a.currentBalance)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                validator: (val) => val == null ? 'Pilih akun kas' : null,
              ),
              const SizedBox(height: 14),

              // Nominal
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Jumlah Nominal (Rp) *',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  prefixIcon: const Icon(LucideIcons.coins, size: 18, color: Color(0xFF64748B)),
                  hintText: '0',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Masukkan nominal';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Nominal harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Kategori
              TextFormField(
                controller: _categoryCtrl,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Kategori Transaksi *',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: const Icon(LucideIcons.tag, size: 18, color: Color(0xFF64748B)),
                  hintText: 'Contoh: Beban Listrik, Gaji, Pemasukan Servis...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Kategori wajib diisi' : null,
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Rekomendasi Kategori:',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.take(6).map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(cat, style: const TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          onPressed: () => setState(() => _categoryCtrl.text = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Tanggal Transaksi
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Transaksi *',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppDateFormatter.format(_transactionDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Keterangan
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Keterangan / Catatan (Opsional)',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'Tambahkan catatan detail...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: cashFlowProvider.isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final payload = {
                            'account_id': _selectedAccountId,
                            'type': _type,
                            'category': _categoryCtrl.text.trim(),
                            'amount': double.parse(_amountCtrl.text.trim()),
                            'transaction_date': DateFormat('yyyy-MM-dd').format(_transactionDate),
                            'description': _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
                          };

                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);

                          bool success;
                          if (isEditing) {
                            success = await cashFlowProvider.updateCashFlow(widget.editItem!.id, payload);
                          } else {
                            success = await cashFlowProvider.createCashFlow(payload);
                          }

                          if (success) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Arus kas berhasil diperbarui'
                                      : 'Arus kas berhasil disimpan',
                                ),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  cashFlowProvider.errorMessage ?? 'Gagal menyimpan transaksi',
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          }
                        },
                  child: cashFlowProvider.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Simpan Perubahan' : 'Simpan Transaksi',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
