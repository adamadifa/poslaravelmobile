import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/payment_model.dart';
import 'package:poslaravelmobile/data/models/sale_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/pos/providers/pos_provider.dart';

class CustomerReceivablesScreen extends StatefulWidget {
  const CustomerReceivablesScreen({super.key});

  @override
  State<CustomerReceivablesScreen> createState() => _CustomerReceivablesScreenState();
}

class _CustomerReceivablesScreenState extends State<CustomerReceivablesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatus = 'active'; // active, unpaid, partial, paid, all
  int? _selectedCustomerId;

  final List<Map<String, String>> _statusFilters = [
    {'key': 'active', 'label': 'Piutang Aktif'},
    {'key': 'unpaid', 'label': 'Belum Dibayar'},
    {'key': 'partial', 'label': 'Cicil (Parsial)'},
    {'key': 'paid', 'label': 'Lunas'},
    {'key': 'all', 'label': 'Semua Tagihan'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      context.read<MasterDataProvider>().fetchCustomers();
      context.read<MasterDataProvider>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    String? apiStatus = _selectedStatus;
    if (_selectedStatus == 'active') {
      apiStatus = null; // Backend returns unpaid & partial by default when null
    }

    context.read<PosProvider>().fetchReceivables(
          paymentStatus: apiStatus,
          customerId: _selectedCustomerId,
          search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
        );
  }

  Future<void> _showReceiveModal(SaleModel item) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ReceiveDebtModal(sale: item);
      },
    );

    if (result == true || mounted) {
      _loadData();
      if (mounted) {
        context.read<MasterDataProvider>().fetchAccounts();
      }
    }
  }

  Future<void> _showHistoryModal(SaleModel item) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ReceiveHistoryModal(sale: item);
      },
    );

    if (result == true || mounted) {
      _loadData();
      if (mounted) {
        context.read<MasterDataProvider>().fetchAccounts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PosProvider>();
    final customers = context.watch<MasterDataProvider>().customers;

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
              'Piutang Penjualan (AR)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
            ),
            Text(
              'Penerimaan tagihan pelanggan & histori kas',
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // TOP FINANCIAL SUMMARY HERO CARD
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  children: [
                    // Main Highlight Card: Total Sisa Piutang
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33059669),
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
                                  'TOTAL SISA PIUTANG USAHA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(provider.totalReceivablesOutstanding),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Total tagihan invoice pelanggan yang belum lunas',
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
                              child: Icon(LucideIcons.coins, color: Colors.white, size: 26),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SEARCH & FILTER BAR
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: [
                    // Search Input
                    Container(
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
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: (_) => _loadData(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Cari No. Invoice / Nama Pelanggan...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
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

                    // Customer Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedCustomerId,
                          isExpanded: true,
                          hint: const Text('Semua Pelanggan', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Semua Pelanggan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            ...customers.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedCustomerId = val);
                            _loadData();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status Pill Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusFilters.map((sf) {
                          final isSelected = _selectedStatus == sf['key'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedStatus = sf['key']!);
                                _loadData();
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF059669) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  sf['label']!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LIST OF RECEIVABLES
            if (provider.isLoadingReceivables)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (provider.receivables.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(LucideIcons.checkCircle2, size: 48, color: Color(0xFF059669)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak Ada Piutang Usaha',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Semua tagihan piutang invoice pelanggan telah lunas terbayar.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = provider.receivables[index];
                      return _buildReceivableCard(item);
                    },
                    childCount: provider.receivables.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivableCard(SaleModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header: Invoice Number, Status Badge, Customer Name
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.coins, color: Color(0xFF059669), size: 20),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.invoiceNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: item.paymentStatusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.paymentStatusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: item.paymentStatusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(LucideIcons.user, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.customerName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          // Remaining Debt & Total Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SISA PIUTANG',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(item.remainingReceivable),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFDC2626),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL INVOICE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(item.grandTotal),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dates & Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.paymentDueDate != null
                              ? 'Jatuh Tempo: ${AppDateFormatter.format(item.paymentDueDate)}'
                              : 'Tgl: ${AppDateFormatter.format(item.saleDate ?? item.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (item.paidAmount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () => _showHistoryModal(item),
                          icon: const Icon(LucideIcons.history, color: Color(0xFF475569), size: 13),
                          label: const Text(
                            'Riwayat',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ),
                      ),
                    if (item.remainingReceivable > 0)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 0,
                        ),
                        onPressed: () => _showReceiveModal(item),
                        icon: const Icon(LucideIcons.coins, color: Colors.white, size: 13),
                        label: const Text(
                          'Terima Piutang',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
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
  }
}

class _ReceiveDebtModal extends StatefulWidget {
  final SaleModel sale;

  const _ReceiveDebtModal({required this.sale});

  @override
  State<_ReceiveDebtModal> createState() => _ReceiveDebtModalState();
}

class _ReceiveDebtModalState extends State<_ReceiveDebtModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _refCtrl;
  late TextEditingController _notesCtrl;

  int? _selectedAccountId;
  String _paymentMethod = 'cash';
  final DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.sale.remainingReceivable.toInt().toString(),
    );
    _refCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    final accounts = context.read<MasterDataProvider>().accounts;
    if (accounts.isNotEmpty) {
      final defaultAcc = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
      _selectedAccountId = defaultAcc.id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _parseNumber(String text) {
    if (text.isEmpty) return 0;
    final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseNumber(_amountCtrl.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal penerimaan harus lebih dari 0.')),
      );
      return;
    }

    if (amount > widget.sale.remainingReceivable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nominal melebihi sisa piutang (${CurrencyFormatter.format(widget.sale.remainingReceivable)}).'),
        ),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun kas/bank penampung.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'sale_id': widget.sale.id,
      'account_id': _selectedAccountId,
      'amount': amount,
      'payment_date': DateFormat('yyyy-MM-dd').format(_paymentDate),
      'payment_method': _paymentMethod,
      'reference_number': _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null,
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    };

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await context.read<PosProvider>().collectReceivable(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Penerimaan piutang untuk invoice ${widget.sale.invoiceNumber} berhasil dicatat.'),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop(true);
    } else {
      final err = context.read<PosProvider>().errorMessage ?? 'Gagal memproses penerimaan piutang.';
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<MasterDataProvider>().accounts;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Penerimaan Piutang Pelanggan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${widget.sale.invoiceNumber} • ${widget.sale.customerName}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
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
              const Divider(height: 20),

              // Sisa Piutang banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sisa Piutang Saat Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                        Text('Invoice Tempo', style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(widget.sale.remainingReceivable),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Akun Kas / Bank Penampung
              const Text('Akun Kas / Bank Penerima', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    hint: const Text('Pilih Akun Kas / Bank', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                    icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                    items: accounts.map((acc) {
                      return DropdownMenuItem<int>(
                        value: acc.id,
                        child: Text(
                          '${acc.name} (${CurrencyFormatter.format(acc.currentBalance)})',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Metode Pembayaran
              const Text('Metode Pembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentMethod,
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Tunai / Kas (Cash)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      DropdownMenuItem(value: 'transfer', child: Text('Transfer Bank', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      DropdownMenuItem(value: 'check', child: Text('Cek / Giro', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      DropdownMenuItem(value: 'other', child: Text('Lainnya', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMethod = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nominal Penerimaan
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                decoration: InputDecoration(
                  labelText: 'Nominal Diterima (Rp) *',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: '0',
                  prefixIcon: const Icon(LucideIcons.coins, size: 18, color: Color(0xFF059669)),
                  suffixIcon: TextButton(
                    onPressed: () {
                      _amountCtrl.text = widget.sale.remainingReceivable.toInt().toString();
                    },
                    child: const Text('Lunaskan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nominal wajib diisi.';
                  final n = _parseNumber(v);
                  if (n <= 0) return 'Nominal harus lebih dari 0.';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Nomor Referensi / Bukti Transfer
              TextFormField(
                controller: _refCtrl,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'No. Referensi / Bukti Transfer (Opsional)',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'Contoh: TRF-20260901-001',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(LucideIcons.hash, size: 16, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              // Catatan / Notes
              TextFormField(
                controller: _notesCtrl,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Catatan Penerimaan (Opsional)',
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'Keterangan pelunasan / cicilan piutang...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(LucideIcons.fileText, size: 16, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitPayment,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Konfirmasi Penerimaan Piutang',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiveHistoryModal extends StatefulWidget {
  final SaleModel sale;

  const _ReceiveHistoryModal({required this.sale});

  @override
  State<_ReceiveHistoryModal> createState() => _ReceiveHistoryModalState();
}

class _ReceiveHistoryModalState extends State<_ReceiveHistoryModal> {
  bool _isLoading = true;
  List<PaymentModel> _payments = [];
  int? _deletingPaymentId;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    final provider = context.read<PosProvider>();
    final list = await provider.getReceivablePayments(widget.sale.id);
    if (mounted) {
      setState(() {
        _payments = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(PaymentModel payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Batalkan Penerimaan?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan penerimaan pembayaran ${payment.paymentNumber} sebesar ${CurrencyFormatter.format(payment.amount)}?\n\nSaldo akun akan ditarik kembali dan sisa piutang invoice akan bertambah kembali.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deletingPaymentId = payment.id);
    final provider = context.read<PosProvider>();
    final success = await provider.cancelReceivablePayment(payment.id);

    if (mounted) {
      setState(() => _deletingPaymentId = null);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('Penerimaan pembayaran ${payment.paymentNumber} berhasil dibatalkan.'),
          ),
        );
        _loadPayments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(provider.errorMessage ?? 'Gagal membatalkan penerimaan.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riwayat Penerimaan Piutang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invoice: ${widget.sale.invoiceNumber} (${widget.sale.customerName})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Color(0xFF64748B), size: 20),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Payment List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_payments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(LucideIcons.fileX, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum ada riwayat penerimaan untuk invoice ini.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: _payments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final p = _payments[idx];
                  final isDeletingThis = _deletingPaymentId == p.id;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.checkCircle, color: Color(0xFF059669), size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      p.paymentNumber,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.paymentMethod.toUpperCase(),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Akun: ${p.accountName}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                              if (p.notes != null && p.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '"${p.notes}"',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Tgl: ${AppDateFormatter.format(p.paymentDate)}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(p.amount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            isDeletingThis
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                                  )
                                : Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _confirmDelete(p);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.trash2, size: 13, color: Color(0xFFDC2626)),
                                            SizedBox(width: 4),
                                            Text(
                                              'Batal',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFDC2626),
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
