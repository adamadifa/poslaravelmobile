import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/master_data/screens/account_form_screen.dart';
import 'package:poslaravelmobile/features/master_data/screens/account_mutations_screen.dart';

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedType = 'all';

  final List<Map<String, String>> _types = [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'cash', 'label': 'Kas Fisik'},
    {'key': 'bank', 'label': 'Bank Operasional'},
    {'key': 'bank_agent', 'label': 'Agen Bank / EDC'},
    {'key': 'ppob_provider', 'label': 'Deposit PPOB'},
    {'key': 'other', 'label': 'Lainnya'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    context.read<MasterDataProvider>().fetchAccounts(
          type: _selectedType,
          search: _searchCtrl.text.trim(),
        );
  }

  void _openForm([AccountModel? account]) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(account: account),
      ),
    );
    if (res == true && mounted) {
      _loadData();
    }
  }

  void _openMutations(AccountModel account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountMutationsScreen(account: account),
      ),
    );
  }

  void _confirmDelete(AccountModel account) {
    if (account.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun default/utama tidak dapat dihapus.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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
              'Hapus Akun Kas?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "${account.name}" (${account.accountCode})?\nPastikan akun ini tidak memiliki riwayat transaksi aktif yang terkunci.',
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
              final ok = await context.read<MasterDataProvider>().deleteAccount(account.id);
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Akun "${account.name}" berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  final err = context.read<MasterDataProvider>().errorMessage ?? 'Gagal menghapus akun';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MasterDataProvider>();
    final summary = provider.accountSummary;
    final accounts = provider.accounts;

    final double totalBalance = double.tryParse((summary['total_balance'] ?? 0).toString()) ?? 0;
    final double totalCash = double.tryParse((summary['total_cash'] ?? 0).toString()) ?? 0;
    final double totalBank = double.tryParse((summary['total_bank'] ?? 0).toString()) ?? 0;
    final double totalBankAgent = double.tryParse((summary['total_bank_agent'] ?? 0).toString()) ?? 0;
    final double totalPpob = double.tryParse((summary['total_ppob'] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akun Kas & Bank',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            Text(
              'Manajemen saldo likuid & rekening',
              style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: Colors.white, size: 20),
            tooltip: 'Tambah Akun',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 3,
        onPressed: () => _openForm(),
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
        label: const Text(
          'Tambah Akun',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // TOP FINANCIAL SUMMARY CARDS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    // Main Highlight Card: Total Saldo Likuid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33EA580C),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TOTAL KAS & BANK LIKUID',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(totalBalance),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Akumulasi seluruh akun kas, bank & deposit aktif',
                                  style: TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.walletCards, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Horizontal scrolling mini summary cards
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _buildMiniSummaryCard(
                            title: 'Kas Fisik Laci',
                            amount: totalCash,
                            subtitle: 'Kas fisik kasir',
                            icon: LucideIcons.banknote,
                            iconColor: const Color(0xFF059669),
                            bgColor: const Color(0xFFECFDF5),
                            borderColor: const Color(0xFFA7F3D0),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniSummaryCard(
                            title: 'Bank Operasional',
                            amount: totalBank,
                            subtitle: 'Rekening operasional',
                            icon: LucideIcons.building2,
                            iconColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                            borderColor: const Color(0xFFBFDBFE),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniSummaryCard(
                            title: 'Saldo Agen Bank',
                            amount: totalBankAgent,
                            subtitle: 'EDC / BRILink dsb',
                            icon: LucideIcons.repeat,
                            iconColor: const Color(0xFF4F46E5),
                            bgColor: const Color(0xFFEEF2FF),
                            borderColor: const Color(0xFFC7D2FE),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniSummaryCard(
                            title: 'Deposit PPOB',
                            amount: totalPpob,
                            subtitle: 'Pulsa, token & tagihan',
                            icon: LucideIcons.smartphone,
                            iconColor: const Color(0xFF0D9488),
                            bgColor: const Color(0xFFF0FDFA),
                            borderColor: const Color(0xFF99F6E4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SEARCH & TYPE FILTER CHIPS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Search box
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: (_) => _loadData(),
                        decoration: InputDecoration(
                          hintText: 'Cari nama akun, nomor rekening, bank...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _loadData();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: _types.map((t) {
                          final isSelected = _selectedType == t['key'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                t['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                ),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedType = t['key']!;
                                });
                                _loadData();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // LIST OF ACCOUNTS
            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (accounts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.wallet, size: 40, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Belum Ada Akun Kas & Bank',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tambahkan akun kas laci, rekening bank, atau deposit PPOB',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                        label: const Text(
                          'Tambah Akun Baru',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = accounts[index];
                      return _buildAccountCard(item);
                    },
                    childCount: accounts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSummaryCard({
    required String title,
    required double amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Icon(icon, size: 13, color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AccountModel item) {
    IconData typeIcon = LucideIcons.wallet;
    Color iconColor = const Color(0xFF059669);
    Color iconBg = const Color(0xFFECFDF5);

    if (item.type == 'bank') {
      typeIcon = LucideIcons.building2;
      iconColor = const Color(0xFF2563EB);
      iconBg = const Color(0xFFEFF6FF);
    } else if (item.type == 'bank_agent') {
      typeIcon = LucideIcons.repeat;
      iconColor = const Color(0xFF4F46E5);
      iconBg = const Color(0xFFEEF2FF);
    } else if (item.type == 'ppob_provider') {
      typeIcon = LucideIcons.smartphone;
      iconColor = const Color(0xFF0D9488);
      iconBg = const Color(0xFFF0FDFA);
    }

    final isLowBalance = item.isLowBalance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowBalance ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isLowBalance ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(typeIcon, color: iconColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Account Title & Badges
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
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (item.isDefault) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: const Text(
                                'Utama POS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.accountCode,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.typeLabel,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Account Details (Bank Name / Account Number / Holder)
          if (item.bankName != null || item.accountNumber != null || item.accountHolder != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.creditCard, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        [
                          if (item.bankName != null && item.bankName!.isNotEmpty) item.bankName,
                          if (item.accountNumber != null && item.accountNumber!.isNotEmpty) item.accountNumber,
                          if (item.accountHolder != null && item.accountHolder!.isNotEmpty) 'a/n ${item.accountHolder}',
                        ].join(' • '),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Balance Display & Low Balance Alert
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo Saat Ini',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(item.currentBalance),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isLowBalance ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                if (isLowBalance)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.alertCircle, size: 12, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'Saldo Rendah',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.isActive ? 'Aktif' : 'Non-Aktif',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.isActive ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Bottom Action Bar (Buku Mutasi, Edit, Hapus)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Buku Mutasi Button
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _openMutations(item),
                    icon: const Icon(LucideIcons.fileText, size: 14, color: AppColors.primary),
                    label: const Text(
                      'Buku Mutasi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
                // Edit Button
                IconButton(
                  icon: const Icon(LucideIcons.edit2, size: 15, color: Color(0xFF64748B)),
                  tooltip: 'Edit Akun',
                  onPressed: () => _openForm(item),
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 15, color: Color(0xFFEF4444)),
                  tooltip: 'Hapus Akun',
                  onPressed: () => _confirmDelete(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
