import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/stock_transfer_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_transfer_detail_screen.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_transfer_form_screen.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class StockTransfersListScreen extends StatefulWidget {
  const StockTransfersListScreen({super.key});

  @override
  State<StockTransfersListScreen> createState() => _StockTransfersListScreenState();
}

class _StockTransfersListScreenState extends State<StockTransfersListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProv = context.read<StockProvider>();
      final masterProv = context.read<MasterDataProvider>();
      masterProv.fetchWarehouses();
      stockProv.fetchTransfers();
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
    final masterProv = context.read<MasterDataProvider>();
    final stockProv = context.read<StockProvider>();
    final warehouses = masterProv.warehouses;

    int? tempFrom = stockProv.fromWarehouseFilter;
    int? tempTo = stockProv.toWarehouseFilter;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                          'Filter Transfer Gudang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            stockProv.clearFilters();
                            stockProv.setTransferStatusFilter(null);
                            _searchCtrl.clear();
                            Navigator.pop(modalCtx);
                          },
                          child: const Text('Reset', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Origin Warehouse filter
                    const Text('Gudang Asal (Pengirim)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: tempFrom,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      hint: const Text('Semua Gudang Asal', style: TextStyle(fontSize: 12.5)),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Semua Gudang Asal', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ),
                        ...warehouses.map((w) => DropdownMenuItem<int?>(
                              value: w.id,
                              child: Text(w.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            )),
                      ],
                      onChanged: (val) {
                        setModalState(() => tempFrom = val);
                      },
                    ),

                    const SizedBox(height: 14),

                    // Destination Warehouse filter
                    const Text('Gudang Tujuan (Penerima)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: tempTo,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      hint: const Text('Semua Gudang Tujuan', style: TextStyle(fontSize: 12.5)),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Semua Gudang Tujuan', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ),
                        ...warehouses.map((w) => DropdownMenuItem<int?>(
                              value: w.id,
                              child: Text(w.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            )),
                      ],
                      onChanged: (val) {
                        setModalState(() => tempTo = val);
                      },
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          stockProv.setTransferWarehouseFilters(fromWarehouseId: tempFrom, toWarehouseId: tempTo);
                          Navigator.pop(modalCtx);
                        },
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

  Widget _buildStatusFilterChip(String label, String? value, String? selectedVal, Function(String?) onTap) {
    final isSelected = selectedVal == value;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final transfers = stockProv.transfers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer Antar Gudang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Distribusi & mutasi stok antar lokasi/cabang',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter, color: Colors.white, size: 19),
            tooltip: 'Filter Dokumen',
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
            tooltip: 'Refresh',
            onPressed: () => stockProv.fetchTransfers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plusCircle, size: 20),
        label: const Text('Transfer Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockTransferFormScreen()),
          ).then((_) {
            if (context.mounted) {
              context.read<StockProvider>().fetchTransfers();
            }
          });
        },
      ),
      body: Column(
        children: [
          // Search & Fast Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nomor transfer / catatan / nomor ref...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          stockProv.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => stockProv.setSearchQuery(val),
            ),
          ),

          // Status Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusFilterChip('Semua Status', null, stockProv.transferStatusFilter, (v) => stockProv.setTransferStatusFilter(v)),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('Draft', 'draft', stockProv.transferStatusFilter, (v) => stockProv.setTransferStatusFilter(v)),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('Dalam Pengiriman', 'in_transit', stockProv.transferStatusFilter, (v) => stockProv.setTransferStatusFilter(v)),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('Selesai', 'completed', stockProv.transferStatusFilter, (v) => stockProv.setTransferStatusFilter(v)),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('Dibatalkan', 'cancelled', stockProv.transferStatusFilter, (v) => stockProv.setTransferStatusFilter(v)),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // List Body
          Expanded(
            child: stockProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : transfers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.arrowRightLeft, size: 48, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum Ada Dokumen Transfer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Buat dokumen transfer baru untuk memindahkan stok antar gudang',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => stockProv.fetchTransfers(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                          itemCount: transfers.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, idx) {
                            final tr = transfers[idx];
                            return _buildTransferCard(tr);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(StockTransferModel tr) {
    Color badgeColor;
    Color badgeTextColor;
    String statusLabel = tr.statusLabel;
    IconData statusIcon = LucideIcons.fileText;

    if (tr.isDraft) {
      badgeColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
      statusIcon = LucideIcons.fileEdit;
    } else if (tr.isInTransit) {
      badgeColor = const Color(0xFFE0E7FF);
      badgeTextColor = const Color(0xFF4F46E5);
      statusIcon = LucideIcons.truck;
    } else if (tr.isCompleted) {
      badgeColor = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
      statusIcon = LucideIcons.checkCircle2;
    } else {
      badgeColor = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
      statusIcon = LucideIcons.xCircle;
    }

    String formattedDate = tr.transferDate;
    try {
      final d = DateTime.parse(tr.transferDate);
      formattedDate = DateFormat('dd MMM yyyy').format(d);
    } catch (_) {}

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockTransferDetailScreen(transferId: tr.id),
          ),
        ).then((_) {
          if (mounted) {
            context.read<StockProvider>().fetchTransfers();
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.arrowRightLeft, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.transferNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: badgeTextColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: badgeTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Route Bar: Origin -> Destination
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEF2F6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DARI', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(
                          tr.fromWarehouseName,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(LucideIcons.arrowRight, size: 16, color: Color(0xFF94A3B8)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TUJUAN', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(
                          tr.toWarehouseName,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  const Icon(LucideIcons.package, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 5),
                  Text(
                    '${tr.totalItemsCount} Produk (${_formatQty(tr.totalQuantitySent)} unit)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const Spacer(),
                  const Text(
                    'Detail',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(width: 2),
                  const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
