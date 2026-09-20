import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/sale_model.dart';
import 'package:poslaravelmobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  State<TransactionsHistoryScreen> createState() => _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashProv = context.read<DashboardProvider>();
      final masterProv = context.read<MasterDataProvider>();

      masterProv.fetchWarehouses();
      dashProv.fetchSalesHistory();
    });
  }

  @override
  void dispose() {
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
    final dash = context.read<DashboardProvider>();
    final masterProv = context.read<MasterDataProvider>();
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
                          'Filter Riwayat Penjualan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            dash.resetSalesFilters();
                            _searchCtrl.clear();
                            Navigator.pop(modalCtx);
                          },
                          child: const Text('Reset', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Warehouse filter
                    const Text('Gudang / Cabang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: warehouses.any((w) => w.id == dash.salesWarehouseId)
                          ? dash.salesWarehouseId
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
                        dash.setSalesWarehouse(val);
                        setModalState(() {});
                      },
                    ),

                    const SizedBox(height: 14),

                    // Date Filter Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rentang Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        if (dash.salesStartDate != null || dash.salesEndDate != null)
                          GestureDetector(
                            onTap: () {
                              dash.setSalesDateRange(null, null);
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
                          dash.setSalesDateRange(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day));
                          setModalState(() {});
                        }, _isTodayRange(dash.salesStartDate, dash.salesEndDate)),
                        const SizedBox(width: 6),
                        _buildDatePresetChip('7 Hari', () {
                          final now = DateTime.now();
                          dash.setSalesDateRange(now.subtract(const Duration(days: 6)), now);
                          setModalState(() {});
                        }, _is7DaysRange(dash.salesStartDate, dash.salesEndDate)),
                        const SizedBox(width: 6),
                        _buildDatePresetChip('Bulan Ini', () {
                          final now = DateTime.now();
                          dash.setSalesDateRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
                          setModalState(() {});
                        }, _isThisMonthRange(dash.salesStartDate, dash.salesEndDate)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Custom Date Picker Trigger
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: dash.salesStartDate != null && dash.salesEndDate != null
                              ? DateTimeRange(start: dash.salesStartDate!, end: dash.salesEndDate!)
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
                          dash.setSalesDateRange(picked.start, picked.end);
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
                                dash.salesStartDate != null && dash.salesEndDate != null
                                    ? '${dash.salesStartDate!.day}/${dash.salesStartDate!.month}/${dash.salesStartDate!.year} - ${dash.salesEndDate!.day}/${dash.salesEndDate!.month}/${dash.salesEndDate!.year}'
                                    : 'Pilih rentang tanggal khusus...',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: dash.salesStartDate != null ? FontWeight.w700 : FontWeight.w500,
                                  color: dash.salesStartDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Payment Method filter
                    const Text('Metode Pembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildFilterOptionChip('Semua', 'all', dash.salesPaymentMethod, (m) {
                          dash.setSalesPaymentMethod(m);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 6),
                        _buildFilterOptionChip('Tunai', 'cash', dash.salesPaymentMethod, (m) {
                          dash.setSalesPaymentMethod(m);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 6),
                        _buildFilterOptionChip('QRIS', 'qris', dash.salesPaymentMethod, (m) {
                          dash.setSalesPaymentMethod(m);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 6),
                        _buildFilterOptionChip('Transfer', 'transfer', dash.salesPaymentMethod, (m) {
                          dash.setSalesPaymentMethod(m);
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

  Widget _buildFilterOptionChip(String label, String value, String selectedVal, Function(String) onTap) {
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

  Widget _buildQuickPaymentChip(String label, String value, String selectedVal, Function(String) onTap) {
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

  void _showSaleDetailSheet(SaleModel sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(LucideIcons.receipt, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.invoiceNumber,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            '${sale.customerName} • ${sale.createdAt ?? sale.saleDate ?? "-"}',
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
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),

                // Info Meta Rows
                _buildModalMetaRow('Kasir', sale.cashierName),
                const SizedBox(height: 4),
                _buildModalMetaRow('Lokasi Gudang', sale.warehouseName),
                const SizedBox(height: 4),
                _buildModalMetaRow('Metode Pembayaran', sale.paymentMethod.toUpperCase(), isHighlight: true),
                const SizedBox(height: 12),

                // Item List
                const Text(
                  'Rincian Item Belanja',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sale.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (c, i) {
                      final it = sale.items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.productName,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                  Text(
                                    '${_formatQty(it.quantity)} ${it.unitName} x ${CurrencyFormatter.format(it.unitPrice)}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  if (it.notes != null && it.notes!.isNotEmpty)
                                    Text(
                                      'Catatan: ${it.notes}',
                                      style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(it.total),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 8),

                // Financial Summary
                if (sale.discountAmount > 0) ...[
                  _buildModalMetaRow('Diskon Penjualan', '-${CurrencyFormatter.format(sale.discountAmount)}', color: const Color(0xFFDC2626)),
                  const SizedBox(height: 4),
                ],
                if (sale.taxAmount > 0) ...[
                  _buildModalMetaRow('Pajak (PPN)', CurrencyFormatter.format(sale.taxAmount)),
                  const SizedBox(height: 4),
                ],
                _buildModalMetaRow('Grand Total', CurrencyFormatter.format(sale.grandTotal), isBold: true, color: AppColors.primary),
                const SizedBox(height: 4),
                _buildModalMetaRow('Nominal Bayar', CurrencyFormatter.format(sale.paidAmount)),
                if (sale.changeAmount > 0) ...[
                  const SizedBox(height: 4),
                  _buildModalMetaRow('Kembalian', CurrencyFormatter.format(sale.changeAmount), color: const Color(0xFF059669)),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(LucideIcons.printer, size: 16, color: Color(0xFF1E293B)),
                        label: const Text('Cetak Struk', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 12.5)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Perintah cetak faktur ${sale.invoiceNumber} dikirim ke printer thermal.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalMetaRow(String label, String value, {bool isBold = false, bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color ?? (isHighlight ? const Color(0xFF2563EB) : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final salesHistory = dash.salesHistory;
    final summary = salesHistory?.summary;
    final salesList = salesHistory?.sales ?? [];

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
            Text('Riwayat Transaksi Penjualan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Colors.white)),
            Text('Daftar faktur kasir, pembayaran, & struk transaksi', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
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
            onPressed: () => dash.fetchSalesHistory(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: Column(
            children: [
              // Search Bar
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
                  onChanged: (val) => dash.setSalesSearch(val),
                  decoration: InputDecoration(
                    hintText: 'Cari nomor faktur, nama pelanggan...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchCtrl.clear();
                              dash.setSalesSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),

              // Quick Filter Pills
              Container(
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildQuickPaymentChip('Semua', 'all', dash.salesPaymentMethod, (m) => dash.setSalesPaymentMethod(m)),
                    const SizedBox(width: 6),
                    _buildQuickPaymentChip('Tunai (Cash)', 'cash', dash.salesPaymentMethod, (m) => dash.setSalesPaymentMethod(m)),
                    const SizedBox(width: 6),
                    _buildQuickPaymentChip('QRIS', 'qris', dash.salesPaymentMethod, (m) => dash.setSalesPaymentMethod(m)),
                    const SizedBox(width: 6),
                    _buildQuickPaymentChip('Transfer Bank', 'transfer', dash.salesPaymentMethod, (m) => dash.setSalesPaymentMethod(m)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      body: dash.isLoadingSales && salesHistory == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => dash.fetchSalesHistory(),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                children: [
                  // KPI Summary Card
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
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL OMZET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669), letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    CurrencyFormatter.format(summary.totalSalesAmount),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
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
                                const Text('TRANSAKSI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${summary.totalTransactionsCount} Trx',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

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
                            dash.salesStartDate != null && dash.salesEndDate != null
                                ? 'Periode: ${dash.salesStartDate!.day}/${dash.salesStartDate!.month}/${dash.salesStartDate!.year} - ${dash.salesEndDate!.day}/${dash.salesEndDate!.month}/${dash.salesEndDate!.year}'
                                : 'Periode: Semua Tanggal',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              initialDateRange: dash.salesStartDate != null && dash.salesEndDate != null
                                  ? DateTimeRange(start: dash.salesStartDate!, end: dash.salesEndDate!)
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
                              dash.setSalesDateRange(picked.start, picked.end);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text('Ubah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFEA580C))),
                          ),
                        ),
                        if (dash.salesStartDate != null || dash.salesEndDate != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => dash.setSalesDateRange(null, null),
                            child: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (salesList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(30)),
                              child: const Icon(LucideIcons.fileQuestion, size: 28, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 14),
                            const Text('Tidak ada riwayat transaksi.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            const Text(
                              'Transaksi kasir yang berhasil akan otomatis tercatat di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...salesList.map((sale) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildSaleCard(sale),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildSaleCard(SaleModel sale) {
    Color badgeBg;
    Color badgeColor;
    switch (sale.paymentMethod.toLowerCase()) {
      case 'cash':
        badgeBg = const Color(0xFFF0FDF4);
        badgeColor = const Color(0xFF16A34A);
        break;
      case 'qris':
        badgeBg = const Color(0xFFEFF6FF);
        badgeColor = const Color(0xFF2563EB);
        break;
      case 'transfer':
        badgeBg = const Color(0xFFFAF5FF);
        badgeColor = const Color(0xFF9333EA);
        break;
      default:
        badgeBg = const Color(0xFFFFFBEB);
        badgeColor = const Color(0xFFD97706);
    }

    return InkWell(
      onTap: () => _showSaleDetailSheet(sale),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.receipt, color: Color(0xFFEA580C), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sale.customerName} • ${sale.createdAt ?? sale.saleDate ?? "-"}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(sale.grandTotal),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sale.paymentMethod.toUpperCase(),
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: badgeColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (sale.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF8FAFC)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.shoppingBag, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${sale.items.length} jenis item (${sale.items.fold(0.0, (acc, it) => acc + it.quantity).toStringAsFixed(0)} total qty)',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kasir: ${sale.cashierName}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
