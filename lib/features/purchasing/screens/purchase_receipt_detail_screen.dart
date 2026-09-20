import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/purchase_receipt_model.dart';
import 'package:poslaravelmobile/features/purchasing/providers/purchasing_provider.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_return_form_screen.dart';

class PurchaseReceiptDetailScreen extends StatelessWidget {
  final PurchaseReceiptModel receipt;

  const PurchaseReceiptDetailScreen({super.key, required this.receipt});

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              receipt.grnNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const Text(
              'Detail Surat Jalan & Barang Masuk',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              final res = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => PurchaseReturnFormScreen(fromReceipt: receipt)),
              );
              if (res == true && context.mounted) {
                context.read<PurchasingProvider>().fetchReceipts();
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(LucideIcons.rotateCcw, size: 16, color: Colors.white),
            label: const Text(
              'Buat Retur Pembelian Dari GRN Ini',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Card (Status, Nomor GRN, Tanggal)
            _buildHeaderCard(),
            const SizedBox(height: 14),

            // 2. Info Pemasok & Gudang
            _buildSupplierWarehouseCard(),
            const SizedBox(height: 14),

            // 3. Daftar Item Diterima
            _buildItemsCard(),
            const SizedBox(height: 14),

            // 4. Ringkasan Keuangan
            _buildFinancialSummaryCard(),

            // 5. Catatan jika ada
            if (receipt.notes != null && receipt.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildNotesCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
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
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.packageCheck, color: Color(0xFF059669), size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOMOR GRN',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      Text(
                        receipt.grnNumber,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: receipt.paymentStatusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  receipt.paymentStatusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: receipt.paymentStatusColor),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Penerimaan', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF2563EB)),
                        const SizedBox(width: 5),
                        Text(
                          AppDateFormatter.format(receipt.receiptDate),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jatuh Tempo Pembayaran', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.calendarClock, size: 13, color: Color(0xFFD97706)),
                        const SizedBox(width: 5),
                        Text(
                          AppDateFormatter.format(receipt.paymentDueDate),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierWarehouseCard() {
    return Container(
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
                    const Text('PEMASOK (SUPPLIER)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    Text(receipt.supplierName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
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
                    const Text('GUDANG PENYIMPANAN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    Text(receipt.warehouseName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  ],
                ),
              ),
            ],
          ),
          if ((receipt.poNumber != null && receipt.poNumber!.isNotEmpty) ||
              (receipt.supplierInvoiceNumber != null && receipt.supplierInvoiceNumber!.isNotEmpty)) ...[
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                if (receipt.poNumber != null && receipt.poNumber!.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NO. PURCHASE ORDER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(receipt.poNumber!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                if (receipt.supplierInvoiceNumber != null && receipt.supplierInvoiceNumber!.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NO. INVOICE / SJ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(receipt.supplierInvoiceNumber!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
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
              const Text('Daftar Barang Masuk', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: Text('${receipt.items.length} Item', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          if (receipt.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('Tidak ada rincian barang.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: receipt.items.length,
              separatorBuilder: (context, index) => const Divider(height: 18, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, idx) {
                final it = receipt.items[idx];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: const Center(child: Icon(LucideIcons.package, size: 18, color: Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          const SizedBox(height: 3),
                          Text(
                            '${it.quantityReceived.toStringAsFixed(it.quantityReceived.truncateToDouble() == it.quantityReceived ? 0 : 2)} ${it.unitName} × ${CurrencyFormatter.format(it.unitCost)}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          if (it.batchNumber != null && it.batchNumber!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                                child: Text('Batch: ${it.batchNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                              ),
                            ),
                          if (it.expiryDate != null && it.expiryDate!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('Exp: ${AppDateFormatter.format(it.expiryDate)}', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(it.subtotal),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal Barang', CurrencyFormatter.format(receipt.subtotal)),
          if (receipt.taxAmount > 0)
            _buildSummaryRow('Pajak (PPN)', '+ ${CurrencyFormatter.format(receipt.taxAmount)}'),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              Text(
                CurrencyFormatter.format(receipt.grandTotal),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
              ),
            ],
          ),
          if (receipt.paidAmount > 0 || receipt.remainingDebt > 0) ...[
            const Divider(height: 18, color: Color(0xFFF1F5F9)),
            _buildSummaryRow('Sudah Dibayar', CurrencyFormatter.format(receipt.paidAmount), color: const Color(0xFF059669)),
            _buildSummaryRow('Sisa Hutang', CurrencyFormatter.format(receipt.remainingDebt), color: const Color(0xFFDC2626)),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
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
          const Row(
            children: [
              Icon(LucideIcons.fileText, size: 14, color: Color(0xFF92400E)),
              SizedBox(width: 6),
              Text('Catatan Penerimaan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
            ],
          ),
          const SizedBox(height: 4),
          Text(receipt.notes!, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color ?? const Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }
}
