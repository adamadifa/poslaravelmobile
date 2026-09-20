import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';
import 'package:poslaravelmobile/data/models/account_mutation_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';

class AccountMutationsScreen extends StatefulWidget {
  final AccountModel account;

  const AccountMutationsScreen({super.key, required this.account});

  @override
  State<AccountMutationsScreen> createState() => _AccountMutationsScreenState();
}

class _AccountMutationsScreenState extends State<AccountMutationsScreen> {
  String _selectedType = 'all'; // all, credit, debit
  DateTime? _startDate;
  DateTime? _endDate;

  final List<Map<String, String>> _types = [
    {'key': 'all', 'label': 'Semua Mutasi'},
    {'key': 'credit', 'label': 'Kas Masuk (+)'},
    {'key': 'debit', 'label': 'Kas Keluar (-)'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMutations();
    });
  }

  void _loadMutations() {
    final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
    final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    context.read<MasterDataProvider>().fetchAccountMutations(
          widget.account.id,
          type: _selectedType,
          startDate: startStr,
          endDate: endStr,
        );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadMutations();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadMutations();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MasterDataProvider>();
    final mutations = provider.accountMutations;
    final summary = provider.mutationsSummary;

    final double totalCredit = double.tryParse((summary['total_credit'] ?? 0).toString()) ?? 0;
    final double totalDebit = double.tryParse((summary['total_debit'] ?? 0).toString()) ?? 0;
    final double currentBal = double.tryParse((summary['current_balance'] ?? widget.account.currentBalance).toString()) ?? widget.account.currentBalance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buku Mutasi: ${widget.account.name}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.account.accountCode} • ${widget.account.typeLabel}',
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
            onPressed: _loadMutations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadMutations(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ACCOUNT HEADER & SUMMARY
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    // Main Balance Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Saldo Saat Ini',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFFEDD5)),
                                ),
                                child: Text(
                                  widget.account.accountCode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFEA580C),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.format(currentBal),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (widget.account.bankName != null || widget.account.accountNumber != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              [
                                if (widget.account.bankName != null) widget.account.bankName,
                                if (widget.account.accountNumber != null) widget.account.accountNumber,
                                if (widget.account.accountHolder != null) 'a/n ${widget.account.accountHolder}',
                              ].join(' • '),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filtered Period Inflow vs Outflow
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(LucideIcons.arrowDownLeft, size: 14, color: Color(0xFF059669)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Total Masuk (+)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  CurrencyFormatter.format(totalCredit),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(LucideIcons.arrowUpRight, size: 14, color: Color(0xFFDC2626)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Total Keluar (-)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  CurrencyFormatter.format(totalDebit),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // FILTER CONTROLS (DATE PICKER & TYPE CHIPS)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Date Filter Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                  : 'Semua Periode Tanggal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _startDate != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          if (_startDate != null)
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _clearDateFilter,
                            )
                          else
                            InkWell(
                              onTap: _selectDateRange,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Text(
                                  'Pilih Tanggal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Type filter chips
                    Row(
                      children: _types.map((t) {
                        final isSelected = _selectedType == t['key'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                              t['label']!,
                              style: TextStyle(
                                fontSize: 11,
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
                              _loadMutations();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // MUTATIONS LIST
            if (provider.isLoadingMutations)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (mutations.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.fileX, size: 36, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak Ada Mutasi Rekening',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Belum ada riwayat transaksi kas pada filter yang dipilih',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                      final item = mutations[index];
                      return _buildMutationCard(item);
                    },
                    childCount: mutations.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutationCard(AccountMutationModel item) {
    final isCredit = item.isCredit;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
          // Row 1: Type icon, Description, Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                    color: isCredit ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Description & Reference
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description != null && item.description!.isNotEmpty
                          ? item.description!
                          : (isCredit ? 'Kas Masuk' : 'Kas Keluar'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.referenceType != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.referenceType!.split('\\').last,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (item.createdAt != null)
                          Text(
                            AppDateFormatter.formatDateTime(item.createdAt!),
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '${isCredit ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isCredit ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          const SizedBox(height: 8),

          // Row 2: Balance Before -> Balance After, User
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo: ${CurrencyFormatter.format(item.balanceBefore)} → ${CurrencyFormatter.format(item.balanceAfter)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              if (item.userName != null)
                Text(
                  item.userName!,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
