import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:poslaravelmobile/core/theme/app_colors.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/data/models/sale_model.dart';
import 'package:poslaravelmobile/features/master_data/providers/master_data_provider.dart';
import 'package:poslaravelmobile/features/sales_returns/providers/sale_return_provider.dart';

class CreateSaleReturnScreen extends StatefulWidget {
  const CreateSaleReturnScreen({super.key});

  @override
  State<CreateSaleReturnScreen> createState() => _CreateSaleReturnScreenState();
}

class _CreateSaleReturnScreenState extends State<CreateSaleReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _invoiceSearchCtrl = TextEditingController();

  DateTime _returnDate = DateTime.now();
  String _refundMethod = 'cash'; // 'cash', 'credit_deduction', 'exchange'
  int? _selectedAccountId;
  SaleModel? _selectedSale;

  // Map of sale_item_id -> quantity to return
  final Map<int, double> _returnQuantities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final master = context.read<MasterDataProvider>();
      master.fetchAccounts();
      master.fetchProducts();

      final retProv = context.read<SaleReturnProvider>();
      retProv.fetchInvoices();
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    _invoiceSearchCtrl.dispose();
    super.dispose();
  }

  String _formatQty(num? val) {
    if (val == null) return '0';
    final double d = val.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  double _calculateTotalRefund() {
    if (_selectedSale == null) return 0.0;
    double total = 0.0;
    for (var item in _selectedSale!.items) {
      final qty = _returnQuantities[item.id] ?? 0.0;
      if (qty > 0) {
        total += qty * item.unitPrice;
      }
    }
    return total;
  }

  int _countTotalReturnedItems() {
    if (_selectedSale == null) return 0;
    int count = 0;
    for (var item in _selectedSale!.items) {
      final qty = _returnQuantities[item.id] ?? 0.0;
      if (qty > 0) {
        count++;
      }
    }
    return count;
  }

  void _openInvoicePickerModal() {
    final retProv = context.read<SaleReturnProvider>();
    _invoiceSearchCtrl.clear();
    retProv.fetchInvoices();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(LucideIcons.receipt, size: 20, color: Color(0xFFEA580C)),
                        SizedBox(width: 8),
                        Text(
                          'Pilih Faktur Invoice Penjualan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search invoice box
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _invoiceSearchCtrl,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                        onChanged: (q) {
                          retProv.fetchInvoices(search: q);
                          setModalState(() {});
                        },
                        decoration: const InputDecoration(
                          hintText: 'Cari nomor faktur / nama pelanggan...',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: Consumer<SaleReturnProvider>(
                        builder: (context, prov, _) {
                          final invoices = prov.availableInvoices;
                          final isLoading = prov.isLoadingInvoices;

                          if (isLoading) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }
                          if (invoices.isEmpty) {
                            return const Center(
                              child: Text('Tidak ada transaksi penjualan selesai yang ditemukan.',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
                            );
                          }

                          return ListView.separated(
                            itemCount: invoices.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (c, i) {
                              final inv = invoices[i];
                              final isSelected = _selectedSale?.id == inv.id;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFBFDBFE)),
                                  ),
                                  child: Icon(
                                    isSelected ? LucideIcons.checkCircle : LucideIcons.receipt,
                                    size: 18,
                                    color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF2563EB),
                                  ),
                                ),
                                title: Text(
                                  inv.invoiceNumber,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                ),
                                subtitle: Text(
                                  '${inv.customerName} • ${inv.items.length} Item • ${inv.saleDate ?? inv.createdAt ?? "-"}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                trailing: Text(
                                  CurrencyFormatter.format(inv.grandTotal),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedSale = inv;
                                    _returnQuantities.clear();
                                    for (var item in inv.items) {
                                      _returnQuantities[item.id] = 0.0;
                                    }
                                  });
                                  Navigator.pop(modalCtx);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_selectedSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih faktur invoice penjualan terlebih dahulu.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan retur wajib diisi.'), backgroundColor: Colors.red),
      );
      return;
    }

    final returnItems = <Map<String, dynamic>>[];
    for (var item in _selectedSale!.items) {
      final qty = _returnQuantities[item.id] ?? 0.0;
      if (qty > 0) {
        returnItems.add({
          'product_id': item.productId,
          'unit_id': item.unitId,
          'quantity': qty,
          'unit_price': item.unitPrice,
          'batch_number': null,
        });
      }
    }

    if (returnItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tentukan minimal 1 produk dengan kuantiti retur lebih dari 0.'), backgroundColor: Colors.red),
      );
      return;
    }

    final payload = {
      'sale_id': _selectedSale!.id,
      'return_date': DateFormat('yyyy-MM-dd').format(_returnDate),
      'refund_method': _refundMethod,
      'account_id': _refundMethod == 'cash' ? _selectedAccountId : null,
      'reason': _reasonCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      'items': returnItems,
    };

    final retProv = context.read<SaleReturnProvider>();
    try {
      final res = await retProv.storeSaleReturn(payload);
      if (mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retur penjualan ${res.returnNumber} berhasil diproses dan stok barang dipulihkan.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final retProv = context.watch<SaleReturnProvider>();
    final master = context.watch<MasterDataProvider>();
    final accounts = master.accounts;
    final totalRefund = _calculateTotalRefund();
    final totalItemsCount = _countTotalReturnedItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEA580C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buat Retur Penjualan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            Text('Pengembalian barang pelanggan & pemulihan stok', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, -3))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL REFUND ($totalItemsCount ITEM)',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                    Text(
                      CurrencyFormatter.format(totalRefund),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: retProv.isLoading ? null : _submitForm,
                icon: retProv.isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.checkCircle, size: 18, color: Colors.white),
                label: const Text('Proses Retur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          children: [
            // STEP 1: INVOICE SELECTOR BOX
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _selectedSale != null ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Faktur Invoice Penjualan *',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      InkWell(
                        onTap: _openInvoicePickerModal,
                        child: Text(
                          _selectedSale != null ? 'Ganti Invoice' : 'Cari Invoice',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFEA580C)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_selectedSale == null)
                    InkWell(
                      onTap: _openInvoicePickerModal,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFEDD5), style: BorderStyle.solid),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.search, size: 18, color: Color(0xFFEA580C)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Sentuh untuk cari & pilih faktur invoice penjualan...',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(LucideIcons.receipt, size: 20, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedSale!.invoiceNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF14532D))),
                                Text(
                                  '${_selectedSale!.customerName} • ${_selectedSale!.saleDate ?? _selectedSale!.createdAt ?? "-"}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(_selectedSale!.grandTotal),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // STEP 2: RETURN PARAMETERS
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Pengembalian & Refund', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),

                  // Return Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _returnDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _returnDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tanggal Retur: ${DateFormat('dd MMMM yyyy').format(_returnDate)}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Refund Method Options
                  const Text('Metode Refund *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMethodOption('Pengembalian Tunai', 'cash'),
                      const SizedBox(width: 8),
                      _buildMethodOption('Potong Piutang', 'credit_deduction'),
                      const SizedBox(width: 8),
                      _buildMethodOption('Tukar Barang', 'exchange'),
                    ],
                  ),

                  if (_refundMethod == 'cash') ...[
                    const SizedBox(height: 12),
                    const Text('Potong dari Kas / Bank *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: accounts.any((a) => a.id == _selectedAccountId)
                          ? _selectedAccountId
                          : (accounts.isNotEmpty ? accounts.first.id : null),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      hint: const Text('Pilih Akun Kas / Bank', style: TextStyle(fontSize: 12)),
                      items: accounts.map((a) => DropdownMenuItem<int?>(
                            value: a.id,
                            child: Text('${a.name} (${CurrencyFormatter.format(a.currentBalance)})',
                                style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                          )).toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Reason input
                  const Text('Alasan Retur *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _reasonCtrl,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Kemasan rusak, produk cacat, salah varian...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Notes input
                  const Text('Catatan Tambahan (Opsional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Tambahkan keterangan bila diperlukan...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // STEP 3: RETURN ITEMS TABLE
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tentukan Kuantiti Barang Diretur', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      Text('Qty 0 = Tidak Diretur', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_selectedSale == null || _selectedSale!.items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(LucideIcons.packageX, size: 32, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 8),
                          Text('Pilih faktur invoice terlebih dahulu untuk menampilkan daftar barang belanjaan.',
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedSale!.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      itemBuilder: (c, i) {
                        final item = _selectedSale!.items[i];
                        final returnQty = _returnQuantities[item.id] ?? 0.0;
                        final lineRefund = returnQty * item.unitPrice;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                  ),
                                  Text(
                                    'Beli: ${_formatQty(item.quantity)} ${item.unitName} @ ${CurrencyFormatter.format(item.unitPrice)}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  if (returnQty > 0)
                                    Text(
                                      'Refund: ${CurrencyFormatter.format(lineRefund)}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Stepper Qty Retur
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (returnQty > 0) {
                                        setState(() {
                                          _returnQuantities[item.id] = (returnQty - 1).clamp(0.0, item.quantity);
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Icon(LucideIcons.minus, size: 14, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 32),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _formatQty(returnQty),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: returnQty > 0 ? const Color(0xFFEA580C) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      if (returnQty < item.quantity) {
                                        setState(() {
                                          _returnQuantities[item.id] = (returnQty + 1).clamp(0.0, item.quantity);
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Icon(LucideIcons.plus, size: 14, color: Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
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

  Widget _buildMethodOption(String label, String value) {
    final isSelected = _refundMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _refundMethod = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
