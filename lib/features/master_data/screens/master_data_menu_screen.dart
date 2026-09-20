import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/master_data/screens/accounts_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/categories_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/customers_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/dining_tables_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/discounts_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/ppob_products_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/products_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/raw_materials_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/suppliers_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/units_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/warehouses_list_screen.dart';

class MasterDataMenuScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const MasterDataMenuScreen({super.key, this.onBack});

  @override
  State<MasterDataMenuScreen> createState() => _MasterDataMenuScreenState();
}

class _MasterDataMenuScreenState extends State<MasterDataMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchSummary();
    });
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MasterDataProvider>();
    final summary = provider.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                onPressed: widget.onBack,
              )
            : null,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Data',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              'Katalog, Relasi, Resto & Operasional',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => provider.fetchSummary(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GRUP 1: MASTER DATA UTAMA (PRODUK & INVENTORI)
              _buildSectionGroup(
                title: 'MASTER DATA UTAMA',
                badgeText: 'Katalog & Stok',
                badgeColor: const Color(0xFF3B82F6),
                badgeBg: const Color(0xFFEFF6FF),
                items: [
                  _MasterMenuItem(
                    title: 'Master Produk',
                    subtitle: 'Katalog barang & barcode',
                    icon: LucideIcons.package,
                    color: const Color(0xFF2563EB),
                    count: summary['products_count'],
                    onTap: () => _navigateTo(const ProductsListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Bahan Baku (Raw)',
                    subtitle: 'Stok bahan mentah (BOM)',
                    icon: LucideIcons.boxes,
                    color: const Color(0xFFD97706),
                    count: summary['raw_materials_count'],
                    onTap: () => _navigateTo(const RawMaterialsListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Kategori Produk',
                    subtitle: 'Pengelompokan barang',
                    icon: LucideIcons.folderTree,
                    color: const Color(0xFF0284C7),
                    count: summary['categories_count'],
                    onTap: () => _navigateTo(const CategoriesListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Satuan Unit',
                    subtitle: 'Pcs, Dus, Lusin, Gram',
                    icon: LucideIcons.scale,
                    color: const Color(0xFF059669),
                    count: summary['units_count'],
                    onTap: () => _navigateTo(const UnitsListScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // GRUP 2: RELASI & KONTAK
              _buildSectionGroup(
                title: 'RELASI & KONTAK BISNIS',
                badgeText: 'Pelanggan & Pemasok',
                badgeColor: const Color(0xFF8B5CF6),
                badgeBg: const Color(0xFFF5F3FF),
                items: [
                  _MasterMenuItem(
                    title: 'Pelanggan & Member',
                    subtitle: 'Daftar customer & poin',
                    icon: LucideIcons.userCheck,
                    color: const Color(0xFF7C3AED),
                    count: summary['customers_count'],
                    onTap: () => _navigateTo(const CustomersListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Pemasok (Supplier)',
                    subtitle: 'Kontak vendor pengadaan',
                    icon: LucideIcons.truck,
                    color: const Color(0xFFD97706),
                    count: summary['suppliers_count'],
                    onTap: () => _navigateTo(const SuppliersListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Gudang & Cabang',
                    subtitle: 'Outlet cabang toko',
                    icon: LucideIcons.warehouse,
                    color: const Color(0xFF0284C7),
                    count: summary['warehouses_count'],
                    onTap: () => _navigateTo(const WarehousesListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Grup Pelanggan',
                    subtitle: 'Member VIP, Grosir, Reseller',
                    icon: LucideIcons.users,
                    color: const Color(0xFF4F46E5),
                    onTap: () => _navigateTo(const CustomersListScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // GRUP 3: RESTORAN & KULINER (F&B)
              _buildSectionGroup(
                title: 'RESTO & KULINER (F&B)',
                badgeText: 'Meja & Dapur',
                badgeColor: const Color(0xFFEA580C),
                badgeBg: const Color(0xFFFFF7ED),
                items: [
                  _MasterMenuItem(
                    title: 'Denah & Meja Resto',
                    subtitle: 'Status meja & kapasitas',
                    icon: LucideIcons.layoutGrid,
                    color: const Color(0xFFEA580C),
                    count: summary['tables_count'],
                    onTap: () => _navigateTo(const DiningTablesListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Modifiers & Topping',
                    subtitle: 'Varian level pedas & topping',
                    icon: LucideIcons.sliders,
                    color: const Color(0xFFD97706),
                    count: summary['modifiers_count'],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Modifiers terintegrasi otomatis di menu POS Kasir.')),
                      );
                    },
                  ),
                  _MasterMenuItem(
                    title: 'Layar Dapur (KDS)',
                    subtitle: 'Kitchen Display System',
                    icon: LucideIcons.flame,
                    color: const Color(0xFFDC2626),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Layar Dapur dapat diakses melalui tablet kitchen atau web dashboard.')),
                      );
                    },
                  ),
                  _MasterMenuItem(
                    title: 'Reservasi Meja',
                    subtitle: 'Jadwal booking tamu',
                    icon: LucideIcons.calendar,
                    color: const Color(0xFF059669),
                    onTap: () => _navigateTo(const DiningTablesListScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // GRUP 4: OPERASIONAL, PROMO & KEUANGAN
              _buildSectionGroup(
                title: 'PROMO & KAS TOKO',
                badgeText: 'Diskon & Finansial',
                badgeColor: const Color(0xFF059669),
                badgeBg: const Color(0xFFECFDF5),
                items: [
                  _MasterMenuItem(
                    title: 'Diskon & Promo',
                    subtitle: 'Voucher diskon & cashback',
                    icon: LucideIcons.badgePercent,
                    color: const Color(0xFF10B981),
                    count: summary['discounts_count'],
                    onTap: () => _navigateTo(const DiscountsListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Akun Kas & Bank',
                    subtitle: 'Rekening & saldo toko',
                    icon: LucideIcons.wallet,
                    color: const Color(0xFF0284C7),
                    count: summary['accounts_count'],
                    onTap: () => _navigateTo(const AccountsListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Produk PPOB & Pulsa',
                    subtitle: 'Katalog pulsa, PLN & paket',
                    icon: LucideIcons.smartphone,
                    color: const Color(0xFF7C3AED),
                    count: summary['ppob_products_count'],
                    onTap: () => _navigateTo(const PpobProductsListScreen()),
                  ),
                  _MasterMenuItem(
                    title: 'Stok Opname',
                    subtitle: 'Penyesuaian stok fisik',
                    icon: LucideIcons.clipboardCheck,
                    color: const Color(0xFF475569),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stok Opname berkala dapat disinkronkan melalui web POS.')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionGroup({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required List<_MasterMenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
                letterSpacing: 0.6,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2x2 Grid per group
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.72,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, idx) {
            final item = items[idx];
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
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
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(item.icon, color: item.color, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.count != null) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: item.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${item.count}',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: item.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
  }
}

class _MasterMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  _MasterMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.count,
    required this.onTap,
  });
}
