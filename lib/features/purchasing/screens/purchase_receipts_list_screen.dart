import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/purchase_receipt_model.dart';
import 'package:poslaravelmobile/features/purchasing/providers/purchasing_provider.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_receipt_detail_screen.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_receipt_form_screen.dart';

class PurchaseReceiptsListScreen extends StatefulWidget {
  const PurchaseReceiptsListScreen({super.key});

  @override
  State<PurchaseReceiptsListScreen> createState() => _PurchaseReceiptsListScreenState();
}

class _PurchaseReceiptsListScreenState extends State<PurchaseReceiptsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchasingProvider>().fetchReceipts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openReceiptForm() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PurchaseReceiptFormScreen()),
    );
    if (res == true && mounted) {
      context.read<PurchasingProvider>().fetchReceipts();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Penerimaan Barang (GRN)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Surat jalan barang masuk & mutasi stok gudang',
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
                  hintText: 'Cari nomor GRN, invoice, atau supplier...',
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
          if (provider.isLoading && provider.receipts.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final query = _searchCtrl.text.toLowerCase().trim();
          var list = provider.receipts;

          if (query.isNotEmpty) {
            list = list.where((r) {
              final grn = r.grnNumber.toLowerCase();
              final inv = (r.supplierInvoiceNumber ?? '').toLowerCase();
              final supp = r.supplierName.toLowerCase();
              return grn.contains(query) || inv.contains(query) || supp.contains(query);
            }).toList();
          }

          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.fetchReceipts(),
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(35)),
                          child: const Icon(LucideIcons.packageCheck, size: 32, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isNotEmpty ? 'Tidak ada penerimaan yang cocok' : 'Belum Ada Penerimaan Barang (GRN)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          query.isNotEmpty ? 'Coba ubah kata kunci pencarian.' : 'Catat barang masuk dari pemasok atau realisasikan PO.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            elevation: 0,
                          ),
                          onPressed: () => _openReceiptForm(),
                          icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                          label: const Text('Catat Penerimaan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchReceipts(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final item = list[idx];
                return _buildReceiptCard(item);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 3,
        onPressed: () => _openReceiptForm(),
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
        label: const Text('Catat GRN', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _showReceiptDetail(PurchaseReceiptModel item) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseReceiptDetailScreen(receipt: item),
      ),
    );
    if (res == true && mounted) {
      context.read<PurchasingProvider>().fetchReceipts();
    }
  }

  Widget _buildReceiptCard(PurchaseReceiptModel item) {
    return InkWell(
      onTap: () => _showReceiptDetail(item),
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
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Icon(LucideIcons.packageCheck, color: Color(0xFF059669), size: 18)),
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
                              item.grnNumber,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: item.paymentStatusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.paymentStatusLabel,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: item.paymentStatusColor),
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

          // Total & Warehouse Info Box
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
                    const Text('TOTAL PENERIMAAN', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(item.grandTotal),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
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
                    item.poNumber != null
                        ? 'Tgl: ${AppDateFormatter.format(item.receiptDate)} (${item.poNumber})'
                        : 'Tgl: ${AppDateFormatter.format(item.receiptDate)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${item.items.length} Item Masuk', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
