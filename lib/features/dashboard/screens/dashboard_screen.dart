import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/features/auth/providers/auth_provider.dart';
import 'package:poslaravelmobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:poslaravelmobile/features/master_data/screens/categories_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/customers_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/dining_tables_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/products_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/suppliers_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/units_list_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/warehouses_list_screen.dart';
import 'package:poslaravelmobile/core/widgets/app_sidebar_drawer.dart';
import 'package:poslaravelmobile/features/shift/providers/shift_provider.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isBreakdownExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
      context.read<ShiftProvider>().fetchCurrentShift();
    });
  }

  void _handleMenuTap(String menuId) {
    switch (menuId) {
      case 'pos':
        widget.onNavigateToTab(1); // Kasir POS tab
        break;
      case 'products':
      case 'raw_materials':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsListScreen()));
        break;
      case 'categories':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesListScreen()));
        break;
      case 'units':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitsListScreen()));
        break;
      case 'resto':
      case 'tables':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DiningTablesListScreen()));
        break;
      case 'customers':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersListScreen()));
        break;
      case 'purchases':
      case 'suppliers':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersListScreen()));
        break;
      case 'warehouses':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WarehousesListScreen()));
        break;
      case 'master_data':
        widget.onNavigateToTab(3); // Master Data tab
        break;
      case 'history':
      case 'reports':
        widget.onNavigateToTab(2); // Riwayat tab
        break;
      case 'settings':
        widget.onNavigateToTab(4); // Pengaturan tab
        break;
      case 'drawer':
        _scaffoldKey.currentState?.openDrawer();
        break;
      case 'shift':
        _showOpenShiftDialog(context);
        break;
      default:
        widget.onNavigateToTab(3); // Open Master Data tab
        break;
    }
  }

  void _showOpenShiftDialog(BuildContext context) {
    final startingCashCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.playCircle, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Buka Sesi Shift Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan modal awal kas di laci sebelum memulai transaksi penjualan.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: startingCashCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Modal Awal Kas (Rp)',
                prefixIcon: Icon(LucideIcons.banknote, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan Shift (Opsional)',
                prefixIcon: Icon(LucideIcons.fileText, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final startingCash = double.tryParse(startingCashCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
              final shiftProv = context.read<ShiftProvider>();
              final success = await shiftProv.openShift(
                warehouseId: 1,
                startingCash: startingCash,
                notes: notesCtrl.text.trim(),
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  context.read<DashboardProvider>().fetchDashboard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shift kasir berhasil dibuka!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(shiftProv.errorMessage ?? 'Gagal membuka shift.')),
                  );
                }
              }
            },
            child: const Text('Buka Shift Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'Operasional';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(LucideIcons.arrowUpRight, color: AppColors.error),
              SizedBox(width: 8),
              Text('Catat Kas Keluar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Kategori Pengeluaran',
                  prefixIcon: Icon(LucideIcons.tag, size: 18),
                ),
                items: ['Operasional', 'Beli Perlengkapan', 'Konsumsi', 'Transport', 'Lainnya']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nominal Kas Keluar (Rp)',
                  prefixIcon: Icon(LucideIcons.banknote, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Pengeluaran',
                  prefixIcon: Icon(LucideIcons.fileText, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                if (amount <= 0) return;

                final shiftProv = context.read<ShiftProvider>();
                final success = await shiftProv.addExpense(
                  amount: amount,
                  category: category,
                  notes: notesCtrl.text.trim(),
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    context.read<DashboardProvider>().fetchDashboard();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kas keluar berhasil dicatat!')),
                    );
                  }
                }
              },
              child: const Text('Simpan Kas Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context) {
    final shift = context.read<ShiftProvider>().currentShift;
    if (shift == null) return;

    final actualCashCtrl = TextEditingController(text: shift.expectedCash.toStringAsFixed(0));
    double actualCash = shift.expectedCash;
    double diff = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          diff = actualCash - shift.expectedCash;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(LucideIcons.lock, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Tutup Sesi Shift Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Modal Awal', CurrencyFormatter.format(shift.startingCash)),
                        const Divider(height: 12),
                        _buildSummaryRow('Penjualan Tunai', CurrencyFormatter.format(shift.totalCashSales)),
                        const Divider(height: 12),
                        _buildSummaryRow('Total Kas Keluar', '- ${CurrencyFormatter.format(shift.totalExpenses)}', isNegative: true),
                        const Divider(height: 12),
                        _buildSummaryRow('Ekspektasi Kas Sistem', CurrencyFormatter.format(shift.expectedCash), isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: actualCashCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Kas Fisik Aktual di Laci (Rp)',
                      prefixIcon: Icon(LucideIcons.banknote, size: 18),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        actualCash = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: diff == 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : (diff < 0 ? AppColors.error.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          diff == 0 ? 'Kas Seimbang' : (diff < 0 ? 'Selisih Kurang' : 'Selisih Lebih'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.error : AppColors.warning),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(diff.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.error : AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final shiftProv = context.read<ShiftProvider>();
                  final success = await shiftProv.closeShift(actualCash: actualCash);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (success) {
                      context.read<DashboardProvider>().fetchDashboard();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shift kasir berhasil ditutup!')),
                      );
                    }
                  }
                },
                child: const Text('Konfirmasi Tutup Shift', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: isNegative ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final shift = context.watch<ShiftProvider>();
    final activeShift = shift.currentShift;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppSidebarDrawer(onNavigateToTab: widget.onNavigateToTab),
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            dash.fetchDashboard(),
            shift.fetchCurrentShift(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SEAMLESS INTEGRATED HEADER & SHIFT RECAP SECTION
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x28EA580C),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Brand Row with Hamburger Sidebar Trigger
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.menu, size: 20, color: Colors.white),
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                tooltip: 'Menu Sidebar',
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.store, color: Color(0xFFEA580C), size: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'WarungPro POS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.bell, size: 17, color: Colors.white),
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // User Profile (Direct layout, no card container)
                        Row(
                          children: [
                            // User Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x28000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: auth.user?.avatar != null && auth.user!.avatar!.isNotEmpty
                                    ? Image.network(
                                        auth.user!.avatar!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(auth.user?.name),
                                      )
                                    : _buildDefaultAvatar(auth.user?.name),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          auth.user?.name ?? 'Pengguna',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.white30, width: 0.8),
                                        ),
                                        child: Text(
                                          (auth.user?.role ?? 'KASIR').toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4ADE80), // Online green dot
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        auth.user?.email ?? 'Aktif Bertugas',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.white.withValues(alpha: 0.88),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ATM Debit Card (Integrated seamlessly into header)
                        if (shift.hasActiveShift && activeShift != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card Top: Chip / NFC / Status Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Gold EMV Chip Simulation
                                        Container(
                                          width: 34,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700),
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(color: const Color(0xFFFFFBEB), width: 0.8),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x22000000),
                                                blurRadius: 3,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(height: 1, color: const Color(0xFFB45309)),
                                              const SizedBox(height: 4),
                                              Container(height: 1, color: const Color(0xFFB45309)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(LucideIcons.wifi, color: Colors.white70, size: 17),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white30, width: 0.8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.checkCircle2, size: 11, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'SHIFT AKTIF',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Total Kas Amount
                                const Text(
                                  'TOTAL KAS FISIK DI LACI',
                                  style: TextStyle(
                                    color: Color(0xFFFFEDD5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  CurrencyFormatter.format(activeShift.expectedCash),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Card Bottom: Operator info & Toggle Button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'OPERATOR KASIR',
                                          style: TextStyle(
                                            color: Color(0xFFFFEDD5),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          activeShift.userName ?? auth.user?.name ?? 'KASIR UTAMA',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isBreakdownExpanded = !_isBreakdownExpanded;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.24),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white30),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _isBreakdownExpanded ? 'Tutup Rincian' : 'Lihat Rincian',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              _isBreakdownExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Card Action Buttons inside Orange Card
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showAddExpenseDialog(context),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.20),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white24),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(LucideIcons.minusCircle, color: Colors.white, size: 13),
                                              SizedBox(width: 5),
                                              Text(
                                                'Catat Kas Keluar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showCloseShiftDialog(context),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x22000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(LucideIcons.lock, color: Color(0xFFEA580C), size: 13),
                                              SizedBox(width: 5),
                                              Text(
                                                'Tutup Shift',
                                                style: TextStyle(
                                                  color: Color(0xFFEA580C),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Shift Closed Banner in Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sesi Kasir Belum Dibuka',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      Text(
                                        'Isi modal awal untuk mulai transaksi.',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFEA580C),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showOpenShiftDialog(context),
                                  child: const Text('Buka Shift', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shift.hasActiveShift && activeShift != null) ...[
                      // COLLAPSIBLE FORMAL REPORT (AUDIT STYLE)
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Report Title Header
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'LAPORAN TRANSAKSI SHIFT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'AUDIT RESMI',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF64748B),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 6),

                              // 1. Retail
                              _buildFormalReportRow(
                                label: 'Modal Awal Kasir',
                                value: CurrencyFormatter.format(activeShift.startingCash),
                                valueColor: const Color(0xFF334155),
                              ),
                              _buildFormalReportRow(
                                label: 'Penjualan Tunai',
                                value: CurrencyFormatter.format(activeShift.totalCashSales),
                                valueColor: const Color(0xFF059669),
                                badgeText: '${activeShift.totalTransactions} Tx',
                                badgeBgColor: const Color(0xFFECFDF5),
                                badgeTextColor: const Color(0xFF059669),
                              ),
                              _buildFormalReportRow(
                                label: 'Penjualan Non-Tunai / QRIS',
                                value: CurrencyFormatter.format(activeShift.totalNonCashSales),
                                valueColor: const Color(0xFF2563EB),
                              ),
                              _buildFormalReportRow(
                                label: 'Kas Keluar Toko (Operasional)',
                                value: '- ${CurrencyFormatter.format(activeShift.totalExpenses)}',
                                valueColor: const Color(0xFFDC2626),
                              ),

                              const SizedBox(height: 6),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 6),

                              // 2. PPOB & Agen
                              _buildFormalReportRow(
                                label: 'Transaksi PPOB & Pulsa',
                                value: CurrencyFormatter.format(activeShift.ppobSales),
                                valueColor: const Color(0xFF7C3AED),
                                badgeText: '${activeShift.ppobCount} Item',
                                badgeBgColor: const Color(0xFFF5F3FF),
                                badgeTextColor: const Color(0xFF7C3AED),
                              ),
                              _buildFormalReportRow(
                                label: 'Tarik Tunai & Transfer Bank',
                                value: '${activeShift.bankTransferCount + activeShift.bankWithdrawalCount} Transaksi',
                                valueColor: const Color(0xFF0284C7),
                              ),
                              _buildFormalReportRow(
                                label: 'Keuntungan / Komisi Agen',
                                value: '+ ${CurrencyFormatter.format(activeShift.totalAgentProfit)}',
                                valueColor: const Color(0xFF059669),
                                isBold: true,
                              ),

                              if (activeShift.totalAgentCashIn > 0 || activeShift.totalAgentCashOut > 0) ...[
                                _buildFormalReportRow(
                                  label: 'Kas Masuk Agen (Setor)',
                                  value: '+ ${CurrencyFormatter.format(activeShift.totalAgentCashIn)}',
                                  valueColor: const Color(0xFF059669),
                                ),
                                _buildFormalReportRow(
                                  label: 'Kas Keluar Agen (Tarik Tunai)',
                                  value: '- ${CurrencyFormatter.format(activeShift.totalAgentCashOut)}',
                                  valueColor: const Color(0xFFDC2626),
                                ),
                              ],

                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Color(0xFF0F172A), thickness: 1.2),
                              const SizedBox(height: 6),

                              // Summary Total
                              _buildFormalReportRow(
                                label: 'Total Saldo Kas Fisik Laci',
                                value: CurrencyFormatter.format(activeShift.expectedCash),
                                valueColor: const Color(0xFF0F172A),
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: _isBreakdownExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 220),
                      ),
                    ],

                    // Menu Cepat Esensial (Quick Access Shortcuts)
                    _buildDashboardSectionGroup(
                      title: 'MENU UTAMA & AKSES CEPAT',
                      badge: 'Favorit',
                      badgeColor: const Color(0xFFEA580C),
                      badgeBg: const Color(0xFFFFF7ED),
                      items: [
                        _DashboardMenuItemData(
                          id: 'pos',
                          title: 'Kasir POS',
                          icon: LucideIcons.shoppingBag,
                          color: const Color(0xFFF97316),
                        ),
                        _DashboardMenuItemData(
                          id: 'shift',
                          title: 'Shift Kasir',
                          icon: LucideIcons.userCheck,
                          color: const Color(0xFFEA580C),
                        ),
                        _DashboardMenuItemData(
                          id: 'products',
                          title: 'Produk',
                          icon: LucideIcons.package,
                          color: const Color(0xFF2563EB),
                        ),
                        _DashboardMenuItemData(
                          id: 'resto',
                          title: 'Meja Resto',
                          icon: LucideIcons.layoutGrid,
                          color: const Color(0xFFD97706),
                        ),
                        _DashboardMenuItemData(
                          id: 'customers',
                          title: 'Pelanggan',
                          icon: LucideIcons.users,
                          color: const Color(0xFF7C3AED),
                        ),
                        _DashboardMenuItemData(
                          id: 'ppob',
                          title: 'PPOB Pulsa',
                          icon: LucideIcons.smartphone,
                          color: const Color(0xFF8B5CF6),
                        ),
                        _DashboardMenuItemData(
                          id: 'reports',
                          title: 'Laporan',
                          icon: LucideIcons.barChart2,
                          color: const Color(0xFF14B8A6),
                        ),
                        _DashboardMenuItemData(
                          id: 'drawer',
                          title: 'Semua Menu',
                          icon: LucideIcons.menu,
                          color: const Color(0xFF475569),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Recent Transactions Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaksi Terakhir',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        InkWell(
                          onTap: () => widget.onNavigateToTab(2),
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    if (dash.isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (dash.recentSales.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text('Belum ada transaksi hari ini', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ),
                      )
                    else
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dash.recentSales.length > 5 ? 5 : dash.recentSales.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final item = dash.recentSales[idx];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.receipt, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['invoice_number'] ?? 'Faktur',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item['customer_name']} • ${item['created_at']}',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(double.tryParse((item['grand_total'] ?? 0).toString()) ?? 0.0),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormalReportRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    String? badgeText,
    Color? badgeBgColor,
    Color? badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isBold ? const Color(0xFF1E293B) : const Color(0xFF475569),
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: badgeBgColor ?? const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor ?? const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }


  Widget _buildDashboardSectionGroup({
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required List<_DashboardMenuItemData> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
            childAspectRatio: 0.94,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, idx) {
            final item = items[idx];
            return _buildGridMenuItem(
              id: item.id,
              title: item.title,
              icon: item.icon,
              color: item.color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGridMenuItem({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _handleMenuTap(id),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: color, size: 22),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initial = (name != null && name.trim().isNotEmpty) ? name.trim()[0].toUpperCase() : 'U';
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Color(0xFFEA580C),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DashboardMenuItemData {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  _DashboardMenuItemData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}
