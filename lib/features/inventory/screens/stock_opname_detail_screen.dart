import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/stock_opname_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_opname_form_screen.dart';

class StockOpnameDetailScreen extends StatefulWidget {
  final int opnameId;

  const StockOpnameDetailScreen({super.key, required this.opnameId});

  @override
  State<StockOpnameDetailScreen> createState() => _StockOpnameDetailScreenState();
}

class _StockOpnameDetailScreenState extends State<StockOpnameDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchOpnameDetail(widget.opnameId);
    });
  }

  String _formatQty(num? val) {
    if (val == null) return '0';
    final double d = val.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _confirmApprove(StockOpnameModel opname) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.checkCircle, color: Color(0xFF059669), size: 22),
            SizedBox(width: 8),
            Text('Setujui Stok Opname?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Sistem akan otomatis menyesuaikan stok fisik gudang ${opname.warehouseName} dan memposting mutasi kartu stok inventaris untuk dokumen ${opname.opnameNumber}. Tindakan ini tidak dapat dibatalkan.',
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
              final success = await stockProv.approveOpname(opname.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stok Opname berhasil disetujui & stok telah disinkronkan.')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(stockProv.errorMessage ?? 'Gagal menyetujui stok opname')),
                );
              }
            },
            child: const Text('Ya, Setujui & Posting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(StockOpnameModel opname) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Hapus / Batalkan?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          opname.isDraft
              ? 'Draft dokumen ${opname.opnameNumber} akan dihapus permanen.'
              : 'Dokumen ${opname.opnameNumber} akan dibatalkan.',
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
              final success = await stockProv.deleteOpname(opname.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(opname.isDraft ? 'Draft berhasil dihapus' : 'Stok opname berhasil dibatalkan')),
                );
                Navigator.pop(context);
              }
            },
            child: Text(
              opname.isDraft ? 'Hapus Draft' : 'Batalkan Dokumen',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final opname = stockProv.selectedOpname;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          opname?.opnameNumber ?? 'Detail Stok Opname',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
        ),
        actions: [
          if (opname != null && opname.canEdit)
            IconButton(
              icon: const Icon(LucideIcons.edit, color: Colors.white, size: 20),
              tooltip: 'Edit Dokumen',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockOpnameFormScreen(opname: opname),
                  ),
                ).then((_) => stockProv.fetchOpnameDetail(opname.id));
              },
            ),
          if (opname != null && !opname.isCompleted && !opname.isCancelled)
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 20, color: Color(0xFFFCA5A5)),
              tooltip: 'Hapus / Batalkan',
              onPressed: () => _confirmDelete(opname),
            ),
        ],
      ),
      bottomNavigationBar: (opname != null && opname.canEdit)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _confirmApprove(opname),
                  icon: const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                  label: const Text(
                    'Setujui & Posting Penyesuaian Stok',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ),
              ),
            )
          : null,
      body: stockProv.isLoadingOpnameDetail
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : (opname == null)
              ? const Center(child: Text('Dokumen Stok Opname tidak ditemukan.'))
              : RefreshIndicator(
                  onRefresh: () => stockProv.fetchOpnameDetail(opname.id),
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header Status & Meta Card
                      Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  opname.opnameNumber,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: opname.statusBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: opname.statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    opname.statusLabel,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: opname.statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildMetaRow(LucideIcons.warehouse, 'Gudang Lokasi', opname.warehouseName),
                            const SizedBox(height: 6),
                            _buildMetaRow(LucideIcons.calendar, 'Tanggal Audit', opname.opnameDate),
                            if (opname.conductorName != null) ...[
                              const SizedBox(height: 6),
                              _buildMetaRow(LucideIcons.userCheck, 'Petugas Audit', opname.conductorName!),
                            ],
                            if (opname.approverName != null) ...[
                              const SizedBox(height: 6),
                              _buildMetaRow(LucideIcons.shieldCheck, 'Disetujui Oleh', '${opname.approverName} (${opname.approvedAt ?? ''})'),
                            ],
                            if (opname.notes != null && opname.notes!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(LucideIcons.fileText, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        opname.notes!,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // KPI Audit Summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL ITEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text('${opname.totalItemsCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                            Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SELISIH FISIK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
                                  const SizedBox(height: 2),
                                  Text('${opname.diffItemsCount} Item', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEA580C))),
                                ],
                              ),
                            ),
                            Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('NET SELISIH QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${opname.totalDifferenceQty > 0 ? '+' : ''}${_formatQty(opname.totalDifferenceQty)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: opname.totalDifferenceQty > 0
                                          ? const Color(0xFF059669)
                                          : (opname.totalDifferenceQty < 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Items Breakdown Section
                      Text(
                        'Rincian Produk Audit (${opname.items.length})',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),

                      ...opname.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.hasDifference
                                  ? (item.isSurplus ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5))
                                  : const Color(0xFFE2E8F0),
                            ),
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
                                        Text(item.productName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                                        if (item.productCode != null)
                                          Text('Kode: ${item.productCode}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.isSurplus
                                          ? const Color(0xFFECFDF5)
                                          : (item.isDeficit ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.differenceQty > 0 ? '+' : ''}${_formatQty(item.differenceQty)} ${item.unitName}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: item.diffColor),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 14, color: Color(0xFFF1F5F9)),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sistem: ${_formatQty(item.systemQty)} ${item.unitName}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Fisik: ${_formatQty(item.physicalQty)} ${item.unitName}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w800),
                                  ),
                                  if (item.differenceValue != 0)
                                    Text(
                                      'Valuasi: ${CurrencyFormatter.format(item.differenceValue)}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: item.diffColor),
                                    ),
                                ],
                              ),

                              if (item.reason != null && item.reason!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.info, size: 12, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Alasan: ${item.reason}',
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        ),
      ],
    );
  }
}
