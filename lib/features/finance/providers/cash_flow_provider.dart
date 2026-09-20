import 'package:flutter/material.dart';
import 'package:poslaravelmobile/data/models/cash_flow_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class CashFlowProvider extends ChangeNotifier {
  final PosRepository _repository = PosRepository();

  CashFlowResponseData? _responseData;
  List<CashFlowModel> _cashFlows = [];
  CashFlowSummary _summary = CashFlowSummary(totalIncome: 0, totalExpense: 0, netFlow: 0);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Filter States
  String _selectedType = 'all'; // all, income, expense
  int? _selectedAccountId;
  String? _selectedCategory;
  String _searchQuery = '';
  String? _startDate;
  String? _endDate;
  int _currentPage = 1;

  // Categories suggestions
  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];

  // Getters
  CashFlowResponseData? get responseData => _responseData;
  List<CashFlowModel> get cashFlows => _cashFlows;
  CashFlowSummary get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  String get selectedType => _selectedType;
  int? get selectedAccountId => _selectedAccountId;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  int get currentPage => _currentPage;

  List<String> get incomeCategories => _incomeCategories;
  List<String> get expenseCategories => _expenseCategories;

  Future<void> fetchCategories() async {
    try {
      final res = await _repository.getCashFlowCategories();
      _incomeCategories = res['income'] ?? [];
      _expenseCategories = res['expense'] ?? [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchCashFlows({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getCashFlows(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        type: _selectedType,
        accountId: _selectedAccountId,
        category: _selectedCategory,
        startDate: _startDate,
        endDate: _endDate,
        page: _currentPage,
      );

      if (res != null) {
        _responseData = res;
        _cashFlows = res.cashFlows;
        _summary = res.summary;
      } else {
        _cashFlows = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTypeFilter(String type) {
    if (_selectedType == type) return;
    _selectedType = type;
    fetchCashFlows(refresh: true);
  }

  void setAccountFilter(int? accountId) {
    _selectedAccountId = accountId;
    fetchCashFlows(refresh: true);
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    fetchCashFlows(refresh: true);
  }

  void setDateRange(String? start, String? end) {
    _startDate = start;
    _endDate = end;
    fetchCashFlows(refresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchCashFlows(refresh: true);
  }

  void resetFilters() {
    _selectedType = 'all';
    _selectedAccountId = null;
    _selectedCategory = null;
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    fetchCashFlows(refresh: true);
  }

  Future<bool> createCashFlow(Map<String, dynamic> payload) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.storeCashFlow(payload);
      if (created != null) {
        await fetchCashFlows(refresh: true);
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCashFlow(int id, Map<String, dynamic> payload) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateCashFlow(id, payload);
      if (updated != null) {
        await fetchCashFlows(refresh: true);
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCashFlow(int id) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.deleteCashFlow(id);
      if (success) {
        await fetchCashFlows(refresh: true);
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
