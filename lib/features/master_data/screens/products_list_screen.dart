import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_card_screen.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/master_data/screens/product_form_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openProductForm([ProductModel? product]) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
    if (res == true && mounted) {
      context.read<MasterDataProvider>().fetchProducts(search: _searchCtrl.text.trim());
    }
  }

  void _confirmDeleteProduct(ProductModel product) {
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
              'Hapus Produk?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "${product.name}"?\nProduk akan dinonaktifkan dari katalog kasir.',
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
              final ok = await context.read<MasterDataProvider>().deleteProduct(product.id);
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Produk "${product.name}" berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  final err = context.read<MasterDataProvider>().errorMessage ?? 'Gagal menghapus produk';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppColors.error),
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
    final provider = context.watch<MasterDataProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Master Produk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
            onPressed: () => provider.fetchProducts(search: _searchCtrl.text.trim()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
        label: const Text(
          'Tambah Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
        ),
        onPressed: () => _openProductForm(),
      ),
      body: Column(
        children: [
          // Search Bar on Orange Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari produk, kode, atau barcode...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.fetchProducts();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFDE68A), width: 1.5),
                ),
              ),
              onSubmitted: (val) {
                provider.fetchProducts(search: val.trim());
              },
            ),
          ),

          // List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : provider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.packageOpen, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada data produk',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _openProductForm(),
                              icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                              label: const Text(
                                'Tambah Produk Sekarang',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => provider.fetchProducts(search: _searchCtrl.text.trim()),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: provider.products.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final prod = provider.products[idx];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _openProductForm(prod),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x04000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Center(
                                          child: Icon(LucideIcons.package, color: Color(0xFF3B82F6), size: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod.name,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                             const SizedBox(height: 3),
                                             Row(
                                               children: [
                                                 if (prod.code != null && prod.code!.isNotEmpty) ...[
                                                   Flexible(
                                                     child: Text(
                                                       prod.code!,
                                                       style: const TextStyle(
                                                         fontSize: 11,
                                                         color: AppColors.textMuted,
                                                         fontWeight: FontWeight.w500,
                                                       ),
                                                       maxLines: 1,
                                                       overflow: TextOverflow.ellipsis,
                                                     ),
                                                   ),
                                                   const SizedBox(width: 4),
                                                   const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                                   const SizedBox(width: 4),
                                                 ],
                                                 Flexible(
                                                   child: Text(
                                                     prod.category?.name ?? 'Umum',
                                                     style: const TextStyle(
                                                       fontSize: 11,
                                                       color: AppColors.primary,
                                                       fontWeight: FontWeight.w600,
                                                     ),
                                                     maxLines: 1,
                                                     overflow: TextOverflow.ellipsis,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             const SizedBox(height: 5),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 4,
                                               crossAxisAlignment: WrapCrossAlignment.center,
                                               children: [
                                                 Text(
                                                   CurrencyFormatter.format(prod.sellingPrice),
                                                   style: const TextStyle(
                                                     fontSize: 13,
                                                     fontWeight: FontWeight.w800,
                                                     color: Color(0xFF059669),
                                                   ),
                                                 ),
                                                 Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                   decoration: BoxDecoration(
                                                     color: prod.stock > 5 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                                     borderRadius: BorderRadius.circular(6),
                                                     border: Border.all(
                                                       color: prod.stock > 5 ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                                                     ),
                                                   ),
                                                   child: Text(
                                                     'Stok: ${prod.stock.toStringAsFixed(0)} ${prod.unitName ?? "Pcs"}',
                                                     style: TextStyle(
                                                       fontSize: 10,
                                                       fontWeight: FontWeight.w700,
                                                       color: prod.stock > 5 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                                     ),
                                                   ),
                                                 ),
                                                 if (prod.conversions.isNotEmpty)
                                                   Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                     decoration: BoxDecoration(
                                                       color: const Color(0xFFF0FDFA),
                                                       borderRadius: BorderRadius.circular(6),
                                                       border: Border.all(color: const Color(0xFF99F6E4)),
                                                     ),
                                                     child: Text(
                                                       '+${prod.conversions.length} Satuan',
                                                       style: const TextStyle(
                                                         fontSize: 9.5,
                                                         fontWeight: FontWeight.w700,
                                                         color: Color(0xFF0D9488),
                                                       ),
                                                     ),
                                                   ),
                                                 if (prod.tieredPrices.isNotEmpty)
                                                   Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                     decoration: BoxDecoration(
                                                       color: const Color(0xFFEFF6FF),
                                                       borderRadius: BorderRadius.circular(6),
                                                       border: Border.all(color: const Color(0xFFBFDBFE)),
                                                     ),
                                                     child: Text(
                                                       '${prod.tieredPrices.length} Tier Grosir',
                                                       style: const TextStyle(
                                                         fontSize: 9.5,
                                                         fontWeight: FontWeight.w700,
                                                         color: Color(0xFF2563EB),
                                                       ),
                                                     ),
                                                   ),
                                               ],
                                             ),
                                           ],
                                         ),
                                       ),
                                      // Action Buttons: Stock Card, Edit, & Delete
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(LucideIcons.boxes, size: 16, color: Color(0xFFEA580C)),
                                            visualDensity: VisualDensity.compact,
                                            tooltip: 'Kartu Stok (FIFO)',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => StockCardScreen(initialProductId: prod.id),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(LucideIcons.edit2, size: 16, color: Color(0xFF2563EB)),
                                            visualDensity: VisualDensity.compact,
                                            tooltip: 'Edit Produk',
                                            onPressed: () => _openProductForm(prod),
                                          ),
                                          IconButton(
                                            icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
                                            visualDensity: VisualDensity.compact,
                                            tooltip: 'Hapus Produk',
                                            onPressed: () => _confirmDeleteProduct(prod),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
