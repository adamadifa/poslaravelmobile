import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/stock_adjustment_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_adjustment_detail_screen.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_adjustment_form_screen.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class StockAdjustmentsListScreen extends StatefulWidget {
  const StockAdjustmentsListScreen({super.key});

  @override
  State<StockAdjustmentsListScreen> createState() => _StockAdjustmentsListScreenState();
}

class _StockAdjustmentsListScreenState extends State<StockAdjustmentsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchWarehouses();
      context.read<StockProvider>().fetchAdjustments();
    });
  }

  @override
  void dispose() {
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
                        const Text('Filter Penyesuaian Stok',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            stockProv.clearFilters();
                            stockProv.setAdjustmentStatusFilter(null);
                            stockProv.setAdjustmentTypeFilter(null);
                            _searchCtrl.clear();
                            Navigator.pop(modalCtx);
                          },
                          child: const Text('Reset', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Warehouse filter
                    const Text('Gudang Lokasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: stockProv.selectedWarehouseId,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      hint: const Text('Semua Gudang', style: TextStyle(fontSize: 12.5)),
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

                    // Tipe Penyesuaian
                    const Text('Jenis Penyesuaian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('Semua', null, stockProv.adjustmentTypeFilter, (val) {
                          stockProv.setAdjustmentTypeFilter(val);
                          setModalState(() {});
                        }),
                        _buildFilterChip('Penambahan (+)', 'addition', stockProv.adjustmentTypeFilter, (val) {
                          stockProv.setAdjustmentTypeFilter(val);
                          setModalState(() {});
                        }),
                        _buildFilterChip('Pengurangan (-)', 'reduction', stockProv.adjustmentTypeFilter, (val) {
                          stockProv.setAdjustmentTypeFilter(val);
                          setModalState(() {});
                        }),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Status
                    const Text('Status Dokumen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('Semua', null, stockProv.adjustmentStatusFilter, (val) {
                          stockProv.setAdjustmentStatusFilter(val);
                          setModalState(() {});
                        }),
                        _buildFilterChip('Draft', 'draft', stockProv.adjustmentStatusFilter, (val) {
                          stockProv.setAdjustmentStatusFilter(val);
                          setModalState(() {});
                        }),
                        _buildFilterChip('Disetujui', 'approved', stockProv.adjustmentStatusFilter, (val) {
                          stockProv.setAdjustmentStatusFilter(val);
                          setModalState(() {});
                        }),
                        _buildFilterChip('Dibatalkan', 'cancelled', stockProv.adjustmentStatusFilter, (val) {
                          stockProv.setAdjustmentStatusFilter(val);
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
                        onPressed: () {
                          stockProv.fetchAdjustments();
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

  Widget _buildFilterChip(String label, String? value, String? selectedVal, Function(String?) onTap) {
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
    final adjustments = stockProv.adjustments;

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
            Text('Penyesuaian Stok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('Tambah / kurangi stok secara manual', style: TextStyle(fontSize: 11, color: Colors.white70)),
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
            tooltip: 'Refresh',
            onPressed: () => stockProv.fetchAdjustments(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plusCircle, size: 20),
        label: const Text('Penyesuaian Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockAdjustmentFormScreen()),
          ).then((_) => stockProv.fetchAdjustments());
        },
      ),
      body: Column(
        children: [
          // Search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nomor / alasan penyesuaian...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          stockProv.setSearchQuery('');
                          stockProv.fetchAdjustments();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              onSubmitted: (val) {
                stockProv.setSearchQuery(val);
                stockProv.fetchAdjustments();
              },
            ),
          ),

          // List
          Expanded(
            child: stockProv.isLoading && adjustments.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () => stockProv.fetchAdjustments(),
                    color: AppColors.primary,
                    child: adjustments.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 80, horizontal: 20),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(LucideIcons.slidersHorizontal, size: 48, color: Color(0xFFCBD5E1)),
                                      SizedBox(height: 12),
                                      Text(
                                        'Belum Ada Penyesuaian Stok',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Buat penyesuaian baru untuk menambah atau mengurangi stok secara manual.',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: adjustments.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) => _buildCard(adjustments[idx]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(StockAdjustmentModel adj) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StockAdjustmentDetailScreen(adjustmentId: adj.id)),
        );
        if (mounted) context.read<StockProvider>().fetchAdjustments();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Number + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    adj.adjustmentNumber,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: adj.statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: adj.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(adj.statusLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: adj.statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Type badge + Warehouse + Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: adj.typeBgColor, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(adj.isAddition ? LucideIcons.plusCircle : LucideIcons.minusCircle, size: 11, color: adj.typeColor),
                      const SizedBox(width: 4),
                      Text(
                        adj.isAddition ? 'Penambahan' : 'Pengurangan',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: adj.typeColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.warehouse, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(child: Text(adj.warehouseName, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(AppDateFormatter.format(adj.adjustmentDate), style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
            const Divider(height: 14, color: Color(0xFFF1F5F9)),

            // Row 3: Items + Value + Reason
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.packageCheck, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text('${adj.items.length} Produk', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(adj.totalValue),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: adj.typeColor),
                ),
              ],
            ),
            if (adj.reason.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Alasan: ${adj.reason}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
