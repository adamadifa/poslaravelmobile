import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poslaravelmobile/data/models/stock_adjustment_model.dart';
import 'package:poslaravelmobile/data/models/stock_alert_model.dart';
import 'package:poslaravelmobile/data/models/stock_batch_model.dart';
import 'package:poslaravelmobile/data/models/stock_movement_model.dart';
import 'package:poslaravelmobile/data/models/stock_opname_model.dart';
import 'package:poslaravelmobile/data/models/stock_transfer_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class StockProvider extends ChangeNotifier {
  final PosRepository _repository = PosRepository();

  bool _isLoading = false;
  String? _errorMessage;

  // Data
  List<StockMovementModel> _movements = [];
  StockMovementSummaryModel _summary = StockMovementSummaryModel(
    totalIn: 0,
    totalOut: 0,
    movementsCount: 0,
  );

  List<StockBatchModel> _batches = [];
  double _totalBatchStock = 0;
  double _totalBatchValuation = 0;
  int _totalBatchesCount = 0;

  ProductStockCardData? _productCardData;
  bool _isLoadingProductCard = false;

  // Stock Alerts Data
  StockAlertsResultModel? _alertsData;
  bool _isLoadingAlerts = false;
  int _alertDaysThreshold = 30; // 30, 60, 90 days
  String _alertProductTypeTab = 'all'; // 'all', 'products', 'raw_materials'
  int? _alertWarehouseId;
  String _alertSearch = '';

  // Stok Opname Data
  List<StockOpnameModel> _opnames = [];
  StockOpnameModel? _selectedOpname;
  bool _isLoadingOpnameDetail = false;
  String? _opnameStatusFilter;

  // Stock Transfer Data
  List<StockTransferModel> _transfers = [];
  StockTransferModel? _selectedTransfer;
  bool _isLoadingTransferDetail = false;
  String? _transferStatusFilter;
  int? _fromWarehouseFilter;
  int? _toWarehouseFilter;

  // Stock Adjustment Data
  List<StockAdjustmentModel> _adjustments = [];
  StockAdjustmentModel? _selectedAdjustment;
  bool _isLoadingAdjustmentDetail = false;
  String? _adjustmentStatusFilter;
  String? _adjustmentTypeFilter;

  // Filters
  String _productTypeTab = 'all'; // 'all', 'products', 'raw_materials'
  int? _selectedWarehouseId;
  int? _selectedProductId;
  String _movementType = 'all'; // 'all', 'in', 'out'
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<StockMovementModel> get movements => _movements;
  StockMovementSummaryModel get summary => _summary;

  List<StockBatchModel> get batches => _batches;
  double get totalBatchStock => _totalBatchStock;
  double get totalBatchValuation => _totalBatchValuation;
  int get totalBatchesCount => _totalBatchesCount;

  ProductStockCardData? get productCardData => _productCardData;
  bool get isLoadingProductCard => _isLoadingProductCard;

  List<StockOpnameModel> get opnames => _opnames;
  StockOpnameModel? get selectedOpname => _selectedOpname;
  bool get isLoadingOpnameDetail => _isLoadingOpnameDetail;
  String? get opnameStatusFilter => _opnameStatusFilter;

  List<StockTransferModel> get transfers => _transfers;
  StockTransferModel? get selectedTransfer => _selectedTransfer;
  bool get isLoadingTransferDetail => _isLoadingTransferDetail;
  String? get transferStatusFilter => _transferStatusFilter;
  int? get fromWarehouseFilter => _fromWarehouseFilter;
  int? get toWarehouseFilter => _toWarehouseFilter;

  List<StockAdjustmentModel> get adjustments => _adjustments;
  StockAdjustmentModel? get selectedAdjustment => _selectedAdjustment;
  bool get isLoadingAdjustmentDetail => _isLoadingAdjustmentDetail;
  String? get adjustmentStatusFilter => _adjustmentStatusFilter;
  String? get adjustmentTypeFilter => _adjustmentTypeFilter;

  String get productTypeTab => _productTypeTab;
  int? get selectedWarehouseId => _selectedWarehouseId;
  int? get selectedProductId => _selectedProductId;
  String get movementType => _movementType;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Filter setters
  void setProductTypeTab(String tab) {
    if (_productTypeTab != tab) {
      _productTypeTab = tab;
      _selectedProductId = null;
      notifyListeners();
      refreshAll();
    }
  }

  void setWarehouseFilter(int? warehouseId) {
    if (_selectedWarehouseId != warehouseId) {
      _selectedWarehouseId = warehouseId;
      notifyListeners();
      refreshAll();
    }
  }

  void setProductFilter(int? productId) {
    if (_selectedProductId != productId) {
      _selectedProductId = productId;
      notifyListeners();
      refreshAll();
    }
  }

  void setMovementTypeFilter(String type) {
    if (_movementType != type) {
      _movementType = type;
      notifyListeners();
      fetchMovements();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    fetchMovements();
    fetchBatches();
    fetchTransfers();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
    fetchMovements();
    fetchTransfers();
  }

  void clearFilters() {
    _selectedWarehouseId = null;
    _selectedProductId = null;
    _movementType = 'all';
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _fromWarehouseFilter = null;
    _toWarehouseFilter = null;
    _transferStatusFilter = null;
    _adjustmentStatusFilter = null;
    _adjustmentTypeFilter = null;
    notifyListeners();
    refreshAll();
  }

  // API Call: Fetch Movements
  Future<void> fetchMovements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      final res = await _repository.getStockMovements(
        productId: _selectedProductId,
        warehouseId: _selectedWarehouseId,
        type: _movementType,
        tab: _productTypeTab,
        startDate: startStr,
        endDate: endStr,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );

      if (res != null) {
        _movements = res.movements;
        _summary = res.summary;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // API Call: Fetch Active FIFO Batches
  Future<void> fetchBatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getStockBatches(
        productId: _selectedProductId,
        warehouseId: _selectedWarehouseId,
        tab: _productTypeTab,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );

      if (res != null) {
        _batches = res.batches;
        _totalBatchStock = res.totalStock;
        _totalBatchValuation = res.totalValuation;
        _totalBatchesCount = res.totalBatchesCount;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // API Call: Fetch Specific Product Stock Card Overview
  Future<void> fetchProductStockCard(int productId) async {
    _isLoadingProductCard = true;
    notifyListeners();

    try {
      _productCardData = await _repository.getProductStockCard(
        productId,
        warehouseId: _selectedWarehouseId,
      );
    } catch (_) {
      _productCardData = null;
    } finally {
      _isLoadingProductCard = false;
      notifyListeners();
    }
  }

  // ==========================================
  // STOCK ALERTS METHODS
  // ==========================================

  StockAlertsResultModel? get alertsData => _alertsData;
  bool get isLoadingAlerts => _isLoadingAlerts;
  int get alertDaysThreshold => _alertDaysThreshold;
  String get alertProductTypeTab => _alertProductTypeTab;
  int? get alertWarehouseId => _alertWarehouseId;
  String get alertSearch => _alertSearch;

  void setAlertDaysThreshold(int days) {
    if (_alertDaysThreshold != days) {
      _alertDaysThreshold = days;
      notifyListeners();
      fetchAlerts();
    }
  }

  void setAlertProductTypeTab(String tab) {
    if (_alertProductTypeTab != tab) {
      _alertProductTypeTab = tab;
      notifyListeners();
      fetchAlerts();
    }
  }

  void setAlertWarehouseFilter(int? warehouseId) {
    if (_alertWarehouseId != warehouseId) {
      _alertWarehouseId = warehouseId;
      notifyListeners();
      fetchAlerts();
    }
  }

  void setAlertSearch(String query) {
    _alertSearch = query;
    notifyListeners();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    _isLoadingAlerts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getStockAlerts(
        warehouseId: _alertWarehouseId,
        tab: _alertProductTypeTab,
        search: _alertSearch.trim().isNotEmpty ? _alertSearch.trim() : null,
        days: _alertDaysThreshold,
      );

      _alertsData = res;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }

  // ==========================================
  // STOK OPNAME METHODS
  // ==========================================

  void setOpnameStatusFilter(String? status) {
    _opnameStatusFilter = status;
    notifyListeners();
    fetchOpnames();
  }

  Future<void> fetchOpnames() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      _opnames = await _repository.getStockOpnames(
        warehouseId: _selectedWarehouseId,
        status: _opnameStatusFilter,
        startDate: startStr,
        endDate: endStr,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StockOpnameModel?> fetchOpnameDetail(int id) async {
    _isLoadingOpnameDetail = true;
    notifyListeners();

    try {
      final detail = await _repository.getStockOpnameDetail(id);
      _selectedOpname = detail;
      return detail;
    } catch (_) {
      return null;
    } finally {
      _isLoadingOpnameDetail = false;
      notifyListeners();
    }
  }

  Future<bool> createOpname(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.storeStockOpname(data);
      if (res != null) {
        await fetchOpnames();
        return true;
      }
      _errorMessage = 'Gagal membuat dokumen stok opname';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOpname(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.updateStockOpname(id, data);
      if (res != null) {
        _selectedOpname = res;
        await fetchOpnames();
        return true;
      }
      _errorMessage = 'Gagal memperbarui dokumen stok opname';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveOpname(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.approveStockOpname(id);
      if (res != null) {
        _selectedOpname = res;
        await fetchOpnames();
        return true;
      }
      _errorMessage = 'Gagal menyetujui stok opname';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOpname(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.deleteStockOpname(id);
      if (success) {
        await fetchOpnames();
        return true;
      }
      _errorMessage = 'Gagal menghapus / membatalkan stok opname';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // STOCK TRANSFER METHODS
  // ==========================================

  void setTransferStatusFilter(String? status) {
    _transferStatusFilter = status;
    notifyListeners();
    fetchTransfers();
  }

  void setTransferWarehouseFilters({int? fromWarehouseId, int? toWarehouseId}) {
    _fromWarehouseFilter = fromWarehouseId;
    _toWarehouseFilter = toWarehouseId;
    notifyListeners();
    fetchTransfers();
  }

  Future<void> fetchTransfers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      _transfers = await _repository.getStockTransfers(
        fromWarehouseId: _fromWarehouseFilter,
        toWarehouseId: _toWarehouseFilter,
        status: _transferStatusFilter,
        startDate: startStr,
        endDate: endStr,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StockTransferModel?> fetchTransferDetail(int id) async {
    _isLoadingTransferDetail = true;
    notifyListeners();

    try {
      final detail = await _repository.getStockTransferDetail(id);
      _selectedTransfer = detail;
      return detail;
    } catch (_) {
      return null;
    } finally {
      _isLoadingTransferDetail = false;
      notifyListeners();
    }
  }

  Future<bool> createTransfer(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.storeStockTransfer(data);
      if (res != null) {
        await fetchTransfers();
        return true;
      }
      _errorMessage = 'Gagal membuat dokumen transfer stok';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> dispatchTransfer(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.dispatchStockTransfer(id);
      if (res != null) {
        _selectedTransfer = res;
        await fetchTransfers();
        return true;
      }
      _errorMessage = 'Gagal mengirim barang transfer';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> receiveTransfer(int id, {List<Map<String, dynamic>>? items}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.receiveStockTransfer(id, items: items);
      if (res != null) {
        _selectedTransfer = res;
        await fetchTransfers();
        return true;
      }
      _errorMessage = 'Gagal memproses penerimaan transfer';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTransfer(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.deleteStockTransfer(id);
      if (success) {
        await fetchTransfers();
        return true;
      }
      _errorMessage = 'Gagal menghapus / membatalkan transfer stok';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchMovements(),
      fetchBatches(),
      fetchOpnames(),
      fetchTransfers(),
      fetchAdjustments(),
      if (_selectedProductId != null) fetchProductStockCard(_selectedProductId!),
    ]);
  }

  // ==========================================
  // STOCK ADJUSTMENT METHODS
  // ==========================================

  void setAdjustmentStatusFilter(String? status) {
    _adjustmentStatusFilter = status;
    notifyListeners();
    fetchAdjustments();
  }

  void setAdjustmentTypeFilter(String? type) {
    _adjustmentTypeFilter = type;
    notifyListeners();
    fetchAdjustments();
  }

  Future<void> fetchAdjustments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      _adjustments = await _repository.getStockAdjustments(
        warehouseId: _selectedWarehouseId,
        status: _adjustmentStatusFilter,
        type: _adjustmentTypeFilter,
        startDate: startStr,
        endDate: endStr,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StockAdjustmentModel?> fetchAdjustmentDetail(int id) async {
    _isLoadingAdjustmentDetail = true;
    notifyListeners();

    try {
      final detail = await _repository.getStockAdjustmentDetail(id);
      _selectedAdjustment = detail;
      return detail;
    } catch (_) {
      return null;
    } finally {
      _isLoadingAdjustmentDetail = false;
      notifyListeners();
    }
  }

  Future<bool> createAdjustment(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.storeStockAdjustment(data);
      if (res != null) {
        await fetchAdjustments();
        return true;
      }
      _errorMessage = 'Gagal membuat dokumen penyesuaian stok';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAdjustment(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.updateStockAdjustment(id, data);
      if (res != null) {
        _selectedAdjustment = res;
        await fetchAdjustments();
        return true;
      }
      _errorMessage = 'Gagal memperbarui dokumen penyesuaian stok';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveAdjustment(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.approveStockAdjustment(id);
      if (res != null) {
        _selectedAdjustment = res;
        await fetchAdjustments();
        return true;
      }
      _errorMessage = 'Gagal menyetujui penyesuaian stok';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAdjustment(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.deleteStockAdjustment(id);
      if (success) {
        await fetchAdjustments();
        return true;
      }
      _errorMessage = 'Gagal menghapus / membatalkan penyesuaian stok';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
