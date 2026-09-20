import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';
import 'package:poslaravelmobile/data/models/account_transfer_model.dart';
import 'package:poslaravelmobile/features/finance/providers/account_transfer_provider.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class AccountTransfersListScreen extends StatefulWidget {
  const AccountTransfersListScreen({super.key});

  @override
  State<AccountTransfersListScreen> createState() => _AccountTransfersListScreenState();
}

class _AccountTransfersListScreenState extends State<AccountTransfersListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _dateFilterMode = 'all'; // all, today, 7days, this_month

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountTransferProvider>().fetchTransfers(refresh: true);
      context.read<MasterDataProvider>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyDateFilter(String mode) {
    setState(() => _dateFilterMode = mode);
    final now = DateTime.now();
    String? start;
    String? end;

    if (mode == 'today') {
      start = DateFormat('yyyy-MM-dd').format(now);
      end = DateFormat('yyyy-MM-dd').format(now);
    } else if (mode == '7days') {
      start = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 6)));
      end = DateFormat('yyyy-MM-dd').format(now);
    } else if (mode == 'this_month') {
      start = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
      end = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));
    }

    context.read<AccountTransferProvider>().setDateRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.watch<AccountTransferProvider>();
    final masterProvider = context.watch<MasterDataProvider>();

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
              'Transfer Kas & Bank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Pindah dana antar kas, bank & deposit',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
            onPressed: () => transferProvider.fetchTransfers(refresh: true),
            tooltip: 'Segarkan Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await transferProvider.fetchTransfers(refresh: true);
          await masterProvider.fetchAccounts();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top Summary Hero Card
            SliverToBoxAdapter(
              child: _buildSummaryHero(transferProvider.summary),
            ),

            // Filter Bar (Search & Quick Dates)
            SliverToBoxAdapter(
              child: _buildFilterSection(transferProvider, masterProvider.accounts),
            ),

            // Transfers List Items
            if (transferProvider.isLoading && transferProvider.transfers.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (transferProvider.transfers.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = transferProvider.transfers[index];
                      return _buildTransferCard(item);
                    },
                    childCount: transferProvider.transfers.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.arrowLeftRight, color: Colors.white),
        label: const Text(
          'Transfer Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddTransferSheet(context),
      ),
    );
  }

  Widget _buildSummaryHero(AccountTransferSummary summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33EA580C),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.arrowLeftRight, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TOTAL MUTASI TRANSFER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary.formattedTotalTransferred,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.receipt, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Total Biaya Admin: ${summary.formattedTotalFee}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(AccountTransferProvider provider, List<AccountModel> accounts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Account Filter in one row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari nomor transfer / ket...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF64748B)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchCtrl.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onSubmitted: (val) => provider.setSearchQuery(val.trim()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Account Filter Dropdown Button
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: provider.fromAccountId != null
                        ? AppColors.primary
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: provider.fromAccountId,
                    hint: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.landmark, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text('Akun Asal', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    icon: const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF64748B)),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Semua Akun Asal', style: TextStyle(fontSize: 13)),
                      ),
                      ...accounts.map(
                        (acc) => DropdownMenuItem<int?>(
                          value: acc.id,
                          child: Text(acc.name, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                    onChanged: (val) => provider.setFromAccount(val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Date Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateChip('Semua Waktu', 'all'),
                const SizedBox(width: 6),
                _buildDateChip('Hari Ini', 'today'),
                const SizedBox(width: 6),
                _buildDateChip('7 Hari Terakhir', '7days'),
                const SizedBox(width: 6),
                _buildDateChip('Bulan Ini', 'this_month'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, String mode) {
    final isSelected = _dateFilterMode == mode;
    return InkWell(
      onTap: () => _applyDateFilter(mode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransferCard(AccountTransferModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _showDetailSheet(context, item),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Transfer Number & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.transferNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Text(
                      item.formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Transfer Route: From Account -> To Account
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      // From Account
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DARI AKUN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.fromAccount?.name ?? 'Akun Asal',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Arrow indicator
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.primary),
                      ),
                      // To Account
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'KE AKUN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.toAccount?.name ?? 'Akun Tujuan',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
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
                const SizedBox(height: 10),

                // Amount and Fees
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.formattedAmount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (item.transferFee > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Text(
                          'Admin: ${item.formattedFee}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.notes!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.arrowLeftRight,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat Transfer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pindahkan saldo kas ke bank atau sebaliknya menggunakan tombol di bawah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, AccountTransferModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AccountTransferDetailSheet(item: item),
    );
  }

  void _showAddTransferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddAccountTransferSheet(),
    );
  }
}

// ==========================================================
// DETAIL SHEET WIDGET
// ==========================================================
class _AccountTransferDetailSheet extends StatelessWidget {
  final AccountTransferModel item;

  const _AccountTransferDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Transfer Kas/Bank',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.arrowLeftRight, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nominal Ditransfer',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9A3412), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.formattedAmount,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Nomor Transfer', item.transferNumber),
          _buildDetailRow('Tanggal', item.formattedDate),
          _buildDetailRow('Akun Asal (Pengirim)', item.fromAccount?.name ?? '-'),
          _buildDetailRow('Akun Tujuan (Penerima)', item.toAccount?.name ?? '-'),
          if (item.transferFee > 0)
            _buildDetailRow('Biaya Admin Transfer', item.formattedFee),
          _buildDetailRow('Total Saldo Terpotong', item.formattedTotalDeduction),
          if (item.referenceNumber != null && item.referenceNumber!.isNotEmpty)
            _buildDetailRow('No. Referensi / Bukti', item.referenceNumber!),
          if (item.notes != null && item.notes!.isNotEmpty)
            _buildDetailRow('Catatan / Keterangan', item.notes!),
          if (item.creatorName != null)
            _buildDetailRow('Diproses Oleh', item.creatorName!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// ADD FORM SHEET WIDGET
// ==========================================================
class _AddAccountTransferSheet extends StatefulWidget {
  const _AddAccountTransferSheet();

  @override
  State<_AddAccountTransferSheet> createState() => _AddAccountTransferSheetState();
}

class _AddAccountTransferSheetState extends State<_AddAccountTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _fromAccountId;
  int? _toAccountId;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _feeCtrl = TextEditingController();
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _transferDate = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transferDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _transferDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterProvider = context.watch<MasterDataProvider>();
    final transferProvider = context.watch<AccountTransferProvider>();
    final accounts = masterProvider.accounts;

    AccountModel? fromAcc;
    if (_fromAccountId != null) {
      fromAcc = accounts.firstWhere((a) => a.id == _fromAccountId, orElse: () => accounts.first);
    }

    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final double fee = double.tryParse(_feeCtrl.text.trim()) ?? 0.0;
    final double totalDeduction = amount + fee;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Modal Header with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: const Icon(LucideIcons.arrowLeftRight, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transfer Kas & Bank',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Pindahkan dana antar rekening kas/bank',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Akun Asal (Sumber Dana)
              DropdownButtonFormField<int>(
                initialValue: _fromAccountId,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Akun Asal (Sumber Dana) *',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: const Icon(LucideIcons.uploadCloud, size: 18, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                hint: const Text('Pilih Akun Asal', maxLines: 1, overflow: TextOverflow.ellipsis),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem<int>(
                        value: a.id,
                        child: Text(
                          '${a.name} (${CurrencyFormatter.format(a.currentBalance)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _fromAccountId = val;
                    if (_toAccountId == val) _toAccountId = null;
                  });
                },
                validator: (val) => val == null ? 'Pilih akun asal' : null,
              ),

              if (fromAcc != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saldo Tersedia Saat Ini:',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        CurrencyFormatter.format(fromAcc.currentBalance),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: fromAcc.currentBalance > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Akun Tujuan (Penerima Dana)
              DropdownButtonFormField<int>(
                initialValue: _toAccountId,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Akun Tujuan (Penerima Dana) *',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: const Icon(LucideIcons.downloadCloud, size: 18, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                hint: const Text('Pilih Akun Tujuan', maxLines: 1, overflow: TextOverflow.ellipsis),
                items: accounts
                    .where((a) => a.id != _fromAccountId)
                    .map(
                      (a) => DropdownMenuItem<int>(
                        value: a.id,
                        child: Text(
                          '${a.name} (${CurrencyFormatter.format(a.currentBalance)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _toAccountId = val),
                validator: (val) {
                  if (val == null) return 'Pilih akun tujuan';
                  if (val == _fromAccountId) return 'Akun tujuan tidak boleh sama dengan akun asal';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Nominal Transfer
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Nominal Transfer (Rp) *',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  prefixIcon: const Icon(LucideIcons.coins, size: 18, color: Color(0xFF64748B)),
                  hintText: '0',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Masukkan nominal transfer';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Nominal harus lebih dari 0';
                  if (fromAcc != null && (num + fee) > fromAcc.currentBalance) {
                    return 'Saldo akun asal tidak mencukupi (${CurrencyFormatter.format(fromAcc.currentBalance)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Quick preset amount chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAmountChip('+100rb', 100000),
                    const SizedBox(width: 6),
                    _buildAmountChip('+500rb', 500000),
                    const SizedBox(width: 6),
                    _buildAmountChip('+1jt', 1000000),
                    const SizedBox(width: 6),
                    _buildAmountChip('+5jt', 5000000),
                    if (fromAcc != null && fromAcc.currentBalance > 0) ...[
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('Transfer Penuh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        backgroundColor: AppColors.primarySurface,
                        side: const BorderSide(color: Color(0xFFFFEDD5)),
                        onPressed: () {
                          final maxAmount = max(0, fromAcc!.currentBalance - fee);
                          setState(() => _amountCtrl.text = maxAmount.toInt().toString());
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Biaya Admin Transfer
              TextFormField(
                controller: _feeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Biaya Admin / Transfer Fee (Opsional)',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixText: 'Rp ',
                  prefixIcon: const Icon(LucideIcons.receipt, size: 18, color: Color(0xFF64748B)),
                  hintText: '0 (jika ada)',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              // Tanggal Transfer
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Transfer *',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppDateFormatter.format(_transferDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Referensi & Catatan
              TextFormField(
                controller: _refCtrl,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Nomor Bukti / No. Resi (Opsional)',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'Contoh: TRF-ATM-001 / No Referensi Bank',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Catatan / Keterangan (Opsional)',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'Contoh: Setoran uang kas toko sore hari...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Total Calculation Preview Card
              if (amount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Saldo Terpotong:',
                            style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Termasuk biaya admin (jika ada)',
                            style: TextStyle(fontSize: 10, color: Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(totalDeduction),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.send, color: Colors.white, size: 16),
                  onPressed: transferProvider.isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final payload = {
                            'from_account_id': _fromAccountId,
                            'to_account_id': _toAccountId,
                            'amount': double.parse(_amountCtrl.text.trim()),
                            'transfer_fee': _feeCtrl.text.trim().isNotEmpty
                                ? double.parse(_feeCtrl.text.trim())
                                : 0.0,
                            'transfer_date': DateFormat('yyyy-MM-dd').format(_transferDate),
                            'reference_number': _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null,
                            'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                          };

                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);

                          final success = await transferProvider.createTransfer(payload);

                          if (success) {
                            nav.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Transfer kas & bank berhasil diproses'),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  transferProvider.errorMessage ?? 'Gagal memproses transfer kas',
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          }
                        },
                  label: transferProvider.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Proses Transfer Sekarang',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountChip(String label, double addAmount) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      onPressed: () {
        final current = double.tryParse(_amountCtrl.text) ?? 0;
        setState(() => _amountCtrl.text = (current + addAmount).toInt().toString());
      },
    );
  }
}
