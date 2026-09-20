import 'package:flutter/material.dart';
import 'package:poslaravelmobile/data/models/cart_item_model.dart';
import 'package:poslaravelmobile/data/models/category_model.dart';
import 'package:poslaravelmobile/data/models/customer_model.dart';
import 'package:poslaravelmobile/data/models/customer_receivable_model.dart';
import 'package:poslaravelmobile/data/models/dining_table_model.dart';
import 'package:poslaravelmobile/data/models/modifier_group_model.dart';
import 'package:poslaravelmobile/data/models/payment_model.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/sale_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class PosProvider extends ChangeNotifier {
  final PosRepository _posRepository = PosRepository();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<CustomerModel> _customers = [];
  List<DiningTableModel> _tables = [];
  Map<String, dynamic> _receiptSettings = {};

  CategoryModel? _selectedCategory;
  CustomerModel? _selectedCustomer;
  int? _selectedWarehouseId = 1;

  // POS Order Mode: 'takeaway', 'dine_in', 'delivery'
  String _serviceType = 'takeaway';
  DiningTableModel? _selectedTable;
  int _guestCount = 1;
  String _appliedPromoCode = '';

  final List<CartItemModel> _cartItems = [];
  double _globalDiscount = 0.0;
  double _taxRate = 0.0;
  double _shippingCost = 0.0;

  bool _isLoadingProducts = false;
  bool _isCheckingOut = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  List<CustomerModel> get customers => _customers;
  List<DiningTableModel> get tables => _tables;
  Map<String, dynamic> get receiptSettings => _receiptSettings;
  bool get allowManualPriceEdit => _receiptSettings['allow_manual_price_edit'] != false;
  CategoryModel? get selectedCategory => _selectedCategory;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  int? get selectedWarehouseId => _selectedWarehouseId;
  String get serviceType => _serviceType;
  DiningTableModel? get selectedTable => _selectedTable;
  int get guestCount => _guestCount;
  String get appliedPromoCode => _appliedPromoCode;
  List<CartItemModel> get cartItems => List.unmodifiable(_cartItems);
  double get globalDiscount => _globalDiscount;
  double get taxRate => _taxRate;
  double get shippingCost => _shippingCost;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isCheckingOut => _isCheckingOut;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Cart Calculations
  int get totalItemCount => _cartItems.fold(0, (sum, item) => sum + (item.qty % 1 == 0 ? item.qty.toInt() : item.qty.ceil()));
  double get totalQty => _cartItems.fold(0.0, (sum, item) => sum + item.qty);
  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get taxAmount => (subtotal - _globalDiscount > 0) ? (subtotal - _globalDiscount) * (_taxRate / 100) : 0.0;
  double get grandTotal {
    double total = subtotal - _globalDiscount + taxAmount + _shippingCost;
    return total > 0 ? total : 0.0;
  }

  void setWarehouseId(int id) {
    _selectedWarehouseId = id;
    loadProducts();
  }

  void setServiceType(String type) {
    _serviceType = type;
    if (type != 'dine_in') {
      _selectedTable = null;
    }
    notifyListeners();
  }

  void setSelectedTable(DiningTableModel? table) {
    _selectedTable = table;
    if (table != null) {
      _serviceType = 'dine_in';
    }
    notifyListeners();
  }

  void setGuestCount(int count) {
    _guestCount = count > 0 ? count : 1;
    notifyListeners();
  }

  void setPromoCode(String code) {
    _appliedPromoCode = code.trim().toUpperCase();
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadCategories(),
      loadCustomers(),
      loadTables(),
      loadReceiptSettings(),
      loadProducts(),
    ]);
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _posRepository.getCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadCustomers() async {
    try {
      _customers = await _posRepository.getCustomers();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadTables() async {
    try {
      _tables = await _posRepository.getTables();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadReceiptSettings() async {
    try {
      _receiptSettings = await _posRepository.getReceiptSettings();
      notifyListeners();
    } catch (_) {}
  }

  Future<CustomerModel?> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    int? customerGroupId,
  }) async {
    try {
      final newCust = await _posRepository.storeCustomer({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'customer_group_id': customerGroupId,
      });
      if (newCust != null) {
        _customers.insert(0, newCust);
        _selectedCustomer = newCust;
        notifyListeners();
      }
      return newCust;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _posRepository.getProducts(
        warehouseId: _selectedWarehouseId,
        categoryId: _selectedCategory?.id,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  void selectCategory(CategoryModel? category) {
    if (_selectedCategory?.id == category?.id) {
      _selectedCategory = null; // toggle off
    } else {
      _selectedCategory = category;
    }
    loadProducts();
  }

  void search(String query) {
    _searchQuery = query;
    loadProducts();
  }

  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  // Cart Operations
  void addToCart(
    ProductModel product, {
    double qty = 1.0,
    double? customPrice,
    int? unitId,
    String? unitName,
    String? notes,
    List<ModifierItemModel>? modifiers,
  }) {
    final effectiveUnitId = unitId ?? product.baseUnitId ?? 1;
    final effectiveUnitName = unitName ?? product.unitName;
    final hasModifiers = modifiers != null && modifiers.isNotEmpty;
    // Only combine if same product, same unit, no modifiers and no specific notes
    final index = _cartItems.indexWhere((item) =>
        item.product.id == product.id &&
        item.unitId == effectiveUnitId &&
        item.variantId == null &&
        (!hasModifiers && item.selectedModifiers.isEmpty) &&
        (notes == null || notes.isEmpty || item.notes == notes));

    if (index >= 0) {
      _cartItems[index].qty += qty;
      if (customPrice != null) _cartItems[index].unitPrice = customPrice;
      if (notes != null && notes.isNotEmpty) _cartItems[index].notes = notes;
    } else {
      _cartItems.add(
        CartItemModel(
          product: product,
          qty: qty,
          unitPrice: customPrice ?? product.sellingPrice,
          unitId: effectiveUnitId,
          unitName: effectiveUnitName,
          notes: notes,
          selectedModifiers: modifiers != null ? List.from(modifiers) : [],
        ),
      );
    }
    notifyListeners();
  }

  Future<double?> resolveProductUnitPrice(int productId, int unitId, {double quantity = 1.0}) async {
    return await _posRepository.getProductPrice(
      productId: productId,
      unitId: unitId,
      quantity: quantity,
      customerId: _selectedCustomer?.id,
    );
  }

  void increaseQty(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].qty += 1;
      notifyListeners();
    }
  }

  void decreaseQty(int index) {
    if (index >= 0 && index < _cartItems.length) {
      if (_cartItems[index].qty > 1) {
        _cartItems[index].qty -= 1;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void updateItemQty(int index, double qty) {
    if (index >= 0 && index < _cartItems.length) {
      if (qty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].qty = qty;
      }
      notifyListeners();
    }
  }

  void updateItemPrice(int index, double price) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].unitPrice = price;
      notifyListeners();
    }
  }

  void updateItemModifiers(int index, List<ModifierItemModel> modifiers) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].selectedModifiers = List.from(modifiers);
      notifyListeners();
    }
  }

  void updateItemNotes(int index, String? notes) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].notes = notes;
      notifyListeners();
    }
  }

  void updateItemUnit(int index, int unitId, String unitName, {double? newPrice}) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].unitId = unitId;
      _cartItems[index].unitName = unitName;
      if (newPrice != null) {
        _cartItems[index].unitPrice = newPrice;
      }
      notifyListeners();
    }
  }

  void updateItemDiscount(int index, double discount) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].discountAmount = discount;
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void setGlobalDiscount(double discount) {
    _globalDiscount = discount;
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }

  void setShippingCost(double shipping) {
    _shippingCost = shipping;
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _globalDiscount = 0.0;
    _taxRate = 0.0;
    _shippingCost = 0.0;
    _selectedCustomer = null;
    _selectedTable = null;
    _appliedPromoCode = '';
    _guestCount = 1;
    _serviceType = 'takeaway';
    notifyListeners();
  }

  // Checkout API
  Future<Map<String, dynamic>?> checkout({
    int? shiftId,
    int? tableId,
    String? serviceType,
    int? guestCount,
    required String paymentMethod,
    required double paidAmount,
    String? notes,
  }) async {
    if (_cartItems.isEmpty) return null;

    _isCheckingOut = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _posRepository.checkout(
        warehouseId: _selectedWarehouseId ?? 1,
        customerId: _selectedCustomer?.id,
        shiftId: shiftId,
        serviceType: serviceType ?? _serviceType,
        tableId: tableId ?? _selectedTable?.id,
        guestCount: guestCount ?? _guestCount,
        items: _cartItems,
        discount: _globalDiscount,
        promoCode: _appliedPromoCode.isNotEmpty ? _appliedPromoCode : null,
        taxRate: _taxRate,
        shippingCost: _shippingCost,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        notes: notes,
      );

      clearCart();
      _isCheckingOut = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isCheckingOut = false;
      notifyListeners();
      return null;
    }
  }

  // Hold & Recall
  Future<bool> holdCart(String referenceNote) async {
    if (_cartItems.isEmpty) return false;

    try {
      final label = referenceNote.trim().isNotEmpty
          ? referenceNote.trim()
          : (_selectedCustomer?.name ?? 'Order #${DateTime.now().millisecondsSinceEpoch % 10000}');

      await _posRepository.holdTransaction(
        warehouseId: _selectedWarehouseId ?? 1,
        customerId: _selectedCustomer?.id,
        referenceNote: label,
        items: _cartItems,
      );
      clearCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<List<dynamic>> getHeldList() async {
    return await _posRepository.getHeldList();
  }

  Future<bool> recallHeld(int id) async {
    try {
      final data = await _posRepository.recallHeld(id);
      clearCart();
      if (data != null && data['cart_payload'] != null) {
        final payload = data['cart_payload'] as List;
        for (var item in payload) {
          final prod = _products.firstWhere(
            (p) => p.id == item['product_id'],
            orElse: () => ProductModel(
              id: item['product_id'] ?? 0,
              name: item['product_name'] ?? item['name'] ?? 'Produk #${item['product_id']}',
              costPrice: 0,
              sellingPrice: double.tryParse((item['price'] ?? item['unit_price'] ?? 0).toString()) ?? 0.0,
            ),
          );
          _cartItems.add(
            CartItemModel(
              product: prod,
              qty: double.tryParse((item['quantity'] ?? item['qty'] ?? 1).toString()) ?? 1.0,
              unitPrice: double.tryParse((item['price'] ?? item['unit_price'] ?? prod.sellingPrice).toString()) ?? prod.sellingPrice,
              discountAmount: double.tryParse((item['discount'] ?? 0).toString()) ?? 0.0,
              unitId: item['unit_id'] ?? prod.baseUnitId ?? 1,
              notes: item['notes'],
            ),
          );
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // ACCOUNT RECEIVABLES (PIUTANG PENJUALAN)
  // ==========================================

  CustomerReceivableData? _receivablesData;
  bool _isLoadingReceivables = false;

  CustomerReceivableData? get receivablesData => _receivablesData;
  double get totalReceivablesOutstanding => _receivablesData?.totalOutstanding ?? 0.0;
  List<SaleModel> get receivables => _receivablesData?.receivables ?? [];
  bool get isLoadingReceivables => _isLoadingReceivables;

  Future<void> fetchReceivables({
    String? search,
    int? customerId,
    String? paymentStatus,
  }) async {
    _isLoadingReceivables = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _receivablesData = await _posRepository.getCustomerReceivables(
        search: search,
        customerId: customerId,
        paymentStatus: paymentStatus,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingReceivables = false;
      notifyListeners();
    }
  }

  Future<bool> collectReceivable(Map<String, dynamic> data) async {
    _isLoadingReceivables = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _posRepository.storeReceivablePayment(data);
      if (ok) {
        await fetchReceivables();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoadingReceivables = false;
      notifyListeners();
    }
  }

  Future<List<PaymentModel>> getReceivablePayments(int saleId) async {
    try {
      return await _posRepository.getReceivablePayments(saleId);
    } catch (_) {
      return [];
    }
  }

  Future<bool> cancelReceivablePayment(int paymentId) async {
    _isLoadingReceivables = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _posRepository.deletePayment(paymentId);
      if (ok) {
        await fetchReceivables();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoadingReceivables = false;
      notifyListeners();
    }
  }
}
