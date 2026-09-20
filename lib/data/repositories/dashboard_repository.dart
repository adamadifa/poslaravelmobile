import 'package:dio/dio.dart';
import 'package:poslaravelmobile/core/api/api_client.dart';
import 'package:poslaravelmobile/core/api/api_endpoints.dart';
import 'package:poslaravelmobile/data/models/sale_model.dart';

class DashboardRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dashboardSummary);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Gagal memuat ringkasan dashboard.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat ringkasan dashboard.');
    }
  }

  Future<SalesHistoryResultModel?> getSalesHistory({
    int? warehouseId,
    String? paymentMethod,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    String? search,
    int perPage = 50,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (warehouseId != null) query['warehouse_id'] = warehouseId;
      if (paymentMethod != null && paymentMethod != 'all') query['payment_method'] = paymentMethod;
      if (paymentStatus != null && paymentStatus != 'all') query['payment_status'] = paymentStatus;
      if (startDate != null && startDate.isNotEmpty) query['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) query['end_date'] = endDate;
      if (search != null && search.isNotEmpty) query['search'] = search;
      query['per_page'] = perPage;

      final response = await _apiClient.get(ApiEndpoints.sales, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return SalesHistoryResultModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getSales({String? search}) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      final response = await _apiClient.get(ApiEndpoints.sales, queryParameters: query);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'];
        if (data is Map && data['sales'] != null) {
          final sData = data['sales'];
          if (sData is Map && sData['data'] is List) {
            return sData['data'] as List;
          }
        }
        if (data is Map && data['data'] is List) {
          return data['data'] as List;
        } else if (data is List) {
          return data;
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
