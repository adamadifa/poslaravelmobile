import 'package:flutter/material.dart';
import 'package:poslaravelmobile/data/models/account_transfer_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class AccountTransferProvider extends ChangeNotifier {
  final PosRepository _repository = PosRepository();

  AccountTransferResponseData? _responseData;
  List<AccountTransferModel> _transfers = [];
  AccountTransferSummary _summary = AccountTransferSummary(totalTransferred: 0, totalFee: 0);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Filter States
  int? _fromAccountId;
  int? _toAccountId;
  String _searchQuery = '';
  String? _startDate;
  String? _endDate;
  int _currentPage = 1;

  // Getters
  AccountTransferResponseData? get responseData => _responseData;
  List<AccountTransferModel> get transfers => _transfers;
  AccountTransferSummary get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  int? get fromAccountId => _fromAccountId;
  int? get toAccountId => _toAccountId;
  String get searchQuery => _searchQuery;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  int get currentPage => _currentPage;

  Future<void> fetchTransfers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getAccountTransfers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        fromAccountId: _fromAccountId,
        toAccountId: _toAccountId,
        startDate: _startDate,
        endDate: _endDate,
        page: _currentPage,
      );

      if (res != null) {
        _responseData = res;
        _transfers = res.transfers;
        _summary = res.summary;
      } else {
        _transfers = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFromAccount(int? id) {
    _fromAccountId = id;
    fetchTransfers(refresh: true);
  }

  void setToAccount(int? id) {
    _toAccountId = id;
    fetchTransfers(refresh: true);
  }

  void setDateRange(String? start, String? end) {
    _startDate = start;
    _endDate = end;
    fetchTransfers(refresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchTransfers(refresh: true);
  }

  void resetFilters() {
    _fromAccountId = null;
    _toAccountId = null;
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    fetchTransfers(refresh: true);
  }

  Future<bool> createTransfer(Map<String, dynamic> payload) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.storeAccountTransfer(payload);
      if (created != null) {
        await fetchTransfers(refresh: true);
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
