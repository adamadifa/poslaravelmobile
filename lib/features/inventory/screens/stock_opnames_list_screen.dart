import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/data/models/stock_opname_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_opname_detail_screen.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_opname_form_screen.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class StockOpnamesListScreen extends StatefulWidget {
  const StockOpnamesListScreen({super.key});

  @override
  State<StockOpnamesListScreen> createState() => _StockOpnamesListScreenState();
}

class _StockOpnamesListScreenState extends State<StockOpnamesListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProv = context.read<StockProvider>();
      final masterProv = context.read<MasterDataProvider>();
      masterProv.fetchWarehouses();
      stockProv.fetchOpnames();
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
                          'Filter Stok Opname',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            stockProv.clearFilters();
                            stockProv.setOpnameStatusFilter(null);
                            _searchCtrl.clear();
                            Navigator.pop(modalCtx);
                          },
                          child: const Text('Reset', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Warehouse filter
                    const Text('Gudang Lokasi Audit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: stockProv.selectedWarehouseId,
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

                    // Status Chips
                    const Text('Status Dokumen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusFilterChip('Semua', null, stockProv.opnameStatusFilter, (val) {
                          stockProv.setOpnameStatusFilter(val);
                          setModalState(() {});
                        }),
                        _buildStatusFilterChip('Draft', 'draft', stockProv.opnameStatusFilter, (val) {
                          stockProv.setOpnameStatusFilter(val);
                          setModalState(() {});
                        }),
                        _buildStatusFilterChip('In Progress', 'in_progress', stockProv.opnameStatusFilter, (val) {
                          stockProv.setOpnameStatusFilter(val);
                          setModalState(() {});
                        }),
                        _buildStatusFilterChip('Selesai', 'completed', stockProv.opnameStatusFilter, (val) {
                          stockProv.setOpnameStatusFilter(val);
                          setModalState(() {});
                        }),
                        _buildStatusFilterChip('Dibatalkan', 'cancelled', stockProv.opnameStatusFilter, (val) {
                          stockProv.setOpnameStatusFilter(val);
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
                          stockProv.fetchOpnames();
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
    final opnames = stockProv.opnames;

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
              'Stok Opname',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Audit fisik vs sistem & rekonsiliasi stok',
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
            onPressed: () => stockProv.fetchOpnames(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plusCircle, size: 20),
        label: const Text('Audit Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockOpnameFormScreen()),
          ).then((_) => stockProv.fetchOpnames());
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
                hintText: 'Cari nomor opname / catatan...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          stockProv.setSearchQuery('');
                          stockProv.fetchOpnames();
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
                stockProv.fetchOpnames();
              },
            ),
          ),

          // Main List
          Expanded(
            child: stockProv.isLoading && opnames.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () => stockProv.fetchOpnames(),
                    color: AppColors.primary,
                    child: opnames.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 80, horizontal: 20),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(LucideIcons.clipboardCheck, size: 48, color: Color(0xFFCBD5E1)),
                                      SizedBox(height: 12),
                                      Text(
                                        'Belum Ada Dokumen Stok Opname',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Mulai audit stok fisik dengan menekan tombol "+ Audit Baru".',
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
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: opnames.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final op = opnames[idx];
                              return _buildOpnameCard(op);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpnameCard(StockOpnameModel op) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StockOpnameDetailScreen(opnameId: op.id)),
        );
        if (mounted) {
          context.read<StockProvider>().fetchOpnames();
        }
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
            // Row 1: Opname Number & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  op.opnameNumber,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: op.statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: op.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    op.statusLabel,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: op.statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Warehouse & Date
            Row(
              children: [
                const Icon(LucideIcons.warehouse, size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 5),
                Text(op.warehouseName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(width: 10),
                const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                const SizedBox(width: 10),
                const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Text(op.opnameDate, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),

            // Row 3: Items count & Net Diff
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.packageCheck, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '${op.totalItemsCount} Produk',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    if (op.diffItemsCount > 0)
                      Text(
                        ' (${op.diffItemsCount} selisih)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEA580C)),
                      ),
                  ],
                ),
                Text(
                  'Selisih: ${op.totalDifferenceQty > 0 ? '+' : ''}${_formatQty(op.totalDifferenceQty)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: op.totalDifferenceQty > 0
                        ? const Color(0xFF059669)
                        : (op.totalDifferenceQty < 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
