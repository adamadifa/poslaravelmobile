import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/features/auth/providers/auth_provider.dart';
import 'package:poslaravelmobile/features/auth/screens/login_screen.dart';
import 'package:poslaravelmobile/features/history/screens/transactions_history_screen.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_alerts_screen.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_card_screen.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_adjustments_list_screen.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_opnames_list_screen.dart';
import 'package:poslaravelmobile/features/inventory/screens/stock_transfers_list_screen.dart';
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
import 'package:poslaravelmobile/features/purchasing/screens/purchase_orders_list_screen.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_receipts_list_screen.dart';
import 'package:poslaravelmobile/features/purchasing/screens/purchase_returns_list_screen.dart';
import 'package:poslaravelmobile/features/purchasing/screens/supplier_payables_screen.dart';
import 'package:poslaravelmobile/features/finance/screens/account_transfers_list_screen.dart';
import 'package:poslaravelmobile/features/finance/screens/cash_flows_list_screen.dart';
import 'package:poslaravelmobile/features/home/screens/main_navigation_screen.dart';
import 'package:poslaravelmobile/features/pos/screens/customer_receivables_screen.dart';
import 'package:poslaravelmobile/features/reports/screens/reports_hub_screen.dart';
import 'package:poslaravelmobile/features/sales_returns/screens/sale_returns_list_screen.dart';
import 'package:poslaravelmobile/features/staff/screens/roles_matrix_screen.dart';
import 'package:poslaravelmobile/features/staff/screens/staff_users_screen.dart';

class AppSidebarDrawer extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const AppSidebarDrawer({super.key, this.onNavigateToTab});

  void _pushScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _selectTab(BuildContext context, int tabIndex) {
    Navigator.pop(context); // close drawer
    if (onNavigateToTab != null) {
      onNavigateToTab!(tabIndex);
    } else {
      MainNavigationScreen.navigateToTab(context, tabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header: Store Brand & Close button
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x28EA580C),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.store, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WarungPro POS',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Sistem Point of Sale',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Menu matching poslaravel sidebar exactly
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  // Nav: Dashboard
                  _buildSidebarItem(
                    title: 'Dashboard',
                    icon: LucideIcons.layoutGrid,
                    onTap: () => _selectTab(context, 0),
                  ),
                  // Nav: Kasir POS (F12)
                  _buildSidebarItem(
                    title: 'Kasir POS (F12)',
                    icon: LucideIcons.shoppingCart,
                    badgeText: 'F12',
                    badgeColor: const Color(0xFFEA580C),
                    badgeBg: const Color(0xFFFFF7ED),
                    onTap: () => _selectTab(context, 1),
                  ),

                  // SECTION: MASTER DATA
                  _buildSectionHeader('MASTER DATA'),
                  _buildSidebarItem(
                    title: 'Master Produk',
                    icon: LucideIcons.package,
                    onTap: () => _pushScreen(context, const ProductsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Bahan Baku (Raw)',
                    icon: LucideIcons.boxes,
                    iconColor: const Color(0xFFD97706),
                    onTap: () => _pushScreen(context, const RawMaterialsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Kategori',
                    icon: LucideIcons.folderTree,
                    onTap: () => _pushScreen(context, const CategoriesListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Satuan',
                    icon: LucideIcons.scale,
                    onTap: () => _pushScreen(context, const UnitsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Pelanggan & Member',
                    icon: LucideIcons.userCheck,
                    onTap: () => _pushScreen(context, const CustomersListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Pemasok (Supplier)',
                    icon: LucideIcons.truck,
                    onTap: () => _pushScreen(context, const SuppliersListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Gudang & Cabang',
                    icon: LucideIcons.warehouse,
                    onTap: () => _pushScreen(context, const WarehousesListScreen()),
                  ),

                  // SECTION: RESTO & KULINER (F&B)
                  _buildSectionHeader('RESTO & F&B', headerColor: const Color(0xFFEA580C)),
                  _buildSidebarItem(
                    title: 'Denah & Meja Resto',
                    icon: LucideIcons.layoutGrid,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () => _pushScreen(context, const DiningTablesListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Reservasi Meja',
                    icon: LucideIcons.calendar,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () => _pushScreen(context, const DiningTablesListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Resep Menu (BOM)',
                    icon: LucideIcons.chefHat,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () => _pushScreen(context, const ProductsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Bahan Baku (Dapur)',
                    icon: LucideIcons.boxes,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () => _pushScreen(context, const ProductsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Modifiers & Topping',
                    icon: LucideIcons.sliders,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () => _selectTab(context, 1),
                  ),
                  _buildSidebarItem(
                    title: 'Layar Dapur (KDS)',
                    icon: LucideIcons.flame,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Layar Dapur (KDS) aktif di Web / Tablet Kitchen.')),
                      );
                    },
                  ),

                  // SECTION: OPERASIONAL
                  _buildSectionHeader('OPERASIONAL'),
                  _buildSidebarItem(
                    title: 'Diskon & Promo',
                    icon: LucideIcons.badgePercent,
                    onTap: () => _pushScreen(context, const DiscountsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Purchase Order (PO)',
                    icon: LucideIcons.clipboardList,
                    onTap: () => _pushScreen(context, const PurchaseOrdersListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Penerimaan Barang (GRN)',
                    icon: LucideIcons.packageCheck,
                    onTap: () => _pushScreen(context, const PurchaseReceiptsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Retur Pembelian',
                    icon: LucideIcons.rotateCcw,
                    iconColor: const Color(0xFFDC2626),
                    onTap: () => _pushScreen(context, const PurchaseReturnsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Kartu Stok (FIFO)',
                    icon: LucideIcons.boxes,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () => _pushScreen(context, const StockCardScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Stok Opname',
                    icon: LucideIcons.clipboardCheck,
                    iconColor: const Color(0xFF059669),
                    onTap: () => _pushScreen(context, const StockOpnamesListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Transfer Antar Gudang',
                    icon: LucideIcons.arrowLeftRight,
                    onTap: () => _pushScreen(context, const StockTransfersListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Penyesuaian Stok (Adj)',
                    icon: LucideIcons.slidersHorizontal,
                    onTap: () => _pushScreen(context, const StockAdjustmentsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Peringatan Stok',
                    icon: LucideIcons.alertTriangle,
                    iconColor: const Color(0xFFD97706),
                    onTap: () => _pushScreen(context, const StockAlertsScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Riwayat Penjualan',
                    icon: LucideIcons.receipt,
                    onTap: () => _pushScreen(context, const TransactionsHistoryScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Retur Penjualan',
                    icon: LucideIcons.rotateCcw,
                    iconColor: const Color(0xFFDC2626),
                    onTap: () => _pushScreen(context, const SaleReturnsListScreen()),
                  ),

                  // SECTION: KEUANGAN & KAS
                  _buildSectionHeader('KEUANGAN & KAS'),
                  _buildSidebarItem(
                    title: 'Akun Kas & Bank',
                    icon: LucideIcons.wallet,
                    onTap: () => _pushScreen(context, const AccountsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Katalog Produk PPOB',
                    icon: LucideIcons.smartphone,
                    onTap: () => _pushScreen(context, const PpobProductsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Hutang Pembelian (AP)',
                    icon: LucideIcons.receipt,
                    onTap: () => _pushScreen(context, const SupplierPayablesScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Piutang Penjualan (AR)',
                    icon: LucideIcons.coins,
                    onTap: () => _pushScreen(context, const CustomerReceivablesScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Arus Kas Masuk & Keluar',
                    icon: LucideIcons.arrowDownUp,
                    onTap: () => _pushScreen(context, const CashFlowsListScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Transfer Kas & Bank',
                    icon: LucideIcons.arrowLeftRight,
                    onTap: () => _pushScreen(context, const AccountTransfersListScreen()),
                  ),

                  // SECTION: LAPORAN & PENGATURAN
                  _buildSectionHeader('LAPORAN & PENGATURAN'),
                  _buildSidebarItem(
                    title: 'Laporan & Analitik',
                    icon: LucideIcons.barChart3,
                    onTap: () => _pushScreen(context, const ReportsHubScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Staf & Pengguna',
                    icon: LucideIcons.users,
                    onTap: () => _pushScreen(context, const StaffUsersScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Hak Akses & Peran',
                    icon: LucideIcons.shieldCheck,
                    onTap: () => _pushScreen(context, const RolesMatrixScreen()),
                  ),
                  _buildSidebarItem(
                    title: 'Pengaturan Toko',
                    icon: LucideIcons.settings,
                    onTap: () => _selectTab(context, 4),
                  ),
                  _buildSidebarItem(
                    title: 'Audit Trail (Log)',
                    icon: LucideIcons.shieldAlert,
                    onTap: () => _selectTab(context, 4),
                  ),
                ],
              ),
            ),

            // Profile Footer Card matching web sidebar footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                color: Color(0xFFF8FAFC),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Center(
                      child: Text(
                        (user?.name != null && user!.name.trim().isNotEmpty)
                            ? user.name.trim()[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Super Administrator',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          (user?.role ?? 'KASIR').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFDC2626)),
                    tooltip: 'Keluar Akun',
                    onPressed: () async {
                      Navigator.pop(context);
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? headerColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: headerColor ?? const Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required String title,
    required IconData icon,
    Color? iconColor,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: iconColor ?? const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg ?? const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor ?? const Color(0xFF475569),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
