import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/purchase_order_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/purchasing/providers/purchasing_provider.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_order_detail_screen.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_order_form_screen.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_receipt_form_screen.dart';

class PurchaseOrdersListScreen extends StatefulWidget {
  const PurchaseOrdersListScreen({super.key});

  @override
  State<PurchaseOrdersListScreen> createState() => _PurchaseOrdersListScreenState();
}

class _PurchaseOrdersListScreenState extends State<PurchaseOrdersListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'all';

  final List<Map<String, String>> _statusFilters = [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'draft', 'label': 'Draft'},
    {'key': 'sent', 'label': 'Terkirim'},
    {'key': 'partial', 'label': 'Parsial'},
    {'key': 'received', 'label': 'Diterima'},
    {'key': 'cancelled', 'label': 'Dibatalkan'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchasingProvider>().fetchOrders();
      context.read<MasterDataProvider>().fetchSuppliers();
      context.read<MasterDataProvider>().fetchWarehouses();
      context.read<MasterDataProvider>().fetchProducts();
      context.read<MasterDataProvider>().fetchUnits();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openOrderForm([PurchaseOrderModel? order]) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseOrderFormScreen(order: order),
      ),
    );
    if (res == true && mounted) {
      context.read<PurchasingProvider>().fetchOrders();
    }
  }

  void _openOrderDetail(PurchaseOrderModel order) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseOrderDetailScreen(orderId: order.id),
      ),
    );
    if (res == true && mounted) {
      context.read<PurchasingProvider>().fetchOrders();
    }
  }

  void _openGoodsReceipt(PurchaseOrderModel order) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseReceiptFormScreen(fromOrder: order),
      ),
    );
    if (res == true && mounted) {
      context.read<PurchasingProvider>().fetchOrders();
    }
  }

  void _confirmDeleteOrder(PurchaseOrderModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Hapus PO?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pesanan ${item.poNumber} (${item.supplierName})?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<PurchasingProvider>().deleteOrder(item.id);
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pesanan ${item.poNumber} berhasil dihapus.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<PurchasingProvider>().errorMessage ?? 'Gagal menghapus PO.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
              'Purchase Order (PO)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Pemesanan barang & bahan baku ke pemasok',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
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
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nomor PO atau nama supplier...',
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
      body: Column(
        children: [
          // Filter Chips (Status)
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final f = _statusFilters[idx];
                final isSelected = _selectedStatusFilter == f['key'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = f['key']!;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Order List
          Expanded(
            child: Consumer<PurchasingProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.orders.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final query = _searchCtrl.text.toLowerCase().trim();
                var list = provider.orders;

                // Apply status filter
                if (_selectedStatusFilter != 'all') {
                  list = list.where((o) => o.status == _selectedStatusFilter).toList();
                }

                // Apply search filter
                if (query.isNotEmpty) {
                  list = list.where((o) {
                    final num = o.poNumber.toLowerCase();
                    final supp = o.supplierName.toLowerCase();
                    return num.contains(query) || supp.contains(query);
                  }).toList();
                }

                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchOrders(),
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
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                child: const Icon(
                                  LucideIcons.clipboardList,
                                  size: 32,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                query.isNotEmpty || _selectedStatusFilter != 'all'
                                    ? 'Tidak ada pesanan yang cocok'
                                    : 'Belum Ada Purchase Order',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                query.isNotEmpty || _selectedStatusFilter != 'all'
                                    ? 'Coba ubah kata kunci pencarian atau filter status.'
                                    : 'Buat Purchase Order baru untuk memesan produk/bahan ke pemasok.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  elevation: 0,
                                ),
                                onPressed: () => _openOrderForm(),
                                icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                                label: const Text(
                                  'Buat PO Baru',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchOrders(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final item = list[idx];
                      return _buildOrderCard(item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 3,
        onPressed: () => _openOrderForm(),
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
        label: const Text(
          'Buat PO Baru',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(PurchaseOrderModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.clipboardList, color: Color(0xFFEA580C), size: 18),
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
                              item.poNumber,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
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
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: item.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(LucideIcons.truck, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.supplierName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                    const Text(
                      'TOTAL PESANAN',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.formattedGrandTotal,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.warehouse, size: 11, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        item.warehouseName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dates & Items details
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.expectedDate != null && item.expectedDate!.isNotEmpty
                        ? 'Order: ${AppDateFormatter.format(item.orderDate)} • Est: ${AppDateFormatter.format(item.expectedDate)}'
                        : 'Order: ${AppDateFormatter.format(item.orderDate)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.items.length} Barang',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),

          const Divider(height: 12, color: Color(0xFFF1F5F9)),

          // Actions Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                // If can receive goods, show Receive button
                if (item.canReceive)
                  InkWell(
                    onTap: () => _openGoodsReceipt(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.packageCheck, size: 13, color: Color(0xFF059669)),
                          SizedBox(width: 5),
                          Text(
                            'Terima Barang (GRN)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // View Details Button
                InkWell(
                  onTap: () => _openOrderDetail(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.eye, color: Color(0xFF475569), size: 14),
                    ),
                  ),
                ),

                if (item.canEdit) ...[
                  const SizedBox(width: 8),
                  // Edit Button
                  InkWell(
                    onTap: () => _openOrderForm(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.pencil, color: Color(0xFF2563EB), size: 13),
                      ),
                    ),
                  ),
                ],

                if (item.canEdit) ...[
                  const SizedBox(width: 8),
                  // Delete Button
                  InkWell(
                    onTap: () => _confirmDeleteOrder(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.trash2, color: Color(0xFFDC2626), size: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
