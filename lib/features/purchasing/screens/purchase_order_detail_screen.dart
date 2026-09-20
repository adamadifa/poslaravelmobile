import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/purchase_order_model.dart';
import 'package:poslaravelmobile/features/purchasing/providers/purchasing_provider.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_order_form_screen.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_receipt_form_screen.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const PurchaseOrderDetailScreen({super.key, required this.orderId});

  @override
  State<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  PurchaseOrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final po = await context.read<PurchasingProvider>().getOrderDetail(widget.orderId);
    if (mounted) {
      setState(() {
        _order = po;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_order == null) return;
    final ok = await context.read<PurchasingProvider>().updateOrderStatus(_order!.id, status);
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status PO berhasil diubah menjadi "$status".'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<PurchasingProvider>().errorMessage ?? 'Gagal mengubah status PO.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Detail Purchase Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Detail Purchase Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text('Data Purchase Order tidak ditemukan.', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          order.poNumber,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          if (order.canEdit)
            IconButton(
              icon: const Icon(LucideIcons.pencil, color: Colors.white, size: 18),
              tooltip: 'Edit PO',
              onPressed: () async {
                final res = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => PurchaseOrderFormScreen(order: order)),
                );
                if (res == true) _loadDetail();
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (order.status == 'draft') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus('sent'),
                    icon: const Icon(LucideIcons.send, color: Colors.white, size: 16),
                    label: const Text('Kirim ke Pemasok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else if (order.canReceive) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final res = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => PurchaseReceiptFormScreen(fromOrder: order)),
                      );
                      if (res == true) _loadDetail();
                    },
                    icon: const Icon(LucideIcons.packageCheck, color: Colors.white, size: 16),
                    label: const Text('Terima Barang (GRN)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Status & Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NOMOR PURCHASE ORDER', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(order.poNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.statusBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: order.statusColor),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Order', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(AppDateFormatter.format(order.orderDate), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimasi Kedatangan', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(
                              order.expectedDate != null ? AppDateFormatter.format(order.expectedDate) : 'Belum ditentukan',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: order.expectedDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Supplier & Warehouse Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                        child: const Center(child: Icon(LucideIcons.truck, color: Color(0xFF2563EB), size: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PEMASOK / SUPPLIER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                            Text(order.supplierName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                            if (order.supplierPhone != null && order.supplierPhone!.isNotEmpty)
                              Text(order.supplierPhone!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                        child: const Center(child: Icon(LucideIcons.warehouse, color: Color(0xFF059669), size: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GUDANG TUJUAN PENERIMAAN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                            Text(order.warehouseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Items List
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
                      const Text('Daftar Barang', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      Text('${order.items.length} Item', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final it = order.items[idx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(it.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                              ),
                              Text(CurrencyFormatter.format(it.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${it.quantityOrdered.toStringAsFixed(it.quantityOrdered.truncateToDouble() == it.quantityOrdered ? 0 : 2)} ${it.unitName} × ${CurrencyFormatter.format(it.unitPrice)}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                              if (it.discountPercent > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                                  child: Text('Disc ${it.discountPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                ),
                              ],
                            ],
                          ),
                          if (order.status != 'draft') ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Diterima: ${it.quantityReceived.toStringAsFixed(0)} / ${it.quantityOrdered.toStringAsFixed(0)} ${it.unitName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: it.isFullyReceived ? const Color(0xFF059669) : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Cost Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', CurrencyFormatter.format(order.subtotal)),
                  if (order.discountAmount > 0)
                    _buildSummaryRow('Diskon Faktur', '- ${CurrencyFormatter.format(order.discountAmount)}', isDiscount: true),
                  if (order.taxAmount > 0)
                    _buildSummaryRow('Pajak PPN', '+ ${CurrencyFormatter.format(order.taxAmount)}'),
                  if (order.shippingCost > 0)
                    _buildSummaryRow('Biaya Ongkir', '+ ${CurrencyFormatter.format(order.shippingCost)}'),
                  const Divider(height: 16, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Biaya', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      Text(order.formattedGrandTotal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Catatan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                    const SizedBox(height: 4),
                    Text(order.notes!, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDiscount ? const Color(0xFF059669) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
