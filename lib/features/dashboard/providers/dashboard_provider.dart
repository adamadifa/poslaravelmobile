import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poslaravelmobile/data/models/sale_model.dart';
import 'package:poslaravelmobile/data/repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  Map<String, dynamic>? _summary;
  List<dynamic> _recentSales = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Comprehensive Sales History
  SalesHistoryResultModel? _salesHistory;
  bool _isLoadingSales = false;
  String _salesPaymentMethod = 'all';
  String _salesPaymentStatus = 'all';
  int? _salesWarehouseId;
  DateTime? _salesStartDate;
  DateTime? _salesEndDate;
  String _salesSearch = '';

  Map<String, dynamic>? get summary => _summary;
  List<dynamic> get recentSales => _recentSales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SalesHistoryResultModel? get salesHistory => _salesHistory;
  bool get isLoadingSales => _isLoadingSales;
  String get salesPaymentMethod => _salesPaymentMethod;
  String get salesPaymentStatus => _salesPaymentStatus;
  int? get salesWarehouseId => _salesWarehouseId;
  DateTime? get salesStartDate => _salesStartDate;
  DateTime? get salesEndDate => _salesEndDate;
  String get salesSearch => _salesSearch;

  double get todaySales => double.tryParse((_summary?['today']?['total_sales'] ?? 0).toString()) ?? 0.0;
  int get todayTransactions => int.tryParse((_summary?['today']?['total_transactions'] ?? 0).toString()) ?? 0;
  double get todayCashSales => double.tryParse((_summary?['today']?['total_cash_sales'] ?? 0).toString()) ?? 0.0;
  double get todayNonCashSales => double.tryParse((_summary?['today']?['total_non_cash_sales'] ?? 0).toString()) ?? 0.0;
  double get averageTransaction => double.tryParse((_summary?['today']?['average_transaction'] ?? 0).toString()) ?? 0.0;
  String get todayDate => _summary?['today']?['date']?.toString() ?? '';

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getSummary();
      _summary = res;
      _recentSales = (res['recent_sales'] is List) ? res['recent_sales'] as List : [];
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSalesPaymentMethod(String method) {
    if (_salesPaymentMethod != method) {
      _salesPaymentMethod = method;
      notifyListeners();
      fetchSalesHistory();
    }
  }

  void setSalesPaymentStatus(String status) {
    if (_salesPaymentStatus != status) {
      _salesPaymentStatus = status;
      notifyListeners();
      fetchSalesHistory();
    }
  }

  void setSalesWarehouse(int? warehouseId) {
    if (_salesWarehouseId != warehouseId) {
      _salesWarehouseId = warehouseId;
      notifyListeners();
      fetchSalesHistory();
    }
  }

  void setSalesDateRange(DateTime? start, DateTime? end) {
    _salesStartDate = start;
    _salesEndDate = end;
    notifyListeners();
    fetchSalesHistory();
  }

  void setSalesSearch(String search) {
    _salesSearch = search;
    notifyListeners();
    fetchSalesHistory();
  }

  void resetSalesFilters() {
    _salesPaymentMethod = 'all';
    _salesPaymentStatus = 'all';
    _salesWarehouseId = null;
    _salesStartDate = null;
    _salesEndDate = null;
    _salesSearch = '';
    notifyListeners();
    fetchSalesHistory();
  }

  Future<void> fetchSalesHistory() async {
    _isLoadingSales = true;
    notifyListeners();

    try {
      final startStr = _salesStartDate != null ? DateFormat('yyyy-MM-dd').format(_salesStartDate!) : null;
      final endStr = _salesEndDate != null ? DateFormat('yyyy-MM-dd').format(_salesEndDate!) : null;

      _salesHistory = await _repository.getSalesHistory(
        warehouseId: _salesWarehouseId,
        paymentMethod: _salesPaymentMethod,
        paymentStatus: _salesPaymentStatus,
        startDate: startStr,
        endDate: endStr,
        search: _salesSearch.trim().isNotEmpty ? _salesSearch.trim() : null,
      );
    } catch (_) {
    } finally {
      _isLoadingSales = false;
      notifyListeners();
    }
  }

  Future<void> fetchSales({String? search}) async {
    try {
      _recentSales = await _repository.getSales(search: search);
      notifyListeners();
    } catch (_) {}
  }
}
