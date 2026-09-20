import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/customer_model.dart';
import 'package:poslaravelmobile/data/models/modifier_group_model.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/features/pos/providers/pos_provider.dart';
import 'package:poslaravelmobile/features/shift/providers/shift_provider.dart';

class MobilePosScreen extends StatefulWidget {
  const MobilePosScreen({super.key});

  @override
  State<MobilePosScreen> createState() => _MobilePosScreenState();
}

class _MobilePosScreenState extends State<MobilePosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  // Catatan preset dinamis dari produk atau kategori (jika belum di-set di web, kembalikan kosong)
  List<String> _resolveItemNotePresets(ProductModel product) {
    if (product.defaultNotes.isNotEmpty) {
      return product.defaultNotes;
    }
    if (product.category != null && product.category!.defaultNotes.isNotEmpty) {
      return product.category!.defaultNotes;
    }
    return const [];
  }

  static const List<String> _defaultInvoiceNotePresets = [
    'Dine In / Makan di Tempat',
    'Take Away / Bungkus',
    'Pesanan Meja',
    'Titipan Pelanggan',
    'Segera Diproses',
  ];

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
    _searchCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 0. CAMERA BARCODE SCANNER MODAL
  // ===========================================================================
  void _showBarcodeScannerModal(BuildContext context) {
    final MobileScannerController scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    bool isScanned = false;
    bool isTorchOn = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.70,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.scanLine, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan Barcode / QR Produk',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Arahkan kamera ke barcode kemasan produk',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                            color: isTorchOn ? Colors.amber : Colors.white70,
                            size: 20,
                          ),
                          onPressed: () async {
                            await scannerController.toggleTorch();
                            setModalState(() {
                              isTorchOn = !isTorchOn;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: MobileScanner(
                            controller: scannerController,
                            errorBuilder: (context, error) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.cameraOff, color: AppColors.error, size: 40),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Gagal Membuka Kamera: ${error.errorCode}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Pastikan izin kamera sudah diberikan atau lakukan restart aplikasi setelah penambahan plugin native.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            onDetect: (capture) {
                              if (isScanned) return;
                              final barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final code = barcode.rawValue?.trim();
                                if (code != null && code.isNotEmpty) {
                                  isScanned = true;
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(modalCtx);
                                  _processScannedBarcode(code);
                                  break;
                                }
                              }
                            },
                          ),
                        ),
                        // Scanner Overlay Box
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.info, size: 14, color: Colors.white60),
                        const SizedBox(width: 8),
                        Text(
                          'Pindai cepat untuk otomatis menambahkan ke keranjang',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      scannerController.dispose();
    });
  }

  void _processScannedBarcode(String barcode) {
    final pos = context.read<PosProvider>();

    // 1. Try to find product by barcode or product code or multi-barcodes in current product list
    ProductModel? matchedProduct;
    for (final p in pos.products) {
      if (p.barcode?.trim().toLowerCase() == barcode.toLowerCase() ||
          p.code?.trim().toLowerCase() == barcode.toLowerCase() ||
          p.barcodes.any((b) => b.barcode.trim().toLowerCase() == barcode.toLowerCase())) {
        matchedProduct = p;
        break;
      }
    }

    if (matchedProduct != null) {
      pos.addToCart(matchedProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${matchedProduct.name} ditambahkan ke keranjang!',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Set query in search field and search via API
      _searchCtrl.text = barcode;
      pos.search(barcode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Barcode "$barcode" dicari di sistem...',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ===========================================================================
  // 1. CUSTOMER SELECTION & QUICK-ADD SHEET
  // ===========================================================================
  void _showCustomerPickerSheet(BuildContext context) {
    final pos = context.read<PosProvider>();
    final searchController = TextEditingController();
    List<CustomerModel> filteredCustomers = List.from(pos.customers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Pelanggan',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih member untuk diskon atau catat piutang',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          backgroundColor: AppColors.primarySurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(LucideIcons.userPlus, size: 15),
                        label: const Text('Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddCustomerDialog(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search box
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama pelanggan / nomor HP...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) {
                      setSheetState(() {
                        final q = val.toLowerCase();
                        filteredCustomers = pos.customers.where((c) {
                          final name = c.name.toLowerCase();
                          final phone = c.phone?.toLowerCase() ?? '';
                          return name.contains(q) || phone.contains(q);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Default / Retail Customer Option
                  InkWell(
                    onTap: () {
                      pos.selectCustomer(null);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: pos.selectedCustomer == null ? AppColors.primarySurface : AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pos.selectedCustomer == null ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.users, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pelanggan Umum (Retail)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Transaksi reguler tanpa member', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          if (pos.selectedCustomer == null)
                            const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Customer List
                  Expanded(
                    child: filteredCustomers.isEmpty
                        ? const Center(
                            child: Text('Tidak ada pelanggan ditemukan', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          )
                        : ListView.separated(
                            itemCount: filteredCustomers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final cust = filteredCustomers[idx];
                              final isSelected = pos.selectedCustomer?.id == cust.id;
                              return InkWell(
                                onTap: () {
                                  pos.selectCustomer(cust);
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primarySurface : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isSelected ? AppColors.primary : AppColors.inputBackground,
                                        child: Text(
                                          cust.name.isNotEmpty ? cust.name[0].toUpperCase() : 'C',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isSelected ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(cust.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                            Text(
                                              cust.phone != null && cust.phone!.isNotEmpty ? cust.phone! : (cust.code ?? '-'),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 18),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(LucideIcons.userPlus, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Tambah Pelanggan Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap *',
                    prefixIcon: Icon(LucideIcons.user, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp / HP',
                    prefixIcon: Icon(LucideIcons.phone, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Opsional)',
                    prefixIcon: Icon(LucideIcons.mail, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setDialogState(() => isSubmitting = true);
                      final newCust = await context.read<PosProvider>().addCustomer(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                            email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                            address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                          );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (newCust != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pelanggan ${newCust.name} berhasil ditambahkan!')),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. PRODUCT CUSTOMIZATION & NOTES MODAL (Tap product detail)
  // ===========================================================================
  void _showItemCustomModal(BuildContext context, ProductModel product) {
    final pos = context.read<PosProvider>();
    double qty = 1.0;
    double price = product.sellingPrice;
    int selectedUnitId = product.baseUnitId ?? 1;
    String selectedUnitName = product.unitName ?? 'Pcs';

    final qtyCtrl = TextEditingController(text: _formatQuantity(qty));
    final priceCtrl = TextEditingController(text: CurrencyFormatter.formatNumber(price));
    final noteCtrl = TextEditingController();
    final List<ModifierItemModel> selectedModifiers = [];

    // Pastikan list units minimal ada base unit
    final availableUnits = product.availableUnits.isNotEmpty
        ? product.availableUnits
        : [
            ProductUnitOption(
              id: product.baseUnitId ?? 1,
              name: product.unitName ?? 'Pcs',
              shortName: product.unitName ?? 'pcs',
              ratio: 1.0,
            ),
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final modExtra = selectedModifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);
          final total = qty * (price + modExtra);

          Future<void> onUnitChanged(ProductUnitOption unitOpt) async {
            selectedUnitId = unitOpt.id;
            selectedUnitName = unitOpt.name;
            final currentQty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? qty;

            // Resolve dynamic unit price from server or ratio fallback
            final resolvedPrice = await pos.resolveProductUnitPrice(product.id, unitOpt.id, quantity: currentQty);
            setModalState(() {
              if (resolvedPrice != null && resolvedPrice > 0) {
                price = resolvedPrice;
              } else {
                price = product.sellingPrice * unitOpt.ratio;
              }
              priceCtrl.text = CurrencyFormatter.formatNumber(price);
            });
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                // Product details row
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.package, color: AppColors.primary, size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  selectedUnitName,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stok: ${_formatQuantity(product.stock)} ${product.unitName ?? ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: product.stock > 0 ? AppColors.textSecondary : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pilihan Satuan Jual (Pcs, Lusin, Dus, Bal, dll)
                const Text('Pilih Satuan Jual',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableUnits.map((u) {
                    final isSelected = u.id == selectedUnitId;
                    return ChoiceChip(
                      label: Text(
                        u.name + (u.ratio > 1 ? ' (${_formatQuantity(u.ratio)} ${product.unitName ?? "pcs"})' : ''),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.inputBackground,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          onUnitChanged(u);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Qty Selector (Manual input supporting decimals + Stepper)
                const Text('Jumlah / Kuantitas (Bisa Desimal)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '1.0',
                          prefixIcon: const Icon(LucideIcons.scale, size: 18),
                          suffixText: selectedUnitName,
                          suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '.'));
                          if (parsed != null && parsed >= 0) {
                            setModalState(() {
                              qty = parsed;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _buildCircleBtn(LucideIcons.minus, () {
                            if (qty > 1) {
                              setModalState(() {
                                qty -= 1;
                                qtyCtrl.text = _formatQuantity(qty);
                              });
                            } else if (qty > 0.1) {
                              setModalState(() {
                                qty = double.parse((qty - 0.1).toStringAsFixed(2));
                                qtyCtrl.text = _formatQuantity(qty);
                              });
                            }
                          }),
                          _buildCircleBtn(LucideIcons.plus, () {
                            setModalState(() {
                              qty += 1;
                              qtyCtrl.text = _formatQuantity(qty);
                            });
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Custom Price (Read-only jika admin mematikan izin edit harga manual)
                TextField(
                  controller: priceCtrl,
                  readOnly: !pos.allowManualPriceEdit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Harga Satuan (Rp)',
                    prefixIcon: Icon(pos.allowManualPriceEdit ? LucideIcons.tag : LucideIcons.lock, size: 18),
                    suffixIcon: !pos.allowManualPriceEdit
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Text('Terkunci', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          )
                        : IconButton(
                            icon: const Icon(LucideIcons.rotateCcw, size: 16, color: AppColors.textMuted),
                            tooltip: 'Reset Harga Normal Satuan',
                            onPressed: () async {
                              final currentSelectedUnit = availableUnits.firstWhere(
                                (u) => u.id == selectedUnitId,
                                orElse: () => availableUnits.first,
                              );
                              final qtyNow = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? qty;
                              final resolved = await pos.resolveProductUnitPrice(product.id, currentSelectedUnit.id, quantity: qtyNow);
                              setModalState(() {
                                if (resolved != null && resolved > 0) {
                                  price = resolved;
                                } else {
                                  price = product.sellingPrice * currentSelectedUnit.ratio;
                                }
                                priceCtrl.text = CurrencyFormatter.formatNumber(price);
                              });
                            },
                          ),
                  ),
                  onChanged: (val) {
                    if (!pos.allowManualPriceEdit) return;
                    setModalState(() {
                      price = CurrencyFormatter.parseCleanNumber(val);
                    });
                  },
                ),
                // Modifiers / Topping Ekstra (jika produk memiliki konfigurasi modifier)
                if (product.modifierGroups.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Pilihan Topping & Racikan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  ...product.modifierGroups.map((group) {
                    final isSingle = group.selectionType == 'single';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: group.isRequired ? AppColors.errorSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: group.isRequired ? AppColors.error : AppColors.border),
                                ),
                                child: Text(
                                  group.isRequired ? 'Wajib' : 'Opsional',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: group.isRequired ? AppColors.error : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: group.modifiers.map((mod) {
                              final isSelected = selectedModifiers.any((m) => m.id == mod.id);
                              return FilterChip(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                                selected: isSelected,
                                selectedColor: AppColors.primarySurface,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                showCheckmark: true,
                                checkmarkColor: AppColors.primary,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      mod.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (mod.priceAdjustment > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '+${CurrencyFormatter.format(mod.priceAdjustment)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (isSingle) {
                                      selectedModifiers.removeWhere((m) => m.modifierGroupId == group.id);
                                      if (selected) {
                                        selectedModifiers.add(mod);
                                      }
                                    } else {
                                      if (selected) {
                                        selectedModifiers.add(mod);
                                      } else {
                                        selectedModifiers.removeWhere((m) => m.id == mod.id);
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 12),

                // Notes / Modifier
                const Text('Catatan Pesanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (_resolveItemNotePresets(product).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _resolveItemNotePresets(product).map((preset) {
                      final isSelected = noteCtrl.text.contains(preset);
                      return ActionChip(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: isSelected ? AppColors.primarySurface : AppColors.inputBackground,
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                        label: Text(
                          '+ $preset',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        onPressed: () {
                          setModalState(() {
                            if (noteCtrl.text.trim().isEmpty) {
                              noteCtrl.text = preset;
                            } else if (!noteCtrl.text.contains(preset)) {
                              noteCtrl.text = '${noteCtrl.text.trim()}, $preset';
                            } else {
                              // toggle off
                              final parts = noteCtrl.text.split(',').map((s) => s.trim()).where((s) => s != preset && s.isNotEmpty).toList();
                              noteCtrl.text = parts.join(', ');
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Kurang manis, ekstra pedas...',
                    prefixIcon: Icon(LucideIcons.fileText, size: 18),
                  ),
                ),
                const SizedBox(height: 20),

                // Total + Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Subtotal Item', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(
                          CurrencyFormatter.format(total),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text('Tambah ke Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final finalQty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? qty;
                            pos.addToCart(
                              product,
                              qty: finalQty,
                              customPrice: price,
                              unitId: selectedUnitId,
                              unitName: selectedUnitName,
                              notes: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                              modifiers: selectedModifiers,
                            );
                            Navigator.pop(ctx);
                          },
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
    );
  }

  // ===========================================================================
  // 3. DISCOUNT & VOUCHER MODAL
  // ===========================================================================
  void _showDiscountModal(BuildContext context) {
    final pos = context.read<PosProvider>();
    final promoCtrl = TextEditingController(text: pos.appliedPromoCode);
    final manualDiscountCtrl = TextEditingController(
      text: pos.globalDiscount > 0 ? pos.globalDiscount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(LucideIcons.tag, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Diskon & Voucher Promo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: promoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Kode Promo Voucher',
                hintText: 'Contoh: PROMO10',
                prefixIcon: Icon(LucideIcons.ticket, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: manualDiscountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Potongan Manual (Rp)',
                hintText: '0',
                prefixIcon: Icon(LucideIcons.percent, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              pos.setPromoCode('');
              pos.setGlobalDiscount(0);
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              pos.setPromoCode(promoCtrl.text.trim());
              final manualDisc = double.tryParse(manualDiscountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
              pos.setGlobalDiscount(manualDisc);
              Navigator.pop(ctx);
            },
            child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Helper to format quantity: displays 2 if whole integer, or 2.5 if decimal
  static String _formatQuantity(double qty) {
    if (qty % 1 == 0) {
      return qty.toInt().toString();
    }
    // Remove trailing zeros if any
    return qty.toString().replaceAll(RegExp(r'\.?0+$'), '');
  }

  // ===========================================================================
  // 3b. EDIT CART ITEM MODAL (Tap item in cart: Qty decimal & Price editing)
  // ===========================================================================
  void _showCartItemEditModal(BuildContext context, int index) {
    final pos = context.read<PosProvider>();
    if (index < 0 || index >= pos.cartItems.length) return;
    final item = pos.cartItems[index];

    double currentQty = item.qty;
    double currentPrice = item.unitPrice;
    int selectedUnitId = item.unitId ?? item.product.baseUnitId ?? 1;
    String selectedUnitName = item.unitName ?? item.product.unitName ?? 'Pcs';

    final qtyCtrl = TextEditingController(text: _formatQuantity(currentQty));
    final priceCtrl = TextEditingController(text: CurrencyFormatter.formatNumber(currentPrice));
    final noteCtrl = TextEditingController(text: item.notes ?? '');
    final List<ModifierItemModel> selectedModifiers = List.from(item.selectedModifiers);

    final availableUnits = item.product.availableUnits.isNotEmpty
        ? item.product.availableUnits
        : [
            ProductUnitOption(
              id: item.product.baseUnitId ?? 1,
              name: item.product.unitName ?? 'Pcs',
              shortName: item.product.unitName ?? 'pcs',
              ratio: 1.0,
            ),
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final modExtra = selectedModifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);
          final total = currentQty * (currentPrice + modExtra);

          Future<void> onUnitChanged(ProductUnitOption unitOpt) async {
            selectedUnitId = unitOpt.id;
            selectedUnitName = unitOpt.name;
            final qtyNow = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? currentQty;

            final resolvedPrice = await pos.resolveProductUnitPrice(item.product.id, unitOpt.id, quantity: qtyNow);
            setModalState(() {
              if (resolvedPrice != null && resolvedPrice > 0) {
                currentPrice = resolvedPrice;
              } else {
                currentPrice = item.product.sellingPrice * unitOpt.ratio;
              }
              priceCtrl.text = CurrencyFormatter.formatNumber(currentPrice);
            });
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with product details & Remove button
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.package, color: AppColors.primary, size: 26),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    selectedUnitName,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Stok: ${_formatQuantity(item.product.stock)} ${item.product.unitName ?? ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: item.product.stock > 0 ? AppColors.textSecondary : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
                        tooltip: 'Hapus Item',
                        onPressed: () {
                          pos.removeFromCart(index);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pilihan Satuan Jual
                  const Text('Pilih Satuan Jual',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableUnits.map((u) {
                      final isSelected = u.id == selectedUnitId;
                      return ChoiceChip(
                        label: Text(
                          u.name + (u.ratio > 1 ? ' (${_formatQuantity(u.ratio)} ${item.product.unitName ?? "pcs"})' : ''),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.inputBackground,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            onUnitChanged(u);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Quantity Section (Stepper + Manual Input supporting decimals)
                  const Text('Jumlah / Kuantitas (Bisa Desimal, misal 0.5 atau 1.25)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Direct Qty TextField
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '1.0',
                            prefixIcon: const Icon(LucideIcons.scale, size: 18),
                            suffixText: selectedUnitName,
                            suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.replaceAll(',', '.'));
                            if (parsed != null && parsed >= 0) {
                              setModalState(() {
                                currentQty = parsed;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Stepper quick buttons
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            _buildCircleBtn(LucideIcons.minus, () {
                              if (currentQty > 1) {
                                setModalState(() {
                                  currentQty = (currentQty - 1);
                                  qtyCtrl.text = _formatQuantity(currentQty);
                                });
                              } else if (currentQty > 0.1) {
                                setModalState(() {
                                  currentQty = double.parse((currentQty - 0.1).toStringAsFixed(2));
                                  qtyCtrl.text = _formatQuantity(currentQty);
                                });
                              }
                            }),
                            _buildCircleBtn(LucideIcons.plus, () {
                              setModalState(() {
                                currentQty = (currentQty + 1);
                                qtyCtrl.text = _formatQuantity(currentQty);
                              });
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Custom Price Section
                  const Text('Harga Satuan (Rp)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    readOnly: !pos.allowManualPriceEdit,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(pos.allowManualPriceEdit ? LucideIcons.tag : LucideIcons.lock, size: 18),
                      suffixIcon: !pos.allowManualPriceEdit
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              child: Text('Terkunci', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            )
                          : IconButton(
                              icon: const Icon(LucideIcons.rotateCcw, size: 16, color: AppColors.textMuted),
                              tooltip: 'Reset Harga Normal Satuan',
                              onPressed: () async {
                                final currentSelectedUnit = availableUnits.firstWhere(
                                  (u) => u.id == selectedUnitId,
                                  orElse: () => availableUnits.first,
                                );
                                final qtyNow = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? currentQty;
                                final resolved = await pos.resolveProductUnitPrice(item.product.id, currentSelectedUnit.id, quantity: qtyNow);
                                setModalState(() {
                                  if (resolved != null && resolved > 0) {
                                    currentPrice = resolved;
                                  } else {
                                    currentPrice = item.product.sellingPrice * currentSelectedUnit.ratio;
                                  }
                                  priceCtrl.text = CurrencyFormatter.formatNumber(currentPrice);
                                });
                              },
                            ),
                    ),
                    onChanged: (val) {
                      if (!pos.allowManualPriceEdit) return;
                      setModalState(() {
                        currentPrice = CurrencyFormatter.parseCleanNumber(val);
                      });
                    },
                  ),
                  // Modifiers / Topping Ekstra
                  if (item.product.modifierGroups.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Pilihan Topping & Racikan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    ...item.product.modifierGroups.map((group) {
                      final isSingle = group.selectionType == 'single';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: group.isRequired ? AppColors.errorSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: group.isRequired ? AppColors.error : AppColors.border),
                                  ),
                                  child: Text(
                                    group.isRequired ? 'Wajib' : 'Opsional',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: group.isRequired ? AppColors.error : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.modifiers.map((mod) {
                                final isSelected = selectedModifiers.any((m) => m.id == mod.id);
                                return FilterChip(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                  selected: isSelected,
                                  selectedColor: AppColors.primarySurface,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  showCheckmark: true,
                                  checkmarkColor: AppColors.primary,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        mod.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                      ),
                                      if (mod.priceAdjustment > 0) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '+${CurrencyFormatter.format(mod.priceAdjustment)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (isSingle) {
                                        selectedModifiers.removeWhere((m) => m.modifierGroupId == group.id);
                                        if (selected) {
                                          selectedModifiers.add(mod);
                                        }
                                      } else {
                                        if (selected) {
                                          selectedModifiers.add(mod);
                                        } else {
                                          selectedModifiers.removeWhere((m) => m.id == mod.id);
                                        }
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 14),

                  // Notes / Modifier Input
                  const Text('Catatan Khusus Pesanan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (_resolveItemNotePresets(item.product).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _resolveItemNotePresets(item.product).map((preset) {
                        final isSelected = noteCtrl.text.contains(preset);
                        return ActionChip(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: isSelected ? AppColors.primarySurface : AppColors.inputBackground,
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                          label: Text(
                            '+ $preset',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                          onPressed: () {
                            setModalState(() {
                              if (noteCtrl.text.trim().isEmpty) {
                                noteCtrl.text = preset;
                              } else if (!noteCtrl.text.contains(preset)) {
                                noteCtrl.text = '${noteCtrl.text.trim()}, $preset';
                              } else {
                                final parts = noteCtrl.text.split(',').map((s) => s.trim()).where((s) => s != preset && s.isNotEmpty).toList();
                                noteCtrl.text = parts.join(', ');
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Kurang manis, ekstra pedas, potongan kecil...',
                      prefixIcon: Icon(LucideIcons.fileText, size: 18),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtotal display and Save Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Subtotal Item', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            CurrencyFormatter.format(total),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(LucideIcons.check, size: 18),
                        label: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final parsedQty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? currentQty;
                          pos.updateItemQty(index, parsedQty);
                          pos.updateItemUnit(index, selectedUnitId, selectedUnitName, newPrice: currentPrice);
                          pos.updateItemModifiers(index, selectedModifiers);
                          pos.updateItemNotes(index, noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null);
                          Navigator.pop(ctx);
                        },
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
  );
}

  // ===========================================================================
  // 4. HOLD & RECALL MODAL
  // ===========================================================================
  void _showHoldDialog(BuildContext context) {
    final pos = context.read<PosProvider>();
    final noteCtrl = TextEditingController(
      text: pos.selectedCustomer != null ? pos.selectedCustomer!.name : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(LucideIcons.pauseCircle, color: AppColors.warning, size: 20),
            SizedBox(width: 8),
            Text('Hold Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Simpan sementara transaksi ini untuk dilanjutkan nanti tanpa kehilangan data keranjang.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Label Referensi / Meja / Nama',
                prefixIcon: Icon(LucideIcons.bookmark, size: 18),
              ),
            ),
          ],
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
              final ok = await pos.holdCart(noteCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pesanan berhasil di-hold!')),
                  );
                }
              }
            },
            child: const Text('Simpan Hold', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRecallSheet(BuildContext context) {
    final pos = context.read<PosProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FutureBuilder<List<dynamic>>(
        future: pos.getHeldList(),
        builder: (context, snapshot) {
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.65,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recall Transaksi Tertahan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Buka kembali pesanan yang pernah di-hold', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : (snapshot.data == null || snapshot.data!.isEmpty)
                            ? const Center(
                                child: Text('Tidak ada transaksi yang sedang di-hold', style: TextStyle(color: AppColors.textMuted)),
                              )
                            : ListView.separated(
                                itemCount: snapshot.data!.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final item = snapshot.data![idx];
                                  final label = item['reference_label'] ?? 'Held #${item['id']}';
                                  final cust = item['customer'] != null ? item['customer']['name'] : 'Umum';
                                  final itemsCount = (item['cart_payload'] as List?)?.length ?? 0;

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBackground,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                            const SizedBox(height: 2),
                                            Text('Pelanggan: $cust • $itemsCount item', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                          onPressed: () async {
                                            final ok = await pos.recallHeld(item['id']);
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx);
                                              if (ok) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Pesanan "$label" berhasil dipulihkan!')),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Buka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 5. MODERN & ELEGANT CART SLIDE-UP SHEET
  // ===========================================================================
  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<PosProvider>(
          builder: (context, pos, _) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.86,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle indicator bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 6),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.shoppingBag, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Keranjang Pesanan',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                                ),
                                Text(
                                  '${pos.totalItemCount} barang dipilih',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (pos.cartItems.isNotEmpty)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              backgroundColor: AppColors.errorSurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(LucideIcons.trash2, size: 14),
                            label: const Text('Kosongkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              pos.clearCart();
                              Navigator.pop(ctx);
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),

                  // Itemized Card List
                  Expanded(
                    child: pos.cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: const BoxDecoration(
                                    color: AppColors.inputBackground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.shoppingBag, size: 38, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 12),
                                const Text('Keranjang Belanja Kosong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                const Text('Pilih produk dari katalog untuk memesan', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(18),
                            itemCount: pos.cartItems.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = pos.cartItems[idx];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showCartItemEditModal(context, idx),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Product Thumbnail Box
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: AppColors.inputBackground,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: AppColors.border),
                                              ),
                                              child: const Center(
                                                child: Icon(LucideIcons.package, size: 22, color: AppColors.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Product Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.product.name,
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${CurrencyFormatter.format(item.unitPrice)} / ${item.unitName ?? item.product.unitName ?? 'pcs'}',
                                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                                                      ),
                                                      if (item.unitPrice != item.product.sellingPrice) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primarySurface,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: const Text('Custom', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Subtotal
                                            Text(
                                              CurrencyFormatter.format(item.subtotal),
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),

                                        // Selected Modifiers Badges (Topping Ekstra)
                                        if (item.selectedModifiers.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: item.selectedModifiers.map((m) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.amber.shade200),
                                                ),
                                                child: Text(
                                                  '+ ${m.name}${m.priceAdjustment > 0 ? " (${CurrencyFormatter.format(m.priceAdjustment)})" : ""}',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber.shade900,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],

                                        // Item Notes (if any)
                                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.inputBackground,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.messageSquare, size: 11, color: AppColors.textMuted),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    item.notes!,
                                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 10),
                                        const Divider(height: 1, color: AppColors.divider),
                                        const SizedBox(height: 8),

                                        // Row Bottom Actions: Edit Action & Quantity Stepper
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Quick Edit Button (Edit Qty / Harga / Catatan)
                                            InkWell(
                                              onTap: () => _showCartItemEditModal(context, idx),
                                              borderRadius: BorderRadius.circular(8),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(LucideIcons.edit3, size: 13, color: AppColors.primary),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      'Edit Qty & Harga',
                                                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Elegant Stepper
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.inputBackground,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: AppColors.border),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _buildQtyBtn(
                                                    item.qty <= 1 ? LucideIcons.trash2 : LucideIcons.minus,
                                                    () => pos.decreaseQty(idx),
                                                    color: item.qty <= 1 ? AppColors.error : AppColors.textPrimary,
                                                  ),
                                                  InkWell(
                                                    onTap: () => _showCartItemEditModal(context, idx),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      child: Text(
                                                        _formatQuantity(item.qty),
                                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                                                      ),
                                                    ),
                                                  ),
                                                  _buildQtyBtn(LucideIcons.plus, () => pos.increaseQty(idx)),
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

                  // Elegant Bottom Bill & Action Area
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Promo & Voucher pill button
                        InkWell(
                          onTap: () => _showDiscountModal(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: pos.globalDiscount > 0 || pos.appliedPromoCode.isNotEmpty
                                  ? AppColors.successSurface
                                  : AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: pos.globalDiscount > 0 || pos.appliedPromoCode.isNotEmpty
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.tag,
                                      size: 16,
                                      color: pos.globalDiscount > 0 ? AppColors.success : AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      pos.appliedPromoCode.isNotEmpty
                                          ? 'Promo: ${pos.appliedPromoCode}'
                                          : (pos.globalDiscount > 0 ? 'Diskon Terpasang' : 'Punya Voucher / Diskon?'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: pos.globalDiscount > 0 ? AppColors.success : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      pos.globalDiscount > 0
                                          ? '- ${CurrencyFormatter.format(pos.globalDiscount)}'
                                          : 'Klaim Diskon',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: pos.globalDiscount > 0 ? AppColors.success : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textMuted),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subtotal breakdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text(CurrencyFormatter.format(pos.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (pos.globalDiscount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diskon Transaksi', style: TextStyle(fontSize: 12, color: AppColors.success)),
                              Text('- ${CurrencyFormatter.format(pos.globalDiscount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 10),

                        // Grand Total Banner
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                                Text('Sudah termasuk pajak', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.format(pos.grandTotal),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons: Hold + Pay
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(LucideIcons.pauseCircle, size: 17),
                              label: const Text('Hold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: pos.cartItems.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      _showHoldDialog(context);
                                    },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                icon: const Icon(LucideIcons.arrowRight, size: 18),
                                label: const Text('Lanjut ke Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                onPressed: pos.cartItems.isEmpty
                                    ? null
                                    : () {
                                        Navigator.pop(ctx);
                                        _showCheckoutDialog(context);
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 6. CHECKOUT & PAYMENT DIALOG (WITH SERVICE TYPE / TAKEAWAY SELECTOR)
  // ===========================================================================
  void _showCheckoutDialog(BuildContext context) {
    final pos = context.read<PosProvider>();
    final shift = context.read<ShiftProvider>().currentShift;
    final total = pos.grandTotal;

    String paymentMethod = 'cash';
    double paidAmount = total;
    final paidCtrl = TextEditingController(text: CurrencyFormatter.formatNumber(total));
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final change = paidAmount - total;
          final currentType = pos.serviceType;
          final currentTable = pos.selectedTable;
          final guestCount = pos.guestCount;

          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.90,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 6),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Dialog Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                  child: Row(
                    children: [
                      const Text(
                        'Pembayaran Transaksi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(LucideIcons.pauseCircle, size: 16),
                        label: const Text('Hold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showHoldDialog(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),

                // Scrollable Payment Body
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grand Total Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                  Text(
                                    '${pos.totalItemCount} Item • ${pos.selectedCustomer?.name ?? "Pelanggan Umum"}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.format(total),
                                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 22),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ==========================================
                        // TIPE LAYANAN / PESANAN (Takeaway, Dine-In, Delivery)
                        // ==========================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tipe Layanan / Pesanan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            Text(
                              currentType == 'takeaway' ? 'Bungkus' : (currentType == 'dine_in' ? 'Makan di Meja' : 'Antar'),
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildServiceTypeOption(
                              title: 'Take Away',
                              subtitle: 'Bungkus',
                              icon: LucideIcons.shoppingBag,
                              isSelected: currentType == 'takeaway',
                              onTap: () {
                                pos.setServiceType('takeaway');
                                setModalState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildServiceTypeOption(
                              title: 'Dine In',
                              subtitle: 'Makan Meja',
                              icon: LucideIcons.utensils,
                              isSelected: currentType == 'dine_in',
                              onTap: () {
                                pos.setServiceType('dine_in');
                                setModalState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildServiceTypeOption(
                              title: 'Delivery',
                              subtitle: 'Kirim Antar',
                              icon: LucideIcons.truck,
                              isSelected: currentType == 'delivery',
                              onTap: () {
                                pos.setServiceType('delivery');
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),

                        // Dine-In Specific Details (Tables & Guests)
                        if (currentType == 'dine_in') ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(LucideIcons.users, size: 16, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Jumlah Pengunjung/Tamu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _buildCircleBtn(LucideIcons.minus, () {
                                          if (guestCount > 1) {
                                            pos.setGuestCount(guestCount - 1);
                                            setModalState(() {});
                                          }
                                        }),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            '$guestCount',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                          ),
                                        ),
                                        _buildCircleBtn(LucideIcons.plus, () {
                                          pos.setGuestCount(guestCount + 1);
                                          setModalState(() {});
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text('Pilih Meja:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                const SizedBox(height: 6),
                                if (pos.tables.isEmpty)
                                  const Text('Tidak ada meja aktif', style: TextStyle(fontSize: 11, color: AppColors.textMuted))
                                else
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: pos.tables.map((table) {
                                      final isChosen = currentTable?.id == table.id;
                                      return ChoiceChip(
                                        avatar: Icon(
                                          LucideIcons.coffee,
                                          size: 13,
                                          color: isChosen ? Colors.white : (table.isAvailable ? AppColors.success : AppColors.error),
                                        ),
                                        label: Text(
                                          'Meja ${table.tableNumber}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isChosen ? Colors.white : AppColors.textPrimary),
                                        ),
                                        selected: isChosen,
                                        selectedColor: AppColors.primary,
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: isChosen ? AppColors.primary : AppColors.border),
                                        onSelected: (_) {
                                          pos.setSelectedTable(isChosen ? null : table);
                                          setModalState(() {});
                                        },
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // ==========================================
                        // METODE PEMBAYARAN
                        // ==========================================
                        const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPaymentChip('cash', 'Tunai', LucideIcons.banknote, paymentMethod, (val) => setModalState(() => paymentMethod = val)),
                            const SizedBox(width: 8),
                            _buildPaymentChip('qris', 'QRIS', LucideIcons.qrCode, paymentMethod, (val) {
                              setModalState(() {
                                paymentMethod = val;
                                paidAmount = total;
                                paidCtrl.text = CurrencyFormatter.formatNumber(total);
                              });
                            }),
                            const SizedBox(width: 8),
                            _buildPaymentChip('transfer', 'Transfer', LucideIcons.arrowRightLeft, paymentMethod, (val) {
                              setModalState(() {
                                paymentMethod = val;
                                paidAmount = total;
                                paidCtrl.text = CurrencyFormatter.formatNumber(total);
                              });
                            }),
                            const SizedBox(width: 8),
                            _buildPaymentChip('credit', 'Piutang', LucideIcons.userCheck, paymentMethod, (val) {
                              setModalState(() {
                                paymentMethod = val;
                                paidAmount = 0;
                                paidCtrl.text = '0';
                              });
                            }),
                          ],
                        ),

                        // Cash Input & Change
                        if (paymentMethod == 'cash') ...[
                          const SizedBox(height: 16),
                          const Text('Uang Diterima (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: paidCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              ThousandsSeparatorInputFormatter(),
                            ],
                            decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.coins, size: 18)),
                            onChanged: (val) {
                              setModalState(() {
                                paidAmount = CurrencyFormatter.parseCleanNumber(val);
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final List<double> smartPresets = [];
                              final Set<int> presetSet = {};

                              if (total > 0) {
                                final int intTotal = total.ceil();

                                // 1. Pembulatan 5.000 terdekat
                                final ceil5k = ((intTotal + 4999) ~/ 5000) * 5000;
                                if (ceil5k > intTotal) presetSet.add(ceil5k);

                                // 2. Pembulatan 10.000 terdekat
                                final ceil10k = ((intTotal + 9999) ~/ 10000) * 10000;
                                if (ceil10k > intTotal) presetSet.add(ceil10k);

                                // 3. Pembulatan 20.000 terdekat
                                final ceil20k = ((intTotal + 19999) ~/ 20000) * 20000;
                                if (ceil20k > intTotal) presetSet.add(ceil20k);

                                // 4. Pembulatan 50.000 terdekat
                                final ceil50k = ((intTotal + 49999) ~/ 50000) * 50000;
                                if (ceil50k > intTotal) presetSet.add(ceil50k);

                                // 5. Pembulatan 100.000 terdekat
                                final ceil100k = ((intTotal + 99999) ~/ 100000) * 100000;
                                if (ceil100k > intTotal) presetSet.add(ceil100k);

                                // 6. Pecahan standar uang kertas di atas total
                                for (final denom in [20000, 50000, 100000, 200000, 500000]) {
                                  if (denom > intTotal) presetSet.add(denom);
                                }

                                final sorted = presetSet.toList()..sort();
                                smartPresets.addAll(sorted.take(5).map((e) => e.toDouble()));
                              } else {
                                smartPresets.addAll([10000.0, 20000.0, 50000.0, 100000.0]);
                              }

                              return Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ActionChip(
                                    backgroundColor: AppColors.primarySurface,
                                    side: const BorderSide(color: AppColors.primary),
                                    label: const Text('Uang Pas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    onPressed: () {
                                      setModalState(() {
                                        paidAmount = total;
                                        paidCtrl.text = CurrencyFormatter.formatNumber(total);
                                      });
                                    },
                                  ),
                                  ...smartPresets.map(
                                    (preset) => ActionChip(
                                      backgroundColor: AppColors.inputBackground,
                                      side: const BorderSide(color: AppColors.border),
                                      label: Text(
                                        CurrencyFormatter.formatNumber(preset),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          paidAmount = preset;
                                          paidCtrl.text = CurrencyFormatter.formatNumber(preset);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: change >= 0 ? AppColors.inputBackground : AppColors.errorSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: change >= 0 ? AppColors.border : AppColors.error),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  change >= 0 ? 'Kembalian' : 'Kurang',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: change >= 0 ? AppColors.textPrimary : AppColors.error),
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

                        const SizedBox(height: 12),
                        const Text('Catatan Faktur (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _defaultInvoiceNotePresets.map((preset) {
                            final isSelected = noteCtrl.text.contains(preset);
                            return ActionChip(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: isSelected ? AppColors.primarySurface : AppColors.inputBackground,
                              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                              label: Text(
                                '+ $preset',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  if (noteCtrl.text.trim().isEmpty) {
                                    noteCtrl.text = preset;
                                  } else if (!noteCtrl.text.contains(preset)) {
                                    noteCtrl.text = '${noteCtrl.text.trim()}, $preset';
                                  } else {
                                    final parts = noteCtrl.text.split(',').map((s) => s.trim()).where((s) => s != preset && s.isNotEmpty).toList();
                                    noteCtrl.text = parts.join(', ');
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: noteCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Misal: Titipan pelanggan, meja 3...',
                            prefixIcon: Icon(LucideIcons.fileText, size: 18),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons: Hold and Selesaikan Transaksi
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning, width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(LucideIcons.pauseCircle, size: 18),
                              label: const Text('Hold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showHoldDialog(context);
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  onPressed: (paymentMethod == 'cash' && change < 0)
                                      ? null
                                      : () async {
                                          final result = await pos.checkout(
                                            shiftId: shift?.id,
                                            serviceType: pos.serviceType,
                                            tableId: pos.selectedTable?.id,
                                            guestCount: pos.guestCount,
                                            paymentMethod: paymentMethod,
                                            paidAmount: paidAmount,
                                            notes: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                                          );

                                          if (ctx.mounted) {
                                            Navigator.pop(ctx);
                                            if (result != null) {
                                              _showReceiptSuccessSheet(context, result);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(pos.errorMessage ?? 'Gagal memproses pembayaran.'),
                                                  backgroundColor: AppColors.error,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  child: const Text('Selesaikan Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  // ===========================================================================
  // 7. THERMAL RECEIPT PREVIEW MODAL
  // ===========================================================================
  void _showReceiptSuccessSheet(BuildContext context, Map<String, dynamic> result) {
    final invNumber = result['invoice_number'] ?? '-';
    final grandTotal = double.tryParse((result['grand_total'] ?? 0).toString()) ?? 0.0;
    final changeAmount = double.tryParse((result['change_amount'] ?? 0).toString()) ?? 0.0;
    final payMethod = (result['payment_method'] ?? 'cash').toString().toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.successSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCheck, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 12),
            const Text('Transaksi Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('No. Faktur: $invNumber', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 14),

            // Thermal Slip Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Metode Bayar', payMethod),
                  const SizedBox(height: 6),
                  _buildReceiptRow('Total Tagihan', CurrencyFormatter.format(grandTotal), isBold: true),
                  if (changeAmount > 0) ...[
                    const SizedBox(height: 6),
                    _buildReceiptRow('Kembalian', CurrencyFormatter.format(changeAmount), isBold: true, color: AppColors.success),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(LucideIcons.printer, size: 16),
                    label: const Text('Cetak Bluetooth', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perintah cetak Bluetooth dikirim ke printer thermal!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Transaksi Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String title, String val, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================
  Widget _buildServiceTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String id, String label, IconData icon, String selected, ValueChanged<String> onSelected) {
    final isSelected = id == selected;
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14, color: color ?? AppColors.textPrimary),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }

  // ===========================================================================
  // MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Top Modern Orange Header extending behind status bar
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    children: [
                  // Row 1: Customer Selector Pill & Recall Action
                  Row(
                    children: [
                      // Customer Picker Pill
                      Expanded(
                        child: InkWell(
                          onTap: () => _showCustomerPickerSheet(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.user, size: 14, color: AppColors.primary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PELANGGAN',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.5),
                                      ),
                                      Text(
                                        pos.selectedCustomer?.name ?? 'Pelanggan Umum (Retail)',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(LucideIcons.chevronDown, size: 14, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Recall Quick Icon
                      InkWell(
                        onTap: () => _showRecallSheet(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: const Row(
                            children: [
                              Icon(LucideIcons.playCircle, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Recall', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search & Barcode Scan Bar
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Cari produk / barcode...',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              isCollapsed: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (val) => pos.search(val),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textMuted),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            tooltip: 'Hapus Pencarian',
                            onPressed: () {
                              _searchCtrl.clear();
                              pos.search('');
                            },
                          ),
                        Container(
                          height: 24,
                          width: 1,
                          color: AppColors.border,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        InkWell(
                          onTap: () => _showBarcodeScannerModal(context),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.scanLine, size: 15, color: AppColors.primary),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Scan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Horizontal Categories Filter Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      backgroundColor: Colors.white,
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    onSelected: (_) => pos.selectCategory(cat),
                  );
                },
              ),
            ),

            // Product Cards Grid
            Expanded(
              child: pos.isLoadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : pos.products.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada produk ditemukan',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(14),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.88,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: pos.products.length,
                          itemBuilder: (context, index) {
                            final product = pos.products[index];
                            final cartItem = pos.cartItems.cast<dynamic>().firstWhere(
                                  (item) => item.product.id == product.id,
                                  orElse: () => null,
                                );
                            final cartCount = cartItem?.qty.toInt() ?? 0;

                            return _buildProductCard(context, product, cartCount);
                          },
                        ),
            ),
          ],
        ),

      // Floating Cart Bottom Bar
      bottomNavigationBar: pos.cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showCartBottomSheet(context),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pos.totalItemCount} Item di Keranjang',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              CurrencyFormatter.format(pos.grandTotal),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(LucideIcons.shoppingBag, size: 16),
                      label: const Text('Lihat Keranjang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () => _showCartBottomSheet(context),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, int cartCount) {
    final pos = context.read<PosProvider>();

    return InkWell(
      onTap: () => pos.addToCart(product),
      onLongPress: () => _showItemCustomModal(context, product),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cartCount > 0 ? AppColors.primary : AppColors.border,
            width: cartCount > 0 ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.package, color: AppColors.textMuted, size: 28),
                    ),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(product.sellingPrice),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 12),
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
    );
  }
}
