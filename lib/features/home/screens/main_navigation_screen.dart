import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:poslaravelmobile/features/history/screens/transactions_history_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/master_data_menu_screen.dart';
import 'package:poslaravelmobile/features/pos/screens/mobile_pos_screen.dart';
import 'package:poslaravelmobile/features/pos/screens/pos_workstation_screen.dart';
import 'package:poslaravelmobile/features/settings/screens/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  static final GlobalKey<MainNavigationScreenState> globalKey = GlobalKey<MainNavigationScreenState>();

  const MainNavigationScreen({super.key});

  static void navigateToTab(BuildContext context, int tabIndex) {
    if (globalKey.currentState != null) {
      globalKey.currentState!.setTab(tabIndex);
      // Pop all pushed routes back to root so MainNavigationScreen is visible
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void setTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    // If running on Tablet, load Full POS Workstation
    if (isTablet) {
      return const PosWorkstationScreen();
    }

    final pages = [
      DashboardScreen(onNavigateToTab: (index) {
        setState(() => _currentIndex = index);
      }),
      const MobilePosScreen(),
      const TransactionsHistoryScreen(),
      const MasterDataMenuScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildFloatingNotchedNavBar(),
    );
  }

  Widget _buildFloatingNotchedNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const barHeight = 64.0;
    const fabSize = 56.0;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPadding > 0 ? bottomPadding : 16,
      ),
      child: SizedBox(
        height: barHeight + 18,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Floating Bar Body with smooth concave notch
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _NotchedPillPainter(
                    notchRadius: 36,
                    notchDepth: 26,
                    cornerRadius: 30,
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    children: [
                      // Left Item 1: Beranda
                      Expanded(
                        child: _buildNavItem(
                          icon: LucideIcons.layoutDashboard,
                          index: 0,
                        ),
                      ),
                      // Left Item 2: Riwayat Transaksi
                      Expanded(
                        child: _buildNavItem(
                          icon: LucideIcons.receipt,
                          index: 2,
                        ),
                      ),
                      // Center Spacer for Notch
                      const SizedBox(width: 72),
                      // Right Item 1: Master Data
                      Expanded(
                        child: _buildNavItem(
                          icon: LucideIcons.database,
                          index: 3,
                        ),
                      ),
                      // Right Item 2: Pengaturan
                      Expanded(
                        child: _buildNavItem(
                          icon: LucideIcons.settings,
                          index: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Elevated Circular Center Button (Kasir POS)
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: BoxDecoration(
                    color: _currentIndex == 1 ? AppColors.primaryDark : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.38),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.shoppingBag,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: onTap ?? () => setState(() => _currentIndex = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 5),
            // Clean active dot indicator matching the reference design
            Container(
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter to draw a floating pill bar with a smooth concave notch at top center
class _NotchedPillPainter extends CustomPainter {
  final double notchRadius;
  final double notchDepth;
  final double cornerRadius;
  final Color backgroundColor;

  _NotchedPillPainter({
    required this.notchRadius,
    required this.notchDepth,
    required this.cornerRadius,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Start at top-left, after corner radius
    path.moveTo(cornerRadius, 0);

    // Line to left side of center notch
    final notchStart = cx - notchRadius;
    path.lineTo(notchStart, 0);

    // Smooth bezier curve into the notch and back up
    path.cubicTo(
      cx - (notchRadius * 0.55), 0,
      cx - (notchRadius * 0.45), notchDepth,
      cx, notchDepth,
    );
    path.cubicTo(
      cx + (notchRadius * 0.45), notchDepth,
      cx + (notchRadius * 0.55), 0,
      cx + notchRadius, 0,
    );

    // Line to top-right corner
    path.lineTo(w - cornerRadius, 0);

    // Top-right rounded corner
    path.arcToPoint(
      Offset(w, cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Right vertical line
    path.lineTo(w, h - cornerRadius);

    // Bottom-right rounded corner
    path.arcToPoint(
      Offset(w - cornerRadius, h),
      radius: Radius.circular(cornerRadius),
    );

    // Bottom horizontal line
    path.lineTo(cornerRadius, h);

    // Bottom-left rounded corner
    path.arcToPoint(
      Offset(0, h - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Left vertical line
    path.lineTo(0, cornerRadius);

    // Top-left rounded corner
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NotchedPillPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.notchDepth != notchDepth;
  }
}

