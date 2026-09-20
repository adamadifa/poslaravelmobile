import 'package:flutter/material.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';
import 'package:poslaravelmobile/data/models/account_mutation_model.dart';
import 'package:poslaravelmobile/data/models/category_model.dart';
import 'package:poslaravelmobile/data/models/customer_model.dart';
import 'package:poslaravelmobile/data/models/dining_table_model.dart';
import 'package:poslaravelmobile/data/models/discount_model.dart';
import 'package:poslaravelmobile/data/models/ppob_product_model.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/supplier_model.dart';
import 'package:poslaravelmobile/data/models/unit_model.dart';
import 'package:poslaravelmobile/data/models/warehouse_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class MasterDataProvider extends ChangeNotifier {
  final PosRepository _repository = PosRepository();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, int> _summary = {};

  // Lists
  List<ProductModel> _products = [];
  List<ProductModel> _rawMaterials = [];
  List<CategoryModel> _categories = [];
  List<UnitModel> _units = [];
  List<CustomerModel> _customers = [];
  List<SupplierModel> _suppliers = [];
  List<WarehouseModel> _warehouses = [];
  List<DiningTableModel> _tables = [];
  List<DiscountModel> _discounts = [];
  List<AccountModel> _accounts = [];
  Map<String, dynamic> _accountSummary = {};
  List<AccountMutationModel> _accountMutations = [];
  Map<String, dynamic> _mutationsSummary = {};
  bool _isLoadingMutations = false;
  List<PpobProductModel> _ppobProducts = [];
  List<String> _ppobProviders = [];
  Map<String, dynamic> _ppobSummary = {};
  bool _isLoadingPpob = false;
  List<Map<String, dynamic>> _customerGroups = [];

  bool get isLoading => _isLoading;
  bool get isLoadingMutations => _isLoadingMutations;
  bool get isLoadingPpob => _isLoadingPpob;
  String? get errorMessage => _errorMessage;
  Map<String, int> get summary => _summary;

  List<ProductModel> get products => _products;
  List<ProductModel> get rawMaterials => _rawMaterials;
  List<CategoryModel> get categories => _categories;
  List<UnitModel> get units => _units;
  List<CustomerModel> get customers => _customers;
  List<SupplierModel> get suppliers => _suppliers;
  List<WarehouseModel> get warehouses => _warehouses;
  List<DiningTableModel> get tables => _tables;
  List<DiscountModel> get discounts => _discounts;
  List<AccountModel> get accounts => _accounts;
  Map<String, dynamic> get accountSummary => _accountSummary;
  List<AccountMutationModel> get accountMutations => _accountMutations;
  Map<String, dynamic> get mutationsSummary => _mutationsSummary;
  List<PpobProductModel> get ppobProducts => _ppobProducts;
  List<String> get ppobProviders => _ppobProviders;
  Map<String, dynamic> get ppobSummary => _ppobSummary;
  List<Map<String, dynamic>> get customerGroups => _customerGroups;

  Future<void> fetchPpobProducts({String? category, String? provider, String? search}) async {
    _isLoadingPpob = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getPpobProducts(
        category: category,
        provider: provider,
        search: search,
      );
      _ppobProducts = res['products'] as List<PpobProductModel>? ?? [];
      _ppobProviders = res['providers'] as List<String>? ?? [];
      _ppobSummary = res['summary'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingPpob = false;
      notifyListeners();
    }
  }

  Future<bool> storePpobProduct(Map<String, dynamic> data) async {
    _isLoadingPpob = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.storePpobProduct(data);
      if (ok) {
        await fetchPpobProducts();
        await fetchSummary();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoadingPpob = false;
      notifyListeners();
    }
  }

  Future<bool> updatePpobProduct(int id, Map<String, dynamic> data) async {
    _isLoadingPpob = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.updatePpobProduct(id, data);
      if (ok) {
        await fetchPpobProducts();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoadingPpob = false;
      notifyListeners();
    }
  }

  Future<bool> deletePpobProduct(int id) async {
    _isLoadingPpob = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deletePpobProduct(id);
      if (ok) {
        await fetchPpobProducts();
        await fetchSummary();
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoadingPpob = false;
      notifyListeners();
    }
  }

  Future<void> fetchAccounts({String? type, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getAccountsWithSummary(type: type, search: search);
      _accounts = res['accounts'] as List<AccountModel>? ?? [];
      _accountSummary = res['summary'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> storeAccount(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.storeAccount(data);
      if (ok) {
        await fetchAccounts();
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

  Future<bool> updateAccount(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.updateAccount(id, data);
      if (ok) {
        await fetchAccounts();
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

  Future<bool> deleteAccount(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteAccount(id);
      if (ok) {
        await fetchAccounts();
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

  Future<void> fetchAccountMutations(
    int accountId, {
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    _isLoadingMutations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getAccountMutations(
        accountId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      _accountMutations = res['mutations'] as List<AccountMutationModel>? ?? [];
      _mutationsSummary = res['summary'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMutations = false;
      notifyListeners();
    }
  }

  Future<void> fetchSummary() async {
    try {
      final res = await _repository.getMasterSummary();
      _summary = res;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchCustomerGroups() async {
    try {
      _customerGroups = await _repository.getCustomerGroups();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchProducts({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _repository.getProducts(search: search);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRawMaterials({String? search, int? categoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rawMaterials = await _repository.getRawMaterials(search: search, categoryId: categoryId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProductModel?> createProduct(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _repository.createProduct(data);
      // Refresh list
      await fetchProducts();
      await fetchSummary();
      return product;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProductModel?> updateProduct(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _repository.updateProduct(id, data);
      await fetchProducts();
      return product;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteProduct(id);
      if (ok) {
        _products.removeWhere((p) => p.id == id);
        await fetchSummary();
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

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repository.getCategories();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CategoryModel?> createCategory(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final category = await _repository.storeCategory(data);
      await fetchCategories();
      await fetchSummary();
      return category;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CategoryModel?> updateCategory(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final category = await _repository.updateCategory(id, data);
      await fetchCategories();
      return category;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteCategory(id);
      if (ok) {
        _categories.removeWhere((c) => c.id == id);
        await fetchSummary();
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

  Future<void> fetchUnits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _units = await _repository.getUnits();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UnitModel?> createUnit(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final unit = await _repository.storeUnit(data);
      await fetchUnits();
      await fetchSummary();
      return unit;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UnitModel?> updateUnit(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final unit = await _repository.updateUnit(id, data);
      await fetchUnits();
      return unit;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUnit(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteUnit(id);
      if (ok) {
        _units.removeWhere((u) => u.id == id);
        await fetchSummary();
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

  Future<void> fetchCustomers({String? search, int? customerGroupId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customers = await _repository.getCustomers(search: search, customerGroupId: customerGroupId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerModel?> createCustomer(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customer = await _repository.storeCustomer(data);
      await fetchCustomers();
      await fetchSummary();
      return customer;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerModel?> updateCustomer(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customer = await _repository.updateCustomer(id, data);
      await fetchCustomers();
      return customer;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCustomer(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteCustomer(id);
      if (ok) {
        _customers.removeWhere((c) => c.id == id);
        await fetchSummary();
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

  Future<void> fetchSuppliers({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _suppliers = await _repository.getSuppliers(search: search);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SupplierModel?> createSupplier(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supplier = await _repository.storeSupplier(data);
      await fetchSuppliers();
      await fetchSummary();
      return supplier;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SupplierModel?> updateSupplier(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supplier = await _repository.updateSupplier(id, data);
      await fetchSuppliers();
      return supplier;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSupplier(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteSupplier(id);
      if (ok) {
        _suppliers.removeWhere((s) => s.id == id);
        await fetchSummary();
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

  Future<void> fetchWarehouses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _warehouses = await _repository.getWarehouses();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<WarehouseModel?> createWarehouse(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final warehouse = await _repository.storeWarehouse(data);
      await fetchWarehouses();
      await fetchSummary();
      return warehouse;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<WarehouseModel?> updateWarehouse(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final warehouse = await _repository.updateWarehouse(id, data);
      await fetchWarehouses();
      return warehouse;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteWarehouse(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteWarehouse(id);
      if (ok) {
        _warehouses.removeWhere((w) => w.id == id);
        await fetchSummary();
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

  Future<void> fetchTables({int? warehouseId, String? area}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tables = await _repository.getTables(warehouseId: warehouseId, area: area);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DiningTableModel?> createTable(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final table = await _repository.storeTable(data);
      await fetchTables();
      await fetchSummary();
      return table;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DiningTableModel?> updateTable(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final table = await _repository.updateTable(id, data);
      await fetchTables();
      return table;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTable(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteTable(id);
      if (ok) {
        _tables.removeWhere((t) => t.id == id);
        await fetchSummary();
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

  Future<void> fetchDiscounts({String? search, String? type, bool? isActive}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _discounts = await _repository.getDiscounts(search: search, type: type, isActive: isActive);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DiscountModel?> createDiscount(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final discount = await _repository.storeDiscount(data);
      await fetchDiscounts();
      await fetchSummary();
      return discount;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DiscountModel?> updateDiscount(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final discount = await _repository.updateDiscount(id, data);
      await fetchDiscounts();
      return discount;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDiscount(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _repository.deleteDiscount(id);
      if (ok) {
        _discounts.removeWhere((d) => d.id == id);
        await fetchSummary();
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
