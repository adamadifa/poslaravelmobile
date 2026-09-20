import 'package:flutter/material.dart';
import 'package:poslaravelmobile/data/models/payment_model.dart';
import 'package:poslaravelmobile/data/models/purchase_order_model.dart';
import 'package:poslaravelmobile/data/models/purchase_payable_model.dart';
import 'package:poslaravelmobile/data/models/purchase_receipt_model.dart';
import 'package:poslaravelmobile/data/models/purchase_return_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class PurchasingProvider extends ChangeNotifier {
  final PosRepository _repository = PosRepository();

  bool _isLoading = false;
  String? _errorMessage;

  List<PurchaseOrderModel> _orders = [];
  List<PurchaseReceiptModel> _receipts = [];
  List<PurchaseReturnModel> _returns = [];
  PurchasePayableData? _payablesData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PurchaseOrderModel> get orders => _orders;
  List<PurchaseReceiptModel> get receipts => _receipts;
  List<PurchaseReturnModel> get returns => _returns;
  PurchasePayableData? get payablesData => _payablesData;
  double get totalOutstanding => _payablesData?.totalOutstanding ?? 0.0;
  List<PurchaseReceiptModel> get payables => _payablesData?.payables ?? [];

  // ==========================================
  // PURCHASE ORDERS (PO)
  // ==========================================

  Future<void> fetchOrders({
    String? search,
    String? status,
    int? supplierId,
    int? warehouseId,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _repository.getPurchaseOrders(
        search: search,
        status: status,
        supplierId: supplierId,
        warehouseId: warehouseId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseOrderModel?> getOrderDetail(int id) async {
    try {
      return await _repository.getPurchaseOrder(id);
    } catch (_) {
      return null;
    }
  }

  Future<PurchaseOrderModel?> createOrder(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final po = await _repository.storePurchaseOrder(data);
      await fetchOrders();
      return po;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseOrderModel?> updateOrder(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final po = await _repository.updatePurchaseOrder(id, data);
      await fetchOrders();
      return po;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(int id, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.updatePurchaseOrderStatus(id, status);
      if (ok) {
        await fetchOrders();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOrder(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deletePurchaseOrder(id);
      if (ok) {
        _orders.removeWhere((o) => o.id == id);
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // GOODS RECEIPTS (GRN)
  // ==========================================

  Future<void> fetchReceipts({
    String? search,
    int? supplierId,
    int? warehouseId,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _receipts = await _repository.getPurchaseReceipts(
        search: search,
        supplierId: supplierId,
        warehouseId: warehouseId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseReceiptModel?> createReceipt(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final grn = await _repository.storePurchaseReceipt(data);
      await fetchReceipts();
      await fetchOrders();
      return grn;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // PURCHASE RETURNS (RETUR PEMBELIAN)
  // ==========================================

  Future<void> fetchReturns({
    String? search,
    int? supplierId,
    int? warehouseId,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _returns = await _repository.getPurchaseReturns(
        search: search,
        supplierId: supplierId,
        warehouseId: warehouseId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseReturnModel?> getReturnDetail(int id) async {
    try {
      return await _repository.getPurchaseReturnDetail(id);
    } catch (_) {
      return null;
    }
  }

  Future<PurchaseReturnModel?> createReturn(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pr = await _repository.storePurchaseReturn(data);
      await fetchReturns();
      return pr;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReturn(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deletePurchaseReturn(id);
      if (ok) {
        _returns.removeWhere((r) => r.id == id);
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // ACCOUNT PAYABLES (HUTANG USAHA)
  // ==========================================

  Future<void> fetchPayables({
    String? search,
    int? supplierId,
    String? paymentStatus,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payablesData = await _repository.getPurchasePayables(
        search: search,
        supplierId: supplierId,
        paymentStatus: paymentStatus,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> payPayable(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.storePayablePayment(data);
      if (ok) {
        await fetchPayables();
        await fetchReceipts();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<PaymentModel>> getPayablePayments(int receiptId) async {
    try {
      return await _repository.getPayablePayments(receiptId);
    } catch (_) {
      return [];
    }
  }

  Future<bool> cancelPayment(int paymentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deletePayment(paymentId);
      if (ok) {
        await fetchPayables();
        await fetchReceipts();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
