import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poslaravelmobile/data/models/user_model.dart';
import 'package:poslaravelmobile/data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _errorMessage;
  String _serverUrl = 'http://127.0.0.1:8000/api/v1';

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  String get serverUrl => _serverUrl;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _token != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _serverUrl = prefs.getString('server_base_url') ?? _serverUrl;

    if (_token != null && _token!.isNotEmpty) {
      try {
        _status = AuthStatus.authenticating;
        notifyListeners();
        _user = await _authRepository.getMe();
        _status = AuthStatus.authenticated;
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        _token = null;
        await prefs.remove('auth_token');
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> setServerUrl(String newUrl) async {
    String formatted = newUrl.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (!formatted.endsWith('/api/v1')) {
      if (formatted.endsWith('/')) {
        formatted = '${formatted}api/v1';
      } else {
        formatted = '$formatted/api/v1';
      }
    }

    _serverUrl = formatted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_base_url', _serverUrl);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.login(email, password);
      _user = result['user'] as UserModel;
      _token = result['token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
