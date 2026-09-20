import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:poslaravelmobile/data/models/report_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

enum ReportPeriod { today, last7Days, thisMonth, thisYear, custom }

class ReportProvider with ChangeNotifier {
  final PosRepository _posRepository = PosRepository();

  // Active period filter
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;
  ReportPeriod get selectedPeriod => _selectedPeriod;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  String get startDateFormatted => DateFormat('yyyy-MM-dd').format(_startDate);
  String get endDateFormatted => DateFormat('yyyy-MM-dd').format(_endDate);
  String get dateRangeLabel {
    final dFormat = DateFormat('dd MMM yyyy');
    if (DateFormat('yyyy-MM-dd').format(_startDate) == DateFormat('yyyy-MM-dd').format(_endDate)) {
      return dFormat.format(_startDate);
    }
    return '${dFormat.format(_startDate)} - ${dFormat.format(_endDate)}';
  }

  int? _selectedWarehouseId;
  int? get selectedWarehouseId => _selectedWarehouseId;

  // Active Main Category Index
  // 0: Penjualan (Harian, Produk, Kategori, Pelanggan)
  // 1: Pembelian & Pengadaan (PO, Supplier)
  // 2: Stok & Inventori (Valuasi, Stok Opname)
  // 3: Laba Rugi & Keuangan (P&L, Arus Kas)
  // 4: Hutang & Piutang (AP & AR)
  // 5: Rekap Shift Kasir
  int _currentCategoryIndex = 0;
  int get currentCategoryIndex => _currentCategoryIndex;

  // Sub-filter under sales
  int _salesSubTabIndex = 0; // 0: Ringkasan & Tren, 1: Produk & Margin, 2: Kategori, 3: Pelanggan
  int get salesSubTabIndex => _salesSubTabIndex;

  // State: Sales Report
  bool _isLoadingSales = false;
  bool get isLoadingSales => _isLoadingSales;
  SalesReportData? _salesData;
  SalesReportData? get salesData => _salesData;

  List<ProductPerformanceModel> _topProducts = [];
  List<ProductPerformanceModel> get topProducts => _topProducts;

  List<CategoryPerformanceModel> _categoryPerformance = [];
  List<CategoryPerformanceModel> get categoryPerformance => _categoryPerformance;

  List<CustomerSalesReportModel> _customerSales = [];
  List<CustomerSalesReportModel> get customerSales => _customerSales;

  // State: Purchases
  bool _isLoadingPurchases = false;
  bool get isLoadingPurchases => _isLoadingPurchases;
  PurchasesReportData? _purchasesData;
  PurchasesReportData? get purchasesData => _purchasesData;

  // State: Stock Valuation & Opnames
  bool _isLoadingValuation = false;
  bool get isLoadingValuation => _isLoadingValuation;
  InventoryValuationData? _valuationData;
  InventoryValuationData? get valuationData => _valuationData;

  List<StockOpnameReportItem> _stockOpnames = [];
  List<StockOpnameReportItem> get stockOpnames => _stockOpnames;

  // State: Profit & Loss & Cash Flows
  bool _isLoadingPL = false;
  bool get isLoadingPL => _isLoadingPL;
  ProfitLossReportData? _profitLossData;
  ProfitLossReportData? get profitLossData => _profitLossData;

  CashFlowReportData? _cashFlowsData;
  CashFlowReportData? get cashFlowsData => _cashFlowsData;

  // State: AP & AR
  bool _isLoadingAPAR = false;
  bool get isLoadingAPAR => _isLoadingAPAR;
  PayableReportData? _payablesData;
  PayableReportData? get payablesData => _payablesData;

  ReceivableReportData? _receivablesData;
  ReceivableReportData? get receivablesData => _receivablesData;

  // State: Shift Kasir
  bool _isLoadingShifts = false;
  bool get isLoadingShifts => _isLoadingShifts;
  CashierShiftReportData? _shiftData;
  CashierShiftReportData? get shiftData => _shiftData;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setCategoryIndex(int index) {
    if (_currentCategoryIndex == index && _shiftData != null && index == 5) return;
    _currentCategoryIndex = index;
    notifyListeners();
    refreshCurrentCategory();
  }

  void setSalesSubTabIndex(int subIndex) {
    _salesSubTabIndex = subIndex;
    notifyListeners();
  }

  void setWarehouse(int? warehouseId) {
    _selectedWarehouseId = warehouseId;
    notifyListeners();
    refreshCurrentCategory();
  }

  void setPeriod(ReportPeriod period, {DateTime? customStart, DateTime? customEnd}) {
    _selectedPeriod = period;
    final now = DateTime.now();

    switch (period) {
      case ReportPeriod.today:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.last7Days:
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
        break;
      case ReportPeriod.thisMonth:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case ReportPeriod.thisYear:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case ReportPeriod.custom:
        if (customStart != null) _startDate = customStart;
        if (customEnd != null) _endDate = customEnd;
        break;
    }

    notifyListeners();
    refreshCurrentCategory();
  }

  Future<void> refreshCurrentCategory() async {
    switch (_currentCategoryIndex) {
      case 0:
        await fetchSalesReport();
        break;
      case 1:
        await fetchPurchasesReport();
        break;
      case 2:
        await Future.wait([
          fetchInventoryValuation(),
          fetchStockOpnames(),
        ]);
        break;
      case 3:
        await Future.wait([
          fetchProfitLossReport(),
          fetchCashFlowsReport(),
        ]);
        break;
      case 4:
        await Future.wait([
          fetchPayablesReport(),
          fetchReceivablesReport(),
        ]);
        break;
      case 5:
        await fetchCashierShifts();
        break;
    }
  }

  Future<void> fetchSalesReport() async {
    _isLoadingSales = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _posRepository.getSalesReportSummary(
          startDate: startDateFormatted,
          endDate: endDateFormatted,
          warehouseId: _selectedWarehouseId,
        ),
        _posRepository.getSalesByProductReport(
          startDate: startDateFormatted,
          endDate: endDateFormatted,
          warehouseId: _selectedWarehouseId,
        ),
        _posRepository.getSalesByCategoryReport(
          startDate: startDateFormatted,
          endDate: endDateFormatted,
          warehouseId: _selectedWarehouseId,
        ),
        _posRepository.getSalesByCustomerReport(
          startDate: startDateFormatted,
          endDate: endDateFormatted,
        ),
      ]);

      _salesData = results[0] as SalesReportData?;
      _topProducts = results[1] as List<ProductPerformanceModel>;
      _categoryPerformance = results[2] as List<CategoryPerformanceModel>;
      _customerSales = results[3] as List<CustomerSalesReportModel>;
    } catch (e) {
      _errorMessage = 'Gagal memuat laporan penjualan: $e';
    } finally {
      _isLoadingSales = false;
      notifyListeners();
    }
  }

  Future<void> fetchPurchasesReport() async {
    _isLoadingPurchases = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _purchasesData = await _posRepository.getPurchasesReport(
        startDate: startDateFormatted,
        endDate: endDateFormatted,
        warehouseId: _selectedWarehouseId,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat laporan pembelian: $e';
    } finally {
      _isLoadingPurchases = false;
      notifyListeners();
    }
  }

  Future<void> fetchInventoryValuation() async {
    _isLoadingValuation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _valuationData = await _posRepository.getInventoryValuationReport(
        warehouseId: _selectedWarehouseId,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat valuasi stok: $e';
    } finally {
      _isLoadingValuation = false;
      notifyListeners();
    }
  }

  Future<void> fetchStockOpnames() async {
    try {
      _stockOpnames = await _posRepository.getStockOpnamesReport(
        startDate: startDateFormatted,
        endDate: endDateFormatted,
        warehouseId: _selectedWarehouseId,
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchProfitLossReport() async {
    _isLoadingPL = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profitLossData = await _posRepository.getProfitLossReport(
        startDate: startDateFormatted,
        endDate: endDateFormatted,
        warehouseId: _selectedWarehouseId,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat laba rugi: $e';
    } finally {
      _isLoadingPL = false;
      notifyListeners();
    }
  }

  Future<void> fetchCashFlowsReport() async {
    try {
      _cashFlowsData = await _posRepository.getCashFlowsReport(
        startDate: startDateFormatted,
        endDate: endDateFormatted,
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchPayablesReport() async {
    _isLoadingAPAR = true;
    notifyListeners();
    try {
      _payablesData = await _posRepository.getPayablesReport();
    } catch (_) {}
    _isLoadingAPAR = false;
    notifyListeners();
  }

  Future<void> fetchReceivablesReport() async {
    try {
      _receivablesData = await _posRepository.getReceivablesReport();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchCashierShifts() async {
    _isLoadingShifts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shiftData = await _posRepository.getCashierShiftsReport(
        startDate: startDateFormatted,
        endDate: endDateFormatted,
        warehouseId: _selectedWarehouseId,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat shift kasir: $e';
    } finally {
      _isLoadingShifts = false;
      notifyListeners();
    }
  }
}
