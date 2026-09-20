import 'package:flutter/material.dart';
import 'package:poslaravelmobile/data/models/shift_model.dart';
import 'package:poslaravelmobile/data/repositories/shift_repository.dart';

class ShiftProvider extends ChangeNotifier {
  final ShiftRepository _shiftRepository = ShiftRepository();

  ShiftModel? _currentShift;
  bool _isLoading = false;
  String? _errorMessage;

  ShiftModel? get currentShift => _currentShift;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveShift => _currentShift != null && _currentShift!.isOpen;

  Future<void> fetchCurrentShift() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentShift = await _shiftRepository.getCurrentShift();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> openShift({
    required int warehouseId,
    required double startingCash,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentShift = await _shiftRepository.openShift(
        warehouseId: warehouseId,
        startingCash: startingCash,
        notes: notes,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeShift({
    required double actualCash,
    String? notes,
  }) async {
    if (_currentShift == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _shiftRepository.closeShift(
        shiftId: _currentShift!.id,
        actualCash: actualCash,
        notes: notes,
      );
      _currentShift = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addExpense({
    required double amount,
    required String category,
    String? notes,
  }) async {
    if (_currentShift == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentShift = await _shiftRepository.addExpense(
        shiftId: _currentShift!.id,
        amount: amount,
        category: category,
        notes: notes,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int expenseId) async {
    if (_currentShift == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentShift = await _shiftRepository.deleteExpense(
        shiftId: _currentShift!.id,
        expenseId: expenseId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
