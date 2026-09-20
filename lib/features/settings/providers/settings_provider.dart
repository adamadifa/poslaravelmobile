import 'package:flutter/foundation.dart';
import 'package:poslaravelmobile/data/models/store_settings_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final PosRepository _repository = PosRepository();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  StoreSettingsModel? _settings;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  StoreSettingsModel? get settings => _settings;

  // Shortcut accessors
  StoreProfileModel? get profile => _settings?.profile;
  BusinessTypeSettingsModel? get businessType => _settings?.businessType;
  PrefixesSettingsModel? get prefixes => _settings?.prefixes;
  TaxCurrencySettingsModel? get taxCurrency => _settings?.taxCurrency;
  ReceiptTemplateSettingsModel? get receipt => _settings?.receipt;
  AgentSettingsModel? get agent => _settings?.agent;

  Future<void> fetchSettings({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _settings = await _repository.getStoreSettings();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.updateProfileSettings(data);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveBusinessType(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.updateBusinessTypeSettings(data);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> savePrefixes(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.updatePrefixesSettings(data);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveTaxCurrency(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.updateTaxCurrencySettings(data);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveReceipt(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.updateReceiptSettings(data);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveAgent(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.updateAgentSettings(data);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
