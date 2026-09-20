import 'package:dio/dio.dart';
import 'package:poslaravelmobile/core/api/api_client.dart';
import 'package:poslaravelmobile/core/api/api_endpoints.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';
import 'package:poslaravelmobile/data/models/account_mutation_model.dart';
import 'package:poslaravelmobile/data/models/account_transfer_model.dart';
import 'package:poslaravelmobile/data/models/cart_item_model.dart';
import 'package:poslaravelmobile/data/models/cash_flow_model.dart';
import 'package:poslaravelmobile/data/models/category_model.dart';
import 'package:poslaravelmobile/data/models/customer_model.dart';
import 'package:poslaravelmobile/data/models/customer_receivable_model.dart';
import 'package:poslaravelmobile/data/models/dining_table_model.dart';
import 'package:poslaravelmobile/data/models/discount_model.dart';
import 'package:poslaravelmobile/data/models/payment_model.dart';
import 'package:poslaravelmobile/data/models/ppob_product_model.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';
import 'package:poslaravelmobile/data/models/purchase_order_model.dart';
import 'package:poslaravelmobile/data/models/purchase_payable_model.dart';
import 'package:poslaravelmobile/data/models/purchase_receipt_model.dart';
import 'package:poslaravelmobile/data/models/purchase_return_model.dart';
import 'package:poslaravelmobile/data/models/sale_model.dart';
import 'package:poslaravelmobile/data/models/sale_return_model.dart';
import 'package:poslaravelmobile/data/models/stock_adjustment_model.dart';
import 'package:poslaravelmobile/data/models/stock_alert_model.dart';
import 'package:poslaravelmobile/data/models/stock_batch_model.dart';
import 'package:poslaravelmobile/data/models/stock_movement_model.dart';
import 'package:poslaravelmobile/data/models/stock_opname_model.dart';
import 'package:poslaravelmobile/data/models/stock_transfer_model.dart';
import 'package:poslaravelmobile/data/models/supplier_model.dart';
import 'package:poslaravelmobile/data/models/unit_model.dart';
import 'package:poslaravelmobile/data/models/warehouse_model.dart';

class PosRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ProductModel>> getProducts({int? warehouseId, int? categoryId, String? search, String? productType}) async {
    try {
      final query = <String, dynamic>{};
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (categoryId != null) query['category_id'] = categoryId;
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (productType != null && productType.isNotEmpty) query['product_type'] = productType;

      final response = await _apiClient.get(ApiEndpoints.products, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => ProductModel.fromJson(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data produk.');
    }
  }

  Future<List<ProductModel>> getRawMaterials({String? search, int? categoryId}) async {
    return getProducts(search: search, categoryId: categoryId, productType: 'raw_material');
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.storeProduct, data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ProductModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal menambahkan produk.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal menambahkan produk.');
    }
  }

  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateProduct(id), data: data);
      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memperbarui produk.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal memperbarui produk.');
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteProduct(id));
      if (response.statusCode == 200) {
        return true;
      }
      throw Exception(response.data['message'] ?? 'Gagal menghapus produk.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal menghapus produk.');
    }
  }

  Future<double?> getProductPrice({
    required int productId,
    required int unitId,
    double quantity = 1.0,
    int? customerId,
  }) async {
    try {
      final query = <String, dynamic>{
        'unit_id': unitId,
        'quantity': quantity,
      };
      if (customerId != null) query['customer_id'] = customerId;

      final response = await _apiClient.get(
        ApiEndpoints.productPrice(productId),
        queryParameters: query,
      );

      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'];
        if (data != null && data['final_unit_price'] != null) {
          return double.tryParse(data['final_unit_price'].toString());
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categories);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => CategoryModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<CategoryModel?> storeCategory(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.categories, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CategoryModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CategoryModel?> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateCategory(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CategoryModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteCategory(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<List<CustomerModel>> getCustomers({String? search, int? customerGroupId}) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (customerGroupId != null) query['customer_group_id'] = customerGroupId;
      final response = await _apiClient.get(ApiEndpoints.customers, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => CustomerModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<CustomerModel?> storeCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.customers, data: data);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CustomerModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CustomerModel?> updateCustomer(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateCustomer(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CustomerModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteCustomer(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerGroups() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.customerGroups);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<UnitModel>> getUnits() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.units);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => UnitModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<UnitModel?> storeUnit(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.units, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return UnitModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UnitModel?> updateUnit(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateUnit(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return UnitModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteUnit(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteUnit(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<List<SupplierModel>> getSuppliers({String? search}) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      final response = await _apiClient.get(ApiEndpoints.suppliers, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => SupplierModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<SupplierModel?> storeSupplier(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.suppliers, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return SupplierModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<SupplierModel?> updateSupplier(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateSupplier(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return SupplierModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteSupplier(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<List<WarehouseModel>> getWarehouses() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.warehouses);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => WarehouseModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<WarehouseModel?> storeWarehouse(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.warehouses, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return WarehouseModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<WarehouseModel?> updateWarehouse(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateWarehouse(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return WarehouseModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteWarehouse(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteWarehouse(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<List<AccountModel>> getAccounts({String? type, String? search}) async {
    try {
      final query = <String, dynamic>{};
      if (type != null && type.isNotEmpty && type != 'all') query['type'] = type;
      if (search != null && search.isNotEmpty) query['q'] = search;

      final response = await _apiClient.get(ApiEndpoints.accounts, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'];
        if (data is Map && data['accounts'] != null) {
          final list = data['accounts'] as List;
          return list.map((item) => AccountModel.fromJson(item)).toList();
        } else if (data is List) {
          return data.map((item) => AccountModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAccountsWithSummary({String? type, String? search}) async {
    try {
      final query = <String, dynamic>{};
      if (type != null && type.isNotEmpty && type != 'all') query['type'] = type;
      if (search != null && search.isNotEmpty) query['q'] = search;

      final response = await _apiClient.get(ApiEndpoints.accounts, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'];
        if (data is Map) {
          final accountsList = data['accounts'] is List
              ? (data['accounts'] as List).map((e) => AccountModel.fromJson(e)).toList()
              : <AccountModel>[];
          final summary = data['summary'] as Map<String, dynamic>? ?? {};
          return {
            'accounts': accountsList,
            'summary': summary,
          };
        }
      }
      return {'accounts': <AccountModel>[], 'summary': <String, dynamic>{}};
    } catch (_) {
      return {'accounts': <AccountModel>[], 'summary': <String, dynamic>{}};
    }
  }

  Future<bool> storeAccount(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.accounts, data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.updateAccount(id), data: data);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteAccount(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getAccountMutations(
    int accountId, {
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (type != null && type.isNotEmpty && type != 'all') query['type'] = type;
      if (startDate != null && startDate.isNotEmpty) query['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) query['end_date'] = endDate;

      final response = await _apiClient.get(
        ApiEndpoints.accountMutations(accountId),
        queryParameters: query,
      );
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'] as Map<String, dynamic>;
        final mutationsList = (data['mutations'] as List? ?? [])
            .map((e) => AccountMutationModel.fromJson(e))
            .toList();
        final account = data['account'] != null ? AccountModel.fromJson(data['account']) : null;
        final summary = data['summary'] as Map<String, dynamic>? ?? {};

        return {
          'account': account,
          'mutations': mutationsList,
          'summary': summary,
        };
      }
      return {'mutations': <AccountMutationModel>[], 'summary': <String, dynamic>{}};
    } catch (_) {
      return {'mutations': <AccountMutationModel>[], 'summary': <String, dynamic>{}};
    }
  }

  Future<Map<String, dynamic>> getPpobProducts({
    String? category,
    String? provider,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category != 'all') query['category'] = category;
      if (provider != null && provider.isNotEmpty && provider != 'all') query['provider'] = provider;
      if (search != null && search.isNotEmpty) query['q'] = search;

      final response = await _apiClient.get(ApiEndpoints.ppobProducts, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'] as Map<String, dynamic>;
        final productsList = (data['products'] as List? ?? [])
            .map((e) => PpobProductModel.fromJson(e))
            .toList();
        final providersList = (data['providers'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        final summary = data['summary'] as Map<String, dynamic>? ?? {};

        return {
          'products': productsList,
          'providers': providersList,
          'summary': summary,
        };
      }
      return {'products': <PpobProductModel>[], 'providers': <String>[], 'summary': <String, dynamic>{}};
    } catch (_) {
      return {'products': <PpobProductModel>[], 'providers': <String>[], 'summary': <String, dynamic>{}};
    }
  }

  Future<bool> storePpobProduct(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.ppobProducts, data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updatePpobProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.updatePpobProduct(id), data: data);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePpobProduct(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deletePpobProduct(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, int>> getMasterSummary() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.masterSummary);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'] as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0));
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<List<DiningTableModel>> getTables({int? warehouseId, String? area}) async {
    try {
      final query = <String, dynamic>{};
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (area != null && area.isNotEmpty) query['area'] = area;
      final response = await _apiClient.get(ApiEndpoints.tables, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => DiningTableModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<DiningTableModel?> storeTable(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.tables, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return DiningTableModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DiningTableModel?> updateTable(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateTable(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return DiningTableModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteTable(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteTable(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<List<DiscountModel>> getDiscounts({String? search, String? type, bool? isActive}) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (type != null && type.isNotEmpty) query['type'] = type;
      if (isActive != null) query['status'] = isActive ? '1' : '0';

      final response = await _apiClient.get(ApiEndpoints.discounts, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => DiscountModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<DiscountModel?> storeDiscount(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.discounts, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return DiscountModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DiscountModel?> updateDiscount(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateDiscount(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return DiscountModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteDiscount(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteDiscount(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // PURCHASING & PENGADAAN
  // ==========================================

  Future<List<PurchaseOrderModel>> getPurchaseOrders({
    String? search,
    String? status,
    int? supplierId,
    int? warehouseId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (supplierId != null) query['supplier_id'] = supplierId;
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;

      final response = await _apiClient.get(ApiEndpoints.purchaseOrders, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => PurchaseOrderModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<PurchaseOrderModel?> getPurchaseOrder(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.purchaseOrder(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return PurchaseOrderModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PurchaseOrderModel?> storePurchaseOrder(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.purchaseOrders, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return PurchaseOrderModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PurchaseOrderModel?> updatePurchaseOrder(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updatePurchaseOrder(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return PurchaseOrderModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updatePurchaseOrderStatus(int id, String status) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.updatePurchaseOrderStatus(id),
        data: {'status': status},
      );
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePurchaseOrder(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deletePurchaseOrder(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  Future<List<PurchaseReceiptModel>> getPurchaseReceipts({
    String? search,
    int? supplierId,
    int? warehouseId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (supplierId != null) query['supplier_id'] = supplierId;
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;

      final response = await _apiClient.get(ApiEndpoints.purchaseReceipts, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => PurchaseReceiptModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<PurchaseReceiptModel?> storePurchaseReceipt(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.purchaseReceipts, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return PurchaseReceiptModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal menyimpan penerimaan barang');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ??
          (e.response?.data?['errors'] is List ? (e.response?.data?['errors'] as List).join(', ') : null);
      throw Exception(serverMsg ?? e.message ?? 'Gagal menyimpan penerimaan barang');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<PurchaseReturnModel>> getPurchaseReturns({
    String? search,
    int? supplierId,
    int? warehouseId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (supplierId != null) query['supplier_id'] = supplierId;
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;

      final response = await _apiClient.get(ApiEndpoints.purchaseReturns, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => PurchaseReturnModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<PurchaseReturnModel?> getPurchaseReturnDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.purchaseReturn(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return PurchaseReturnModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PurchaseReturnModel?> storePurchaseReturn(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.purchaseReturns, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return PurchaseReturnModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memproses retur pembelian');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ??
          (e.response?.data?['errors'] is List ? (e.response?.data?['errors'] as List).join(', ') : null);
      throw Exception(serverMsg ?? e.message ?? 'Gagal memproses retur pembelian');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<bool> deletePurchaseReturn(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deletePurchaseReturn(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return true;
      }
      throw Exception(response.data['message'] ?? 'Gagal membatalkan retur pembelian');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ?? e.message;
      throw Exception(serverMsg ?? 'Gagal membatalkan retur pembelian');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<PurchasePayableData?> getPurchasePayables({
    String? search,
    int? supplierId,
    String? paymentStatus,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (supplierId != null) query['supplier_id'] = supplierId;
      if (paymentStatus != null) query['payment_status'] = paymentStatus;

      final response = await _apiClient.get(ApiEndpoints.purchasePayables, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return PurchasePayableData.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> storePayablePayment(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.storePayablePayment, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return true;
      }
      throw Exception(response.data['message'] ?? 'Gagal memproses pembayaran hutang.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?['errors']?.toString() ?? e.message;
      throw Exception(msg ?? 'Gagal memproses pembayaran hutang.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<PaymentModel>> getPayablePayments(int receiptId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.payablePayments(receiptId));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List? ?? [];
        return list.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> deletePayment(int paymentId) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deletePayment(paymentId));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return true;
      }
      throw Exception(response.data['message'] ?? 'Gagal membatalkan pembayaran.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal membatalkan pembayaran.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  // ==========================================
  // ACCOUNT RECEIVABLES (PIUTANG USAHA)
  // ==========================================

  Future<CustomerReceivableData?> getCustomerReceivables({
    String? search,
    int? customerId,
    String? paymentStatus,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (customerId != null) query['customer_id'] = customerId;
      if (paymentStatus != null) query['payment_status'] = paymentStatus;

      final response = await _apiClient.get(ApiEndpoints.customerReceivables, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CustomerReceivableData.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> storeReceivablePayment(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.storeReceivablePayment, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return true;
      }
      throw Exception(response.data['message'] ?? 'Gagal memproses penerimaan piutang.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?['errors']?.toString() ?? e.message;
      throw Exception(msg ?? 'Gagal memproses penerimaan piutang.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<PaymentModel>> getReceivablePayments(int saleId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.receivablePayments(saleId));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List? ?? [];
        return list.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getReceiptSettings() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.receiptSettings);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> calculateCart({
    required List<CartItemModel> items,
    int? customerId,
    double discount = 0,
    double taxRate = 0,
    double shippingCost = 0,
    String? promoCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.calculateCart,
        data: {
          'items': items.map((i) => i.toApiCheckoutItem()).toList(),
          'customer_id': customerId,
          'manual_discount': discount,
          'promo_code': promoCode,
          'tax_rate': taxRate,
          'shipping_cost': shippingCost,
        },
      );
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Gagal menghitung keranjang.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menghitung keranjang.');
    }
  }

  Future<Map<String, dynamic>> checkout({
    required int warehouseId,
    int? customerId,
    int? shiftId,
    String? serviceType,
    int? tableId,
    int? guestCount,
    required List<CartItemModel> items,
    double discount = 0,
    double taxRate = 0,
    double shippingCost = 0,
    String? promoCode,
    required String paymentMethod,
    required double paidAmount,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.checkout,
        data: {
          'warehouse_id': warehouseId,
          'customer_id': customerId,
          'cashier_shift_id': shiftId,
          'service_type': serviceType ?? 'takeaway',
          'dining_table_id': tableId,
          'guest_count': guestCount ?? 1,
          'items': items.map((i) => i.toApiCheckoutItem()).toList(),
          'manual_discount': discount,
          'promo_code': promoCode,
          'tax_rate': taxRate,
          'shipping_cost': shippingCost,
          'payment_method': paymentMethod,
          'paid_amount': paidAmount,
          'notes': notes,
        },
      );
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Checkout gagal.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          (e.response?.data?['errors'] is List ? (e.response?.data?['errors'] as List).join(', ') : null) ??
          'Checkout gagal.';
      throw Exception(msg);
    }
  }

  Future<void> holdTransaction({
    required int warehouseId,
    int? customerId,
    required String referenceNote,
    required List<CartItemModel> items,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.hold,
        data: {
          'warehouse_id': warehouseId,
          'customer_id': customerId,
          'reference_label': referenceNote,
          'cart_payload': items.map((i) => i.toApiCheckoutItem()).toList(),
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menyimpan transaksi hold.');
    }
  }

  Future<List<dynamic>> getHeldList() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.heldList);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return response.data['data'] as List;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<dynamic> recallHeld(int id) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.recall(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Gagal recall transaksi.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal recall transaksi.');
    }
  }

  // ==========================================
  // INVENTARIS & KARTU STOK (FIFO) & PERINGATAN STOK
  // ==========================================

  Future<StockAlertsResultModel?> getStockAlerts({
    int? warehouseId,
    int? categoryId,
    String? tab,
    String? search,
    int days = 30,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (categoryId != null) query['category_id'] = categoryId;
      if (tab != null && tab != 'all') query['tab'] = tab;
      if (search != null && search.isNotEmpty) query['q'] = search;
      query['days'] = days;

      final response = await _apiClient.get(ApiEndpoints.stockAlerts, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockAlertsResultModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StockMovementsResult?> getStockMovements({
    int? productId,
    int? warehouseId,
    String? type,
    String? tab,
    String? startDate,
    String? endDate,
    String? search,
    int limit = 100,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (productId != null) query['product_id'] = productId;
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (type != null && type != 'all') query['type'] = type;
      if (tab != null && tab != 'all') query['tab'] = tab;
      if (startDate != null && startDate.isNotEmpty) query['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) query['end_date'] = endDate;
      if (search != null && search.isNotEmpty) query['q'] = search;
      query['limit'] = limit;

      final response = await _apiClient.get(ApiEndpoints.stockMovements, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockMovementsResult.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StockBatchesResult?> getStockBatches({
    int? productId,
    int? warehouseId,
    String? tab,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (productId != null) query['product_id'] = productId;
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (tab != null && tab != 'all') query['tab'] = tab;
      if (search != null && search.isNotEmpty) query['q'] = search;

      final response = await _apiClient.get(ApiEndpoints.stockBatches, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockBatchesResult.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ProductStockCardData?> getProductStockCard(int productId, {int? warehouseId}) async {
    try {
      final query = <String, dynamic>{};
      if (warehouseId != null) query['warehouse_id'] = warehouseId;

      final response = await _apiClient.get(ApiEndpoints.productStockCard(productId), queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return ProductStockCardData.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // STOK OPNAME & AUDIT INVENTARIS
  // =========================================================================

  Future<List<StockOpnameModel>> getStockOpnames({
    int? warehouseId,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (status != null && status != 'all') query['status'] = status;
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;
      if (search != null && search.isNotEmpty) query['q'] = search;

      final response = await _apiClient.get(ApiEndpoints.stockOpnames, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => StockOpnameModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<StockOpnameModel?> getStockOpnameDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.stockOpname(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockOpnameModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StockOpnameModel?> storeStockOpname(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.stockOpnames, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockOpnameModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StockOpnameModel?> updateStockOpname(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateStockOpname(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockOpnameModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StockOpnameModel?> approveStockOpname(int id) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.approveStockOpname(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockOpnameModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteStockOpname(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteStockOpname(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } catch (_) {
      return false;
    }
  }

  // ================= Stock Transfer Methods =================

  Future<List<StockTransferModel>> getStockTransfers({
    int? fromWarehouseId,
    int? toWarehouseId,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (fromWarehouseId != null) query['from_warehouse_id'] = fromWarehouseId;
      if (toWarehouseId != null) query['to_warehouse_id'] = toWarehouseId;
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (startDate != null && startDate.isNotEmpty) query['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) query['end_date'] = endDate;
      if (search != null && search.isNotEmpty) query['q'] = search;

      final response = await _apiClient.get(ApiEndpoints.stockTransfers, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => StockTransferModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<StockTransferModel?> getStockTransferDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.stockTransfer(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockTransferModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StockTransferModel?> storeStockTransfer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.stockTransfers, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockTransferModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal membuat dokumen transfer.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal membuat dokumen transfer.');
    }
  }

  Future<StockTransferModel?> dispatchStockTransfer(int id) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.dispatchStockTransfer(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockTransferModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal mengirim barang transfer.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal mengirim barang transfer.');
    }
  }

  Future<StockTransferModel?> receiveStockTransfer(int id, {List<Map<String, dynamic>>? items}) async {
    try {
      final data = <String, dynamic>{};
      if (items != null && items.isNotEmpty) {
        data['items'] = items;
      }
      final response = await _apiClient.post(ApiEndpoints.receiveStockTransfer(id), data: data.isNotEmpty ? data : null);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockTransferModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memproses penerimaan transfer.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal memproses penerimaan transfer.');
    }
  }

  Future<bool> deleteStockTransfer(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteStockTransfer(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal menghapus dokumen transfer.');
    }
  }

  // =========================================================================
  // PENYESUAIAN STOK (STOCK ADJUSTMENTS)
  // =========================================================================

  Future<List<StockAdjustmentModel>> getStockAdjustments({
    int? warehouseId,
    String? status,
    String? type,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (status != null && status != 'all') query['status'] = status;
      if (type != null && type != 'all') query['type'] = type;
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;
      if (search != null && search.isNotEmpty) query['q'] = search;

      final response = await _apiClient.get(ApiEndpoints.stockAdjustments, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => StockAdjustmentModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<StockAdjustmentModel?> getStockAdjustmentDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.stockAdjustment(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockAdjustmentModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StockAdjustmentModel?> storeStockAdjustment(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.stockAdjustments, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockAdjustmentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal membuat penyesuaian stok.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal membuat penyesuaian stok.');
    }
  }

  Future<StockAdjustmentModel?> updateStockAdjustment(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateStockAdjustment(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockAdjustmentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memperbarui penyesuaian stok.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal memperbarui penyesuaian stok.');
    }
  }

  Future<StockAdjustmentModel?> approveStockAdjustment(int id) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.approveStockAdjustment(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return StockAdjustmentModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal menyetujui penyesuaian stok.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal menyetujui penyesuaian stok.');
    }
  }

  Future<bool> deleteStockAdjustment(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteStockAdjustment(id));
      return response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Gagal menghapus penyesuaian stok.');
    }
  }

  // ==========================================
  // RETUR PENJUALAN (SALES RETURNS)
  // ==========================================
  Future<SaleReturnsResultModel?> getSaleReturns({
    String? search,
    String? status,
    int? warehouseId,
    String? refundMethod,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;
      if (status != null && status != 'all') query['status'] = status;
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (refundMethod != null && refundMethod != 'all') query['refund_method'] = refundMethod;
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;

      final response = await _apiClient.get(ApiEndpoints.saleReturns, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return SaleReturnsResultModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<SaleModel>> getSaleReturnInvoices({String? search}) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['q'] = search;

      final response = await _apiClient.get(ApiEndpoints.saleReturnInvoices, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final list = response.data['data'] as List;
        return list.map((item) => SaleModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<SaleReturnModel?> getSaleReturnDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.saleReturn(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return SaleReturnModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<SaleReturnModel?> storeSaleReturn(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.saleReturns, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return SaleReturnModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memproses retur penjualan');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ??
          (e.response?.data?['errors'] is List ? (e.response?.data?['errors'] as List).join(', ') : null);
      throw Exception(serverMsg ?? e.message ?? 'Gagal memproses retur penjualan');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<bool> deleteSaleReturn(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteSaleReturn(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return true;
      }
      throw Exception(response.data['message'] ?? 'Gagal membatalkan retur penjualan');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ?? e.message;
      throw Exception(serverMsg ?? 'Gagal membatalkan retur penjualan');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  // ==========================================
  // ARUS KAS (CASH FLOW - INFLOW & OUTFLOW)
  // ==========================================
  Future<CashFlowResponseData?> getCashFlows({
    String? search,
    String? type,
    int? accountId,
    String? category,
    String? startDate,
    String? endDate,
    int? page,
    int? perPage,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (type != null && type != 'all') query['type'] = type;
      if (accountId != null) query['account_id'] = accountId;
      if (category != null && category.isNotEmpty) query['category'] = category;
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;
      if (page != null) query['page'] = page;
      if (perPage != null) query['per_page'] = perPage;

      final response = await _apiClient.get(ApiEndpoints.cashFlows, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CashFlowResponseData.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, List<String>>> getCashFlowCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.cashFlowCategories);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'] as Map<String, dynamic>;
        final incomes = (data['income_categories'] as List? ?? []).map((e) => e.toString()).toList();
        final expenses = (data['expense_categories'] as List? ?? []).map((e) => e.toString()).toList();
        return {
          'income': incomes,
          'expense': expenses,
        };
      }
      return {'income': [], 'expense': []};
    } catch (_) {
      return {'income': [], 'expense': []};
    }
  }

  Future<CashFlowModel?> getCashFlowDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.cashFlow(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CashFlowModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CashFlowModel?> storeCashFlow(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.cashFlows, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CashFlowModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal mencatat arus kas');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ??
          (e.response?.data?['errors'] is List ? (e.response?.data?['errors'] as List).join(', ') : null);
      throw Exception(serverMsg ?? e.message ?? 'Gagal mencatat arus kas');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<CashFlowModel?> updateCashFlow(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.updateCashFlow(id), data: data);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return CashFlowModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memperbarui arus kas');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ??
          (e.response?.data?['errors'] is List ? (e.response?.data?['errors'] as List).join(', ') : null);
      throw Exception(serverMsg ?? e.message ?? 'Gagal memperbarui arus kas');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<bool> deleteCashFlow(int id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteCashFlow(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return true;
      }
      throw Exception(response.data['message'] ?? 'Gagal menghapus arus kas');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ?? e.message;
      throw Exception(serverMsg ?? 'Gagal menghapus arus kas');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  // ==========================================
  // TRANSFER KAS & BANK (ACCOUNT TRANSFERS)
  // ==========================================
  Future<AccountTransferResponseData?> getAccountTransfers({
    String? search,
    int? fromAccountId,
    int? toAccountId,
    String? startDate,
    String? endDate,
    int? page,
    int? perPage,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (fromAccountId != null) query['from_account_id'] = fromAccountId;
      if (toAccountId != null) query['to_account_id'] = toAccountId;
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;
      if (page != null) query['page'] = page;
      if (perPage != null) query['per_page'] = perPage;

      final response = await _apiClient.get(ApiEndpoints.accountTransfers, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return AccountTransferResponseData.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AccountTransferModel?> getAccountTransferDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.accountTransfer(id));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return AccountTransferModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AccountTransferModel?> storeAccountTransfer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.storeAccountTransfer, data: data);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return AccountTransferModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memproses transfer kas');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ??
          (e.response?.data?['errors'] is List ? (e.response?.data?['errors'] as List).join(', ') : null);
      throw Exception(serverMsg ?? e.message ?? 'Gagal memproses transfer kas');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }
}
