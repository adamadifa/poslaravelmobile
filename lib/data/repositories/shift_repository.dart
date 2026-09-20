import 'package:dio/dio.dart';
import 'package:poslaravelmobile/core/api/api_client.dart';
import 'package:poslaravelmobile/core/api/api_endpoints.dart';
import 'package:poslaravelmobile/data/models/shift_model.dart';

class ShiftRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ShiftModel?> getCurrentShift() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.currentShift);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        if (response.data['data'] != null) {
          return ShiftModel.fromJson(response.data['data']);
        }
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data shift aktif.');
    }
  }

  Future<ShiftModel> openShift({
    required int warehouseId,
    required double startingCash,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.openShift,
        data: {
          'warehouse_id': warehouseId,
          'starting_cash': startingCash,
          'notes': notes,
        },
      );
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return ShiftModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal membuka shift.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal membuka shift.');
    }
  }

  Future<ShiftModel> closeShift({
    required int shiftId,
    required double actualCash,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.closeShift(shiftId),
        data: {
          'actual_cash': actualCash,
          'notes': notes,
        },
      );
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return ShiftModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal menutup shift.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menutup shift.');
    }
  }

  Future<ShiftModel> addExpense({
    required int shiftId,
    required double amount,
    required String category,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.addExpense(shiftId),
        data: {
          'amount': amount,
          'category': category,
          'notes': notes,
        },
      );
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return ShiftModel.fromJson(response.data['data']['shift']);
      }
      throw Exception(response.data['message'] ?? 'Gagal mencatat pengeluaran.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mencatat pengeluaran.');
    }
  }

  Future<ShiftModel> deleteExpense({
    required int shiftId,
    required int expenseId,
  }) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteExpense(shiftId, expenseId));
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return ShiftModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal menghapus pengeluaran.');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menghapus pengeluaran.');
    }
  }
}
