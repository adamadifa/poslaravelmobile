import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/stock_adjustment_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_adjustment_form_screen.dart';

class StockAdjustmentDetailScreen extends StatefulWidget {
  final int adjustmentId;

  const StockAdjustmentDetailScreen({super.key, required this.adjustmentId});

  @override
  State<StockAdjustmentDetailScreen> createState() => _StockAdjustmentDetailScreenState();
}

class _StockAdjustmentDetailScreenState extends State<StockAdjustmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchAdjustmentDetail(widget.adjustmentId);
    });
  }

  String _formatNum(num? val) {
    if (val == null) return '0';
    final d = val.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _confirmApprove(StockAdjustmentModel adj) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(LucideIcons.checkCircle, color: Color(0xFF059669), size: 22),
          SizedBox(width: 8),
          Flexible(child: Text('Setujui Penyesuaian?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        ]),
        content: Text(
          'Sistem akan ${adj.isAddition ? 'menambahkan' : 'mengurangi'} stok di gudang ${adj.warehouseName} sesuai dokumen ${adj.adjustmentNumber}. Tindakan ini tidak dapat dibatalkan dengan mudah.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final stockProv = context.read<StockProvider>();
              final success = await stockProv.approveAdjustment(adj.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penyesuaian stok berhasil disetujui & stok telah disesuaikan.')));
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(stockProv.errorMessage ?? 'Gagal menyetujui penyesuaian stok.')));
              }
            },
            child: const Text('Ya, Setujui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(StockAdjustmentModel adj) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
          SizedBox(width: 8),
          Flexible(child: Text('Hapus / Batalkan?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        ]),
        content: Text(
          adj.isDraft
              ? 'Draft dokumen ${adj.adjustmentNumber} akan dihapus permanen.'
              : 'Dokumen ${adj.adjustmentNumber} akan dibatalkan dan stok dikembalikan (jika sudah disetujui).',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kembali', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final stockProv = context.read<StockProvider>();
              final success = await stockProv.deleteAdjustment(adj.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dokumen berhasil dihapus / dibatalkan.')));
                Navigator.pop(context);
              }
            },
            child: Text(adj.isDraft ? 'Hapus Draft' : 'Batalkan Dokumen', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final adj = stockProv.selectedAdjustment;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.chevronLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(adj?.adjustmentNumber ?? 'Detail Penyesuaian Stok', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
        actions: [
          if (adj != null && adj.canEdit)
            IconButton(
              icon: const Icon(LucideIcons.edit, color: Colors.white, size: 20),
              tooltip: 'Edit',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StockAdjustmentFormScreen(adjustment: adj)),
                ).then((_) => stockProv.fetchAdjustmentDetail(adj.id));
              },
            ),
          if (adj != null && !adj.isCancelled)
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 20, color: Color(0xFFFCA5A5)),
              tooltip: 'Hapus / Batalkan',
              onPressed: () => _confirmDelete(adj),
            ),
        ],
      ),
      bottomNavigationBar: (adj != null && adj.canEdit)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
              child: SafeArea(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _confirmApprove(adj),
                  icon: const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                  label: const Text('Setujui & Posting Penyesuaian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ),
            )
          : null,
      body: stockProv.isLoadingAdjustmentDetail
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : adj == null
              ? const Center(child: Text('Dokumen tidak ditemukan.'))
              : RefreshIndicator(
                  onRefresh: () => stockProv.fetchAdjustmentDetail(adj.id),
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header Card
                      _buildHeaderCard(adj),
                      const SizedBox(height: 14),

                      // Summary KPI
                      _buildSummaryKpi(adj),
                      const SizedBox(height: 16),

                      // Items
                      Text(
                        'Rincian Produk (${adj.items.length})',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      ...adj.items.map((item) => _buildItemCard(item, adj.isAddition)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(StockAdjustmentModel adj) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(adj.adjustmentNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: adj.statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: adj.statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(adj.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: adj.statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: adj.typeBgColor, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(adj.isAddition ? LucideIcons.plusCircle : LucideIcons.minusCircle, size: 14, color: adj.typeColor),
                const SizedBox(width: 6),
                Text(adj.typeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: adj.typeColor)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(LucideIcons.warehouse, 'Gudang', adj.warehouseName),
          const SizedBox(height: 6),
          _infoRow(LucideIcons.calendar, 'Tanggal Penyesuaian', AppDateFormatter.format(adj.adjustmentDate)),
          const SizedBox(height: 6),
          _infoRow(LucideIcons.helpCircle, 'Alasan', adj.reason),
          if (adj.creatorName != null) ...[
            const SizedBox(height: 6),
            _infoRow(LucideIcons.user, 'Dibuat Oleh', adj.creatorName!),
          ],
          if (adj.approverName != null) ...[
            const SizedBox(height: 6),
            _infoRow(LucideIcons.shieldCheck, 'Disetujui Oleh', '${adj.approverName} • ${AppDateFormatter.formatDateTime(adj.approvedAt)}'),
          ],
          if (adj.notes != null && adj.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.fileText, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(adj.notes!, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryKpi(StockAdjustmentModel adj) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL PRODUK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text('${adj.items.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL QTY', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(
                  '${adj.isAddition ? '+' : '-'}${_formatNum(adj.totalQuantity)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: adj.typeColor),
                ),
              ],
            ),
          ),
          Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL NILAI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(CurrencyFormatter.format(adj.totalValue), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: adj.typeColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(StockAdjustmentItemModel item, bool isAddition) {
    final typeColor = isAddition ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final typeBg = isAddition ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    if (item.productCode != null)
                      Text('Kode: ${item.productCode}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${isAddition ? '+' : '-'}${_formatNum(item.quantity)} ${item.unitName}',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: typeColor),
                ),
              ),
            ],
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Harga Modal: ${CurrencyFormatter.format(item.unitCost)}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Text('Nilai: ${CurrencyFormatter.format(item.totalCost)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: typeColor)),
            ],
          ),
          if (item.batchNumber != null && item.batchNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Batch: ${item.batchNumber}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))),
      ],
    );
  }
}
