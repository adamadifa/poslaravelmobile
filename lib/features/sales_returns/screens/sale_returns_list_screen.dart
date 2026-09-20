import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/sale_return_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/sales_returns/providers/sale_return_provider.dart';
import 'package:poslaravelmobile/features/sales_returns/screens/create_sale_return_screen.dart';

class SaleReturnsListScreen extends StatefulWidget {
  const SaleReturnsListScreen({super.key});

  @override
  State<SaleReturnsListScreen> createState() => _SaleReturnsListScreenState();
}

class _SaleReturnsListScreenState extends State<SaleReturnsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final retProv = context.read<SaleReturnProvider>();
      final masterProv = context.read<MasterDataProvider>();

      masterProv.fetchWarehouses();
      retProv.fetchReturns();
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

  void _showFilterModal() {
    final retProv = context.read<SaleReturnProvider>();
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
                          'Filter Retur Penjualan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            retProv.resetFilters();
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
                      initialValue: warehouses.any((w) => w.id == retProv.warehouseFilter)
                          ? retProv.warehouseFilter
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
                        retProv.setWarehouse(val);
                        setModalState(() {});
                      },
                    ),

                    const SizedBox(height: 14),

                    // Date Filter Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rentang Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        if (retProv.startDate != null || retProv.endDate != null)
                          GestureDetector(
                            onTap: () {
                              retProv.setDateRange(null, null);
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
                          retProv.setDateRange(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day));
                          setModalState(() {});
                        }, _isTodayRange(retProv.startDate, retProv.endDate)),
                        const SizedBox(width: 6),
                        _buildDatePresetChip('7 Hari', () {
                          final now = DateTime.now();
                          retProv.setDateRange(now.subtract(const Duration(days: 6)), now);
                          setModalState(() {});
                        }, _is7DaysRange(retProv.startDate, retProv.endDate)),
                        const SizedBox(width: 6),
                        _buildDatePresetChip('Bulan Ini', () {
                          final now = DateTime.now();
                          retProv.setDateRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
                          setModalState(() {});
                        }, _isThisMonthRange(retProv.startDate, retProv.endDate)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Custom Date Picker Trigger
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: retProv.startDate != null && retProv.endDate != null
                              ? DateTimeRange(start: retProv.startDate!, end: retProv.endDate!)
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
                          retProv.setDateRange(picked.start, picked.end);
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
                                retProv.startDate != null && retProv.endDate != null
                                    ? '${retProv.startDate!.day}/${retProv.startDate!.month}/${retProv.startDate!.year} - ${retProv.endDate!.day}/${retProv.endDate!.month}/${retProv.endDate!.year}'
                                    : 'Pilih rentang tanggal khusus...',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: retProv.startDate != null ? FontWeight.w700 : FontWeight.w500,
                                  color: retProv.startDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Status filter
                    const Text('Status Dokumen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildFilterOptionChip('Semua', 'all', retProv.statusFilter, (m) {
                          retProv.setStatus(m);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 6),
                        _buildFilterOptionChip('Selesai', 'completed', retProv.statusFilter, (m) {
                          retProv.setStatus(m);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 6),
                        _buildFilterOptionChip('Dibatalkan', 'cancelled', retProv.statusFilter, (m) {
                          retProv.setStatus(m);
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

  Widget _buildQuickMethodChip(String label, String value, String selectedVal, Function(String) onTap) {
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

  void _showReturnDetailSheet(SaleReturnModel ret) {
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
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(LucideIcons.rotateCcw, color: Color(0xFFDC2626), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ret.returnNumber,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            'Inv: ${ret.invoiceNumber ?? "-"} • ${ret.returnDate ?? ret.createdAt ?? "-"}',
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

                _buildModalMetaRow('Pelanggan', ret.customerName),
                const SizedBox(height: 4),
                _buildModalMetaRow('Gudang Restock', ret.warehouseName),
                const SizedBox(height: 4),
                _buildModalMetaRow('Metode Refund', ret.refundMethod.toUpperCase(), isHighlight: true),
                const SizedBox(height: 4),
                _buildModalMetaRow('Alasan Retur', ret.reason),
                if (ret.notes != null && ret.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildModalMetaRow('Catatan', ret.notes!),
                ],
                const SizedBox(height: 12),

                // Item list
                const Text(
                  'Daftar Barang yang Diretur',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: ret.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (c, i) {
                      final it = ret.items[i];
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(it.subtotal),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
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

                _buildModalMetaRow('Total Refund Dana', CurrencyFormatter.format(ret.refundAmount), isBold: true, color: const Color(0xFFDC2626)),
                const SizedBox(height: 16),

                Row(
                  children: [
                    if (ret.status == 'completed') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(LucideIcons.xCircle, size: 16, color: Color(0xFFDC2626)),
                          label: const Text('Batalkan Retur', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 12.5)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            _confirmCancelReturn(ret);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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

  void _confirmCancelReturn(SaleReturnModel ret) {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Batalkan Retur Penjualan?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Text(
            'Apakah Anda yakin ingin membatalkan retur ${ret.returnNumber}? Mutasi stok barang akan dikembalikan ke posisi sebelum retur.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () async {
                Navigator.pop(dCtx);
                final retProv = context.read<SaleReturnProvider>();
                try {
                  await retProv.deleteSaleReturn(ret.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Retur ${ret.returnNumber} berhasil dibatalkan.'), backgroundColor: const Color(0xFF059669)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
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
    final retProv = context.watch<SaleReturnProvider>();
    final returnsResult = retProv.returnsResult;
    final summary = returnsResult?.summary;
    final returnList = returnsResult?.returns ?? [];

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
            Text('Retur Penjualan (Sales Return)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Colors.white)),
            Text('Kelola pengembalian barang pelanggan & refund', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
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
            onPressed: () => retProv.fetchReturns(),
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
                  onChanged: (val) => retProv.setSearch(val),
                  decoration: InputDecoration(
                    hintText: 'Cari nomor retur, invoice, nama pelanggan...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchCtrl.clear();
                              retProv.setSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),

              // Quick Method Filter Pills
              Container(
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildQuickMethodChip('Semua Metode', 'all', retProv.refundMethodFilter, (m) => retProv.setRefundMethod(m)),
                    const SizedBox(width: 6),
                    _buildQuickMethodChip('Pengembalian Tunai', 'cash', retProv.refundMethodFilter, (m) => retProv.setRefundMethod(m)),
                    const SizedBox(width: 6),
                    _buildQuickMethodChip('Potong Piutang', 'credit_deduction', retProv.refundMethodFilter, (m) => retProv.setRefundMethod(m)),
                    const SizedBox(width: 6),
                    _buildQuickMethodChip('Tukar Barang', 'exchange', retProv.refundMethodFilter, (m) => retProv.setRefundMethod(m)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFEA580C),
        elevation: 4,
        icon: const Icon(LucideIcons.plusCircle, color: Colors.white, size: 19),
        label: const Text('Buat Retur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSaleReturnScreen()),
          );
        },
      ),
      body: retProv.isLoading && returnsResult == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => retProv.fetchReturns(),
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
                                const Text('TOTAL REFUND', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626), letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    CurrencyFormatter.format(summary.totalRefund),
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
                                const Text('ITEM DIRETUR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${_formatQty(summary.totalItemsReturned)} Unit',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                            retProv.startDate != null && retProv.endDate != null
                                ? 'Periode: ${retProv.startDate!.day}/${retProv.startDate!.month}/${retProv.startDate!.year} - ${retProv.endDate!.day}/${retProv.endDate!.month}/${retProv.endDate!.year}'
                                : 'Periode: Semua Tanggal',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              initialDateRange: retProv.startDate != null && retProv.endDate != null
                                  ? DateTimeRange(start: retProv.startDate!, end: retProv.endDate!)
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
                              retProv.setDateRange(picked.start, picked.end);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text('Ubah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFEA580C))),
                          ),
                        ),
                        if (retProv.startDate != null || retProv.endDate != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => retProv.setDateRange(null, null),
                            child: const Icon(LucideIcons.x, size: 14, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (returnList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(30)),
                              child: const Icon(LucideIcons.rotateCcw, size: 28, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 14),
                            const Text('Belum ada transaksi retur penjualan.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            const Text('Ketuk tombol "Buat Retur" di bawah untuk memproses retur barang dari invoice.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    )
                  else
                    ...returnList.map((ret) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildReturnCard(ret),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildReturnCard(SaleReturnModel ret) {
    final isCompleted = ret.status == 'completed';

    return InkWell(
      onTap: () => _showReturnDetailSheet(ret),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.rotateCcw,
                        size: 15,
                        color: isCompleted ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ret.returnNumber,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    isCompleted ? 'Selesai' : 'Dibatalkan',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inv: ${ret.invoiceNumber ?? "-"} • ${ret.customerName}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Alasan: ${ret.reason}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ret.returnDate ?? ret.createdAt ?? "-"} • ${ret.refundMethod.toUpperCase()}',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Refund', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                    Text(
                      CurrencyFormatter.format(ret.refundAmount),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
