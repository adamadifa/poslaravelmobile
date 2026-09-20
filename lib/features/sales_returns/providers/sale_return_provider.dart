import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poslaravelmobile/data/models/sale_model.dart';
import 'package:poslaravelmobile/data/models/sale_return_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class SaleReturnProvider extends ChangeNotifier {
  final PosRepository _repository = PosRepository();

  bool _isLoading = false;
  String? _errorMessage;

  SaleReturnsResultModel? _returnsResult;
  SaleReturnModel? _selectedReturn;
  bool _isLoadingDetail = false;

  // Invoice selection for creating return
  List<SaleModel> _availableInvoices = [];
  bool _isLoadingInvoices = false;
  SaleModel? _selectedInvoice;

  // Filters (matching web exactly)
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'completed', 'cancelled'
  int? _warehouseFilter;
  String _refundMethodFilter = 'all'; // 'all', 'cash', 'credit_deduction', 'exchange'
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SaleReturnsResultModel? get returnsResult => _returnsResult;
  List<SaleReturnModel> get returns => _returnsResult?.returns ?? [];
  SaleReturnSummaryModel? get summary => _returnsResult?.summary;

  SaleReturnModel? get selectedReturn => _selectedReturn;
  bool get isLoadingDetail => _isLoadingDetail;

  List<SaleModel> get availableInvoices => _availableInvoices;
  bool get isLoadingInvoices => _isLoadingInvoices;
  SaleModel? get selectedInvoice => _selectedInvoice;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  int? get warehouseFilter => _warehouseFilter;
  String get refundMethodFilter => _refundMethodFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Filter setters
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
    fetchReturns();
  }

  void setStatus(String status) {
    if (_statusFilter != status) {
      _statusFilter = status;
      notifyListeners();
      fetchReturns();
    }
  }

  void setWarehouse(int? warehouseId) {
    if (_warehouseFilter != warehouseId) {
      _warehouseFilter = warehouseId;
      notifyListeners();
      fetchReturns();
    }
  }

  void setRefundMethod(String method) {
    if (_refundMethodFilter != method) {
      _refundMethodFilter = method;
      notifyListeners();
      fetchReturns();
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
    fetchReturns();
  }

  void resetFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _warehouseFilter = null;
    _refundMethodFilter = 'all';
    _startDate = null;
    _endDate = null;
    notifyListeners();
    fetchReturns();
  }

  void setSelectedInvoice(SaleModel? sale) {
    _selectedInvoice = sale;
    notifyListeners();
  }

  // Fetch Returns List
  Future<void> fetchReturns() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      _returnsResult = await _repository.getSaleReturns(
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
        status: _statusFilter,
        warehouseId: _warehouseFilter,
        refundMethod: _refundMethodFilter,
        startDate: startStr,
        endDate: endStr,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Invoices for Picker
  Future<void> fetchInvoices({String? search}) async {
    _isLoadingInvoices = true;
    notifyListeners();

    try {
      _availableInvoices = await _repository.getSaleReturnInvoices(search: search);
    } catch (_) {
      _availableInvoices = [];
    } finally {
      _isLoadingInvoices = false;
      notifyListeners();
    }
  }

  // Fetch Return Detail
  Future<void> fetchReturnDetail(int id) async {
    _isLoadingDetail = true;
    _selectedReturn = null;
    notifyListeners();

    try {
      _selectedReturn = await _repository.getSaleReturnDetail(id);
    } catch (_) {
      _selectedReturn = null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // Create Sale Return
  Future<SaleReturnModel?> storeSaleReturn(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.storeSaleReturn(data);
      await fetchReturns();
      return res;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel / Delete Sale Return
  Future<bool> deleteSaleReturn(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteSaleReturn(id);
      if (ok) {
        await fetchReturns();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
