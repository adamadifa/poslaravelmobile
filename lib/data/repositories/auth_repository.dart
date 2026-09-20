import 'package:dio/dio.dart';
import 'package:poslaravelmobile/core/api/api_client.dart';
import 'package:poslaravelmobile/core/api/api_endpoints.dart';
import 'package:poslaravelmobile/data/models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        final data = response.data['data'];
        final user = UserModel.fromJson(data['user']);
        final token = data['token'] as String;
        return {
          'user': user,
          'token': token,
        };
      } else {
        throw Exception(response.data['message'] ?? 'Login gagal.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan jaringan.';
      throw Exception(msg);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);
      if (response.statusCode == 200 &&
          (response.data['success'] == true || response.data['status'] == 'success')) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengambil data user.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan jaringan.';
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore logout api failure, clear local token anyway
    }
  }
}
