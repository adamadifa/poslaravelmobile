import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/purchase_return_model.dart';
import 'package:poslaravelmobile/features/purchasing/providers/purchasing_provider.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_return_form_screen.dart';

class PurchaseReturnsListScreen extends StatefulWidget {
  const PurchaseReturnsListScreen({super.key});

  @override
  State<PurchaseReturnsListScreen> createState() => _PurchaseReturnsListScreenState();
}

class _PurchaseReturnsListScreenState extends State<PurchaseReturnsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'all'; // all, confirmed, cancelled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchasingProvider>().fetchReturns();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openReturnForm() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PurchaseReturnFormScreen()),
    );
    if (res == true && mounted) {
      context.read<PurchasingProvider>().fetchReturns();
    }
  }

  void _showReturnDetail(PurchaseReturnModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.rotateCcw, color: Color(0xFFDC2626), size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.returnNumber,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.statusBgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.statusLabel,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: item.statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tgl: ${item.returnDate}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Info grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _buildDetailInfoRow('Pemasok (Supplier)', item.supplierName, LucideIcons.truck),
                    const SizedBox(height: 6),
                    _buildDetailInfoRow('Gudang Asal', item.warehouseName, LucideIcons.warehouse),
                    if (item.grnNumber != null) ...[
                      const SizedBox(height: 6),
                      _buildDetailInfoRow('No. GRN / Faktur', item.grnNumber!, LucideIcons.fileCheck),
                    ],
                    if (item.reason != null && item.reason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildDetailInfoRow('Alasan Retur', item.reason!, LucideIcons.alertCircle, isHighlight: true),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Daftar Produk Diretur (${item.items.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),

              // Items List
              Expanded(
                child: item.items.isEmpty
                    ? const Center(child: Text('Tidak ada rincian item.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))))
                    : ListView.separated(
                        itemCount: item.items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, idx) {
                          final it = item.items[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(LucideIcons.package, size: 16, color: Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.productName,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${it.quantity.toStringAsFixed(0)} ${it.unitName} @ ${CurrencyFormatter.format(it.unitCost)}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      if (it.batchNumber != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text('Batch: ${it.batchNumber}', style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(it.subtotal),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Total & Action Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Nilai Retur:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  Text(
                    CurrencyFormatter.format(item.totalAmount),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (item.status.toLowerCase() == 'confirmed')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmCancelReturn(item);
                    },
                    icon: const Icon(LucideIcons.xCircle, size: 16),
                    label: const Text('Batalkan Retur (Kembalikan Stok)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailInfoRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: isHighlight ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isHighlight ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _confirmCancelReturn(PurchaseReturnModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Batalkan Retur?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan Retur "${item.returnNumber}"?\n\nStok produk yang diretur akan otomatis dikembalikan ke gudang ${item.warehouseName}.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final prov = context.read<PurchasingProvider>();
              final ok = await prov.deleteReturn(item.id);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Retur ${item.returnNumber} berhasil dibatalkan dan stok dipulihkan.'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Retur Pembelian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Pengembalian barang rusak/cacat ke pemasok',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nomor retur (PR-...), supplier...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<PurchasingProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading && provider.returns.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
          }

          final query = _searchCtrl.text.toLowerCase().trim();
          var list = provider.returns;

          if (_statusFilter != 'all') {
            list = list.where((r) => r.status.toLowerCase() == _statusFilter).toList();
          }

          if (query.isNotEmpty) {
            list = list.where((r) {
              final pr = r.returnNumber.toLowerCase();
              final supp = r.supplierName.toLowerCase();
              final grn = (r.grnNumber ?? '').toLowerCase();
              final reason = (r.reason ?? '').toLowerCase();
              return pr.contains(query) || supp.contains(query) || grn.contains(query) || reason.contains(query);
            }).toList();
          }

          final totalReturnValue = list.fold<double>(0, (sum, r) => sum + r.totalAmount);

          return RefreshIndicator(
            onRefresh: () => provider.fetchReturns(),
            color: const Color(0xFFDC2626),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              children: [
                // KPI Stats Card
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
                            const Text(
                              'TOTAL NILAI RETUR',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              CurrencyFormatter.format(totalReturnValue),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRANSAKSI',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${list.length} Retur',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 'all', provider.returns.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Selesai', 'confirmed', provider.returns.where((r) => r.status.toLowerCase() == 'confirmed').length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Dibatalkan', 'cancelled', provider.returns.where((r) => r.status.toLowerCase() == 'cancelled').length),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (list.isEmpty) ...[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(35)),
                          child: const Icon(LucideIcons.rotateCcw, size: 32, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isNotEmpty ? 'Tidak ada retur yang cocok' : 'Belum Ada Retur Pembelian',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          query.isNotEmpty ? 'Coba ubah kata kunci pencarian.' : 'Catat pengembalian barang rusak atau cacat ke supplier.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            elevation: 0,
                          ),
                          onPressed: () => _openReturnForm(),
                          icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                          label: const Text('Buat Retur Pembelian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...list.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildReturnCard(item),
                      )),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFDC2626),
        elevation: 3,
        onPressed: () => _openReturnForm(),
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
        label: const Text('Catat Retur', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDC2626) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x33FFFFFF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnCard(PurchaseReturnModel item) {
    return InkWell(
      onTap: () => _showReturnDetail(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.rotateCcw, color: Color(0xFFDC2626), size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.returnNumber,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: item.statusBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.statusLabel,
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: item.statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.supplierName,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Value & Warehouse Box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NILAI RETUR',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(item.totalAmount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.warehouse, size: 11, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(item.warehouseName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.reason != null && item.reason!.isNotEmpty
                          ? 'Tgl: ${item.returnDate} (${item.reason})'
                          : 'Tgl: ${item.returnDate}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${item.items.length} Item Diretur', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
