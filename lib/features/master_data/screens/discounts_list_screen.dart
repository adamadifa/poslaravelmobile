import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/discount_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/master_data/screens/discount_form_screen.dart';

class DiscountsListScreen extends StatefulWidget {
  const DiscountsListScreen({super.key});

  @override
  State<DiscountsListScreen> createState() => _DiscountsListScreenState();
}

class _DiscountsListScreenState extends State<DiscountsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedTypeFilter = 'all';

  final List<Map<String, String>> _filterTypes = [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'percentage_item', 'label': '% Item'},
    {'key': 'fixed_item', 'label': 'Rp Item'},
    {'key': 'percentage_invoice', 'label': '% Nota'},
    {'key': 'fixed_invoice', 'label': 'Rp Nota'},
    {'key': 'buy_x_get_y', 'label': 'Buy X Get Y'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().fetchDiscounts();
      context.read<MasterDataProvider>().fetchProducts();
      context.read<MasterDataProvider>().fetchCustomerGroups();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDiscountForm([DiscountModel? discount]) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DiscountFormScreen(discount: discount),
      ),
    );
    if (res == true && mounted) {
      context.read<MasterDataProvider>().fetchDiscounts();
      context.read<MasterDataProvider>().fetchSummary();
    }
  }

  void _confirmDeleteDiscount(DiscountModel item) {
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
              'Hapus Promo?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus promo "${item.name}"?\nPromo ini tidak akan dapat digunakan lagi di kasir.',
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
              final ok = await context.read<MasterDataProvider>().deleteDiscount(item.id);
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Promo "${item.name}" berhasil dihapus.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<MasterDataProvider>().errorMessage ?? 'Gagal menghapus promo.'),
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
              'Diskon & Promosi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Kelola kupon belanja, potongan harga & Buy X Get Y',
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
                onChanged: (val) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Cari promo, kupon, atau deskripsi...',
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
          // Filter Chips (Type)
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filterTypes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final f = _filterTypes[idx];
                final isSelected = _selectedTypeFilter == f['key'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTypeFilter = f['key']!;
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

          // List Body
          Expanded(
            child: Consumer<MasterDataProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.discounts.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final query = _searchCtrl.text.toLowerCase().trim();
                var list = provider.discounts;

                // Apply type filter
                if (_selectedTypeFilter != 'all') {
                  list = list.where((d) => d.type == _selectedTypeFilter).toList();
                }

                // Apply search filter
                if (query.isNotEmpty) {
                  list = list.where((d) {
                    final n = d.name.toLowerCase();
                    final c = (d.code ?? '').toLowerCase();
                    final desc = (d.description ?? '').toLowerCase();
                    return n.contains(query) || c.contains(query) || desc.contains(query);
                  }).toList();
                }

                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchDiscounts(),
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
                                  LucideIcons.badgePercent,
                                  size: 32,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                query.isNotEmpty || _selectedTypeFilter != 'all'
                                    ? 'Tidak ada promo yang cocok'
                                    : 'Belum Ada Promo / Diskon',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                query.isNotEmpty || _selectedTypeFilter != 'all'
                                    ? 'Coba ubah kata kunci pencarian atau filter tipe.'
                                    : 'Buat promo diskon pertama Anda untuk meningkatkan penjualan.',
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
                                onPressed: () => _openDiscountForm(),
                                icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                                label: const Text(
                                  'Tambah Promo Baru',
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
                  onRefresh: () => provider.fetchDiscounts(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final item = list[idx];
                      return _buildDiscountCard(item);
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
        onPressed: () => _openDiscountForm(),
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
        label: const Text(
          'Tambah Promo',
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

  Widget _buildDiscountCard(DiscountModel item) {
    Color typeBg;
    Color typeColor;
    IconData typeIcon;

    switch (item.type) {
      case 'percentage_item':
      case 'percentage_invoice':
        typeBg = const Color(0xFFEFF6FF);
        typeColor = const Color(0xFF2563EB);
        typeIcon = LucideIcons.percent;
        break;
      case 'fixed_item':
      case 'fixed_invoice':
        typeBg = const Color(0xFFECFDF5);
        typeColor = const Color(0xFF059669);
        typeIcon = LucideIcons.dollarSign;
        break;
      case 'buy_x_get_y':
        typeBg = const Color(0xFFFAF5FF);
        typeColor = const Color(0xFF7C3AED);
        typeIcon = LucideIcons.gift;
        break;
      default:
        typeBg = const Color(0xFFF1F5F9);
        typeColor = const Color(0xFF475569);
        typeIcon = LucideIcons.tag;
    }

    final isExpired = item.isExpired;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !item.isActive
              ? const Color(0xFFE2E8F0)
              : isExpired
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0),
        ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(typeIcon, color: typeColor, size: 19),
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
                              item.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: !item.isActive
                                  ? const Color(0xFFF1F5F9)
                                  : isExpired
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              !item.isActive
                                  ? 'Nonaktif'
                                  : isExpired
                                      ? 'Kedaluwarsa'
                                      : 'Aktif',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: !item.isActive
                                    ? const Color(0xFF64748B)
                                    : isExpired
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          // Type Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: typeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.typeLabel,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: typeColor,
                              ),
                            ),
                          ),
                          if (item.code != null && item.code!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.ticket, size: 9, color: Color(0xFFEA580C)),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.code!,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Value Highlight Banner
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
                      'POTONGAN PROMO',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.valueFormatted,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
                if (item.customerGroupName != null && item.customerGroupName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.users, size: 10, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          item.customerGroupName!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Semua Pelanggan',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details List
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Validity date
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.startDate != null && item.endDate != null
                            ? '${item.startDate} s/d ${item.endDate}'
                            : (item.startDate != null
                                ? 'Mulai ${item.startDate}'
                                : (item.endDate != null
                                    ? 'Berakhir ${item.endDate}'
                                    : 'Tanpa Batas Waktu')),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Min Order / Max Discount
                if (item.minOrderAmount > 0 || item.maxDiscountAmount > 0) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.info, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            if (item.minOrderAmount > 0)
                              'Min: ${CurrencyFormatter.format(item.minOrderAmount)}',
                            if (item.maxDiscountAmount > 0)
                              'Maks: ${CurrencyFormatter.format(item.maxDiscountAmount)}',
                          ].join(' • '),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Reward product if Buy X Get Y
                if (item.type == 'buy_x_get_y' && item.rewardProductName != null) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.gift, size: 12, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Hadiah: ${item.rewardProductName}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Targeted items count
                if (item.productIds.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.box, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Berlaku untuk ${item.productIds.length} produk khusus',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Combinable badge
                if (item.isCombinable)
                  Row(
                    children: [
                      const Icon(LucideIcons.layers, size: 12, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Dapat digabung dengan promo lain',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const Divider(height: 12, color: Color(0xFFF1F5F9)),

          // Actions Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit Button
                InkWell(
                  onTap: () => _openDiscountForm(item),
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
                const SizedBox(width: 8),

                // Delete Button
                InkWell(
                  onTap: () => _confirmDeleteDiscount(item),
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
            ),
          ),
        ],
      ),
    );
  }
}
