import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_card_screen.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/master_data/screens/raw_material_form_screen.dart';

class RawMaterialsListScreen extends StatefulWidget {
  const RawMaterialsListScreen({super.key});

  @override
  State<RawMaterialsListScreen> createState() => _RawMaterialsListScreenState();
}

class _RawMaterialsListScreenState extends State<RawMaterialsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchRawMaterials();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openRawMaterialForm([ProductModel? rawMaterial]) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RawMaterialFormScreen(rawMaterial: rawMaterial),
      ),
    );
    if (res == true && mounted) {
      context.read<MasterDataProvider>().fetchRawMaterials(search: _searchCtrl.text.trim());
      context.read<MasterDataProvider>().fetchSummary();
    }
  }

  void _confirmDeleteRawMaterial(ProductModel item) {
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
              'Hapus Bahan Baku?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus bahan baku "${item.name}"?\nData bahan baku ini akan dihapus dari sistem.',
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
              final ok = await context.read<MasterDataProvider>().deleteProduct(item.id);
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bahan baku "${item.name}" berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.read<MasterDataProvider>().fetchRawMaterials(search: _searchCtrl.text.trim());
                  context.read<MasterDataProvider>().fetchSummary();
                } else {
                  final err = context.read<MasterDataProvider>().errorMessage ?? 'Gagal menghapus bahan baku';
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
          'Master Bahan Baku',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
            onPressed: () => provider.fetchRawMaterials(search: _searchCtrl.text.trim()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
        label: const Text(
          'Tambah Bahan Baku',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
        ),
        onPressed: () => _openRawMaterialForm(),
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
                hintText: 'Cari nama bahan, SKU, atau merk...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.fetchRawMaterials();
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
                provider.fetchRawMaterials(search: val.trim());
              },
            ),
          ),

          // List of Raw Materials
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : provider.rawMaterials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.boxes, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada data bahan baku',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _openRawMaterialForm(),
                              icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                              label: const Text(
                                'Tambah Bahan Baku Sekarang',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => provider.fetchRawMaterials(search: _searchCtrl.text.trim()),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: provider.rawMaterials.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final item = provider.rawMaterials[idx];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _openRawMaterialForm(item),
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
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Center(
                                          child: Icon(LucideIcons.boxes, color: Color(0xFFD97706), size: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                if (item.code != null && item.code!.isNotEmpty) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      item.code!,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFFB45309),
                                                        fontFamily: 'monospace',
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                if (item.unitName != null && item.unitName!.isNotEmpty)
                                                  Text(
                                                    'Satuan: ${item.unitName}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'HPP: ${CurrencyFormatter.format(item.costPrice)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                if (item.unitName != null)
                                                  Text(
                                                    '/${item.unitName}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                  ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: item.stock > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: item.stock > 0 ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Stok: ${item.stock.toStringAsFixed(0)} ${item.unitName ?? "Pcs"}',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: item.stock > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                ),
                                                if (item.conversions.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEFF6FF),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${item.conversions.length} Konversi',
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
                                      PopupMenuButton<String>(
                                        icon: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textMuted),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (action) {
                                          if (action == 'stock_card') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => StockCardScreen(initialProductId: item.id),
                                              ),
                                            );
                                          } else if (action == 'edit') {
                                            _openRawMaterialForm(item);
                                          } else if (action == 'delete') {
                                            _confirmDeleteRawMaterial(item);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'stock_card',
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.fileText, size: 16, color: Color(0xFF2563EB)),
                                                SizedBox(width: 8),
                                                Text('Kartu Stok', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.edit2, size: 16, color: AppColors.primary),
                                                SizedBox(width: 8),
                                                Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                                                SizedBox(width: 8),
                                                Text('Hapus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                                              ],
                                            ),
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
