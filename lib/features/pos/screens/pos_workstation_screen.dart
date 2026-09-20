import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/features/auth/providers/auth_provider.dart';
import 'package:poslaravelmobile/features/auth/screens/login_screen.dart';
import 'package:poslaravelmobile/features/pos/providers/pos_provider.dart';
import 'package:poslaravelmobile/features/shift/providers/shift_provider.dart';

class PosWorkstationScreen extends StatefulWidget {
  const PosWorkstationScreen({super.key});

  @override
  State<PosWorkstationScreen> createState() => _PosWorkstationScreenState();
}

class _PosWorkstationScreenState extends State<PosWorkstationScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().loadInitialData();
      context.read<ShiftProvider>().fetchCurrentShift();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              Text('Catat Kas Keluar (Expense)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                        _buildSummaryRow('Total Penjualan Tunai', CurrencyFormatter.format(shift.totalCashSales)),
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

  void _showCheckoutDialog(BuildContext context) {
    final pos = context.read<PosProvider>();
    final shift = context.read<ShiftProvider>().currentShift;
    final total = pos.grandTotal;

    String paymentMethod = 'cash';
    double paidAmount = total;
    final paidCtrl = TextEditingController(text: total.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final change = paidAmount - total;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pembayaran Transaksi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Text(
                        CurrencyFormatter.format(total),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPaymentMethodChip('cash', 'Tunai', LucideIcons.banknote, paymentMethod, (val) {
                      setModalState(() => paymentMethod = val);
                    }),
                    _buildPaymentMethodChip('qris', 'QRIS', LucideIcons.qrCode, paymentMethod, (val) {
                      setModalState(() {
                        paymentMethod = val;
                        paidAmount = total;
                        paidCtrl.text = total.toStringAsFixed(0);
                      });
                    }),
                    _buildPaymentMethodChip('transfer', 'Transfer Bank', LucideIcons.arrowRightLeft, paymentMethod, (val) {
                      setModalState(() {
                        paymentMethod = val;
                        paidAmount = total;
                        paidCtrl.text = total.toStringAsFixed(0);
                      });
                    }),
                    _buildPaymentMethodChip('card', 'Debit / Kartu', LucideIcons.creditCard, paymentMethod, (val) {
                      setModalState(() {
                        paymentMethod = val;
                        paidAmount = total;
                        paidCtrl.text = total.toStringAsFixed(0);
                      });
                    }),
                  ],
                ),
                if (paymentMethod == 'cash') ...[
                  const SizedBox(height: 16),
                  const Text('Nominal Uang Diterima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.coins, size: 18),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        paidAmount = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Uang Pas'),
                        onPressed: () {
                          setModalState(() {
                            paidAmount = total;
                            paidCtrl.text = total.toStringAsFixed(0);
                          });
                        },
                      ),
                      ...[20000.0, 50000.0, 100000.0].where((n) => n >= total).map((preset) => ActionChip(
                            label: Text(CurrencyFormatter.format(preset)),
                            onPressed: () {
                              setModalState(() {
                                paidAmount = preset;
                                paidCtrl.text = preset.toStringAsFixed(0);
                              });
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: change >= 0 ? AppColors.background : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          change >= 0 ? 'Kembalian' : 'Uang Kurang',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: change >= 0 ? AppColors.textPrimary : AppColors.error,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(change.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: change >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (paymentMethod == 'cash' && change < 0)
                        ? null
                        : () async {
                            final result = await pos.checkout(
                              shiftId: shift?.id,
                              paymentMethod: paymentMethod,
                              paidAmount: paidAmount,
                            );

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              if (result != null) {
                                _showSuccessReceiptDialog(context, result);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(pos.errorMessage ?? 'Gagal checkout transaksi.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.checkCircle2, size: 20),
                        SizedBox(width: 8),
                        Text('Selesaikan Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSuccessReceiptDialog(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCheck, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Transaksi Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Faktur: ${result['invoice_number'] ?? '-'}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${CurrencyFormatter.format(double.tryParse((result['grand_total'] ?? 0).toString()) ?? 0.0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            if (result['change_amount'] != null && (double.tryParse(result['change_amount'].toString()) ?? 0) > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Kembalian: ${CurrencyFormatter.format(double.tryParse(result['change_amount'].toString()) ?? 0.0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.printer, size: 16),
            label: const Text('Cetak Struk'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mengirim perintah cetak struk Bluetooth...')),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  void _showHoldDialog(BuildContext context) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simpan Sementara (Hold)', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: noteCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Catatan / Nama Pelanggan / Nomor Meja',
            hintText: 'Contoh: Meja 04 / Mas Budi',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final pos = context.read<PosProvider>();
              final success = await pos.holdCart(noteCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaksi berhasil di-hold.')),
                  );
                }
              }
            },
            child: const Text('Hold Transaksi'),
          ),
        ],
      ),
    );
  }

  void _showHeldListDialog(BuildContext context) async {
    final pos = context.read<PosProvider>();
    final list = await pos.getHeldList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Daftar Transaksi Tertunda (Held)', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 380,
          child: list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Tidak ada transaksi yang di-hold.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (_, idx) {
                    final item = list[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.clock, color: AppColors.warning, size: 20),
                      ),
                      title: Text(item['reference_note'] ?? 'Tanpa Catatan', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item['items']?.length ?? 0} item • ${item['created_at'] ?? ''}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          final success = await pos.recallHeld(item['id']);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaksi berhasil dimuat kembali ke keranjang.')),
                              );
                            }
                          }
                        },
                        child: const Text('Recall'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  static Widget _buildPaymentMethodChip(
    String id,
    String label,
    IconData icon,
    String selectedId,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = id == selectedId;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textPrimary),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelected(id),
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
    final pos = context.watch<PosProvider>();
    final shift = context.watch<ShiftProvider>();
    final auth = context.watch<AuthProvider>();
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.store, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kasir POS Modern', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(
                  auth.user?.name ?? 'Kasir',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Shift Status & Action Header
          if (shift.hasActiveShift) ...[
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                foregroundColor: AppColors.error,
              ),
              icon: const Icon(LucideIcons.arrowUpRight, size: 14),
              label: Text('Kas Keluar (${CurrencyFormatter.format(shift.currentShift!.totalExpenses)})'),
              onPressed: () => _showAddExpenseDialog(context),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primarySurface,
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(LucideIcons.lock, size: 14),
              label: const Text('Tutup Shift'),
              onPressed: () => _showCloseShiftDialog(context),
            ),
          ] else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(LucideIcons.playCircle, size: 14),
              label: const Text('Buka Shift'),
              onPressed: () => _showOpenShiftDialog(context),
            ),
          ],
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(LucideIcons.clock),
            tooltip: 'Transaksi Tertunda (Hold)',
            onPressed: () => _showHeldListDialog(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Keluar',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Area: Product Catalog Grid & Filter
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama produk, barcode, SKU...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                pos.search('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => pos.search(val),
                  ),
                ),

                // Category Chips List
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    scrollDirection: Axis.horizontal,
                    itemCount: pos.categories.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      if (idx == 0) {
                        final isSelected = pos.selectedCategory == null;
                        return ChoiceChip(
                          label: const Text('Semua'),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => pos.selectCategory(null),
                        );
                      }
                      final cat = pos.categories[idx - 1];
                      final isSelected = pos.selectedCategory?.id == cat.id;
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => pos.selectCategory(cat),
                      );
                    },
                  ),
                ),

                // Products Grid View
                Expanded(
                  child: pos.isLoadingProducts
                      ? const Center(child: CircularProgressIndicator())
                      : pos.products.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada produk ditemukan',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isTablet ? 3 : 2,
                                childAspectRatio: 0.82,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: pos.products.length,
                              itemBuilder: (context, index) {
                                final product = pos.products[index];
                                return _buildProductCard(context, product);
                              },
                            ),
                ),
              ],
            ),
          ),

          // Right Area: Shopping Cart
          Container(
            width: isTablet ? 340 : 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                // Cart Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.shoppingBag, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Keranjang (${pos.totalItemCount})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      if (pos.cartItems.isNotEmpty)
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                          tooltip: 'Kosongkan',
                          onPressed: () => pos.clearCart(),
                        ),
                    ],
                  ),
                ),

                // Cart Items List
                Expanded(
                  child: pos.cartItems.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.shoppingCart, size: 40, color: AppColors.border),
                              SizedBox(height: 8),
                              Text('Keranjang Masih Kosong', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(10),
                          itemCount: pos.cartItems.length,
                          separatorBuilder: (context, index) => const Divider(height: 12),
                          itemBuilder: (context, idx) {
                            final item = pos.cartItems[idx];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.product.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(item.subtotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${CurrencyFormatter.format(item.unitPrice)} / ${item.product.unitName ?? 'pcs'}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                    Row(
                                      children: [
                                        _buildQtyButton(LucideIcons.minus, () => pos.decreaseQty(idx)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            item.qty.toInt().toString(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        _buildQtyButton(LucideIcons.plus, () => pos.increaseQty(idx)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                ),

                // Cart Total & Action Buttons
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text(CurrencyFormatter.format(pos.subtotal), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            CurrencyFormatter.format(pos.grandTotal),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(LucideIcons.pauseCircle, size: 16),
                              label: const Text('Hold', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: pos.cartItems.isEmpty ? null : () => _showHoldDialog(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(LucideIcons.checkCircle2, size: 16),
                              label: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: pos.cartItems.isEmpty ? null : () => _showCheckoutDialog(context),
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
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final pos = context.read<PosProvider>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => pos.addToCart(product),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image / Placeholder Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.package,
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(product.sellingPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Stok: ${product.stock.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: product.stock > 0 ? AppColors.textMuted : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 12, color: AppColors.textPrimary),
      ),
    );
  }
}
