import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/stock_transfer_model.dart';
import 'package:poslaravelmobile/features/inventory/providers/stock_provider.dart';

class StockTransferDetailScreen extends StatefulWidget {
  final int transferId;

  const StockTransferDetailScreen({super.key, required this.transferId});

  @override
  State<StockTransferDetailScreen> createState() => _StockTransferDetailScreenState();
}

class _StockTransferDetailScreenState extends State<StockTransferDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchTransferDetail(widget.transferId);
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

  void _confirmDispatch(StockTransferModel tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.truck, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Kirim Transfer Barang?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Stok akan dipotong dari gudang asal (${tr.fromWarehouseName}) berdasarkan metode FIFO dan berstatus "Dalam Pengiriman".',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final stockProv = context.read<StockProvider>();
              final success = await stockProv.dispatchTransfer(tr.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barang berhasil dikirim dan stok gudang asal telah dikurangi.')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(stockProv.errorMessage ?? 'Gagal mengirim barang')),
                );
              }
            },
            child: const Text('Ya, Kirim Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showReceiveModal(StockTransferModel tr) {
    final Map<int, TextEditingController> receivedCtrls = {};
    for (var item in tr.items) {
      final double defaultQty = item.quantityReceived > 0
          ? item.quantityReceived
          : item.quantitySent;
      receivedCtrls[item.id] = TextEditingController(text: _formatQty(defaultQty));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.packageCheck, size: 20, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Konfirmasi Penerimaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          Text('Masukkan jumlah fisik barang yang diterima di gudang', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: tr.items.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (c, idx) {
                        final item = tr.items[idx];
                        final ctrl = receivedCtrls[item.id]!;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Dikirim: ${_formatQty(item.quantitySent)} ${item.unitName}',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: ctrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    labelText: 'Qty Diterima',
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(LucideIcons.checkCircle2, size: 18, color: Colors.white),
                      label: const Text('Terima & Tambah Stok', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      onPressed: () async {
                        final List<Map<String, dynamic>> itemsPayload = [];
                        for (var item in tr.items) {
                          final ctrl = receivedCtrls[item.id]!;
                          final val = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? item.quantitySent;
                          itemsPayload.add({
                            'id': item.id,
                            'quantity_received': val,
                          });
                        }

                        Navigator.pop(modalCtx);
                        final stockProv = context.read<StockProvider>();
                        final success = await stockProv.receiveTransfer(tr.id, items: itemsPayload);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Barang berhasil diterima di gudang ${tr.toWarehouseName} dan stok telah bertambah!')),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(stockProv.errorMessage ?? 'Gagal memproses penerimaan transfer')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmCancel(StockTransferModel tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Batalkan Transfer?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          tr.isDraft
              ? 'Draft dokumen transfer ${tr.transferNumber} akan dihapus secara permanen.'
              : 'Transfer ${tr.transferNumber} akan dibatalkan dan stok yang telah dikirim akan dikembalikan ke gudang asal (${tr.fromWarehouseName}).',
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
              final success = await stockProv.deleteTransfer(tr.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dokumen transfer berhasil dibatalkan / dihapus.')),
                );
                Navigator.pop(context);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(stockProv.errorMessage ?? 'Gagal membatalkan transfer')),
                );
              }
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final tr = stockProv.selectedTransfer;
    final isLoading = stockProv.isLoadingTransferDetail || tr == null;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Detail Transfer Gudang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Color badgeColor;
    Color badgeTextColor;
    IconData statusIcon;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.transferNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const Text('Detail & Riwayat Pemindahan', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
            onPressed: () => stockProv.fetchTransferDetail(tr.id),
          ),
        ],
      ),
      bottomNavigationBar: (tr.isDraft || tr.isInTransit)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Tombol Batal / Hapus
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _confirmCancel(tr),
                      icon: const Icon(LucideIcons.trash2, size: 16),
                      label: Text(tr.isDraft ? 'Hapus' : 'Batalkan', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),

                    // Tombol Aksi Utama
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tr.isDraft ? AppColors.primary : const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (tr.isDraft) {
                            _confirmDispatch(tr);
                          } else if (tr.isInTransit) {
                            _showReceiveModal(tr);
                          }
                        },
                        icon: Icon(tr.isDraft ? LucideIcons.truck : LucideIcons.packageCheck, size: 18, color: Colors.white),
                        label: Text(
                          tr.isDraft ? 'Kirim Transfer' : 'Konfirmasi Penerimaan',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Status & Rute
          Container(
            padding: const EdgeInsets.all(16),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              AppDateFormatter.format(tr.transferDate),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                            tr.statusLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: badgeTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rute Asal -> Tujuan
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEF2F6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GUDANG ASAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(
                              tr.fromWarehouseName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.arrowRight, size: 18, color: AppColors.primary),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('GUDANG TUJUAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(
                              tr.toWarehouseName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ringkasan Pengirim & Catatan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Informasi Pengiriman', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                _buildInfoRow('Nomor Dokumen', tr.transferNumber),
                if (tr.senderName != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Dibuat / Dikirim Oleh', tr.senderName!),
                ],
                if (tr.receiverName != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Diterima Oleh', tr.receiverName!),
                ],
                if (tr.receivedAt != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Waktu Penerimaan', AppDateFormatter.formatDateTime(tr.receivedAt!)),
                ],
                if (tr.notes != null && tr.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Catatan', tr.notes!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daftar Item Transfer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.boxes, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Daftar Produk (${tr.items.length})', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      ],
                    ),
                    Text(
                      'Total: ${_formatQty(tr.totalQuantitySent)} unit',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tr.items.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final item = tr.items[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEF2F6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ),
                              Text(
                                '${_formatQty(item.quantitySent)} ${item.unitName}',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item.batchNumber != null)
                                Text('Batch: ${item.batchNumber} • ', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              if (tr.isCompleted && item.quantityReceived > 0)
                                Text(
                                  'Diterima: ${_formatQty(item.quantityReceived)} ${item.unitName}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                                )
                              else
                                Text(
                                  'Status: ${tr.statusLabel}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
