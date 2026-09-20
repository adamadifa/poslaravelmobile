import 'package:flutter/foundation.dart';
import 'package:poslaravelmobile/data/models/user_management_model.dart';
import 'package:poslaravelmobile/data/repositories/pos_repository.dart';

class StaffProvider with ChangeNotifier {
  final PosRepository _posRepository = PosRepository();

  // Users State
  List<StaffUserModel> _users = [];
  List<StaffUserModel> get users => _users;

  bool _isLoadingUsers = false;
  bool get isLoadingUsers => _isLoadingUsers;

  String? _searchQuery;
  String? get searchQuery => _searchQuery;

  String? _selectedRoleFilter;
  String? get selectedRoleFilter => _selectedRoleFilter;

  // Roles & Permissions State
  List<RoleModel> _roles = [];
  List<RoleModel> get roles => _roles;

  List<PermissionModuleModel> _permissionModules = [];
  List<PermissionModuleModel> get permissionModules => _permissionModules;

  int _totalPermissionsCount = 0;
  int get totalPermissionsCount => _totalPermissionsCount;

  bool _isLoadingRoles = false;
  bool get isLoadingRoles => _isLoadingRoles;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filters & Actions
  void setSearchQuery(String? query) {
    _searchQuery = query;
    fetchUsers();
  }

  void setRoleFilter(String? role) {
    _selectedRoleFilter = role;
    fetchUsers();
  }

  Future<void> fetchAllData() async {
    await Future.wait([
      fetchUsers(),
      fetchRoles(),
    ]);
  }

  Future<void> fetchUsers() async {
    _isLoadingUsers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _posRepository.getUsers(
        search: _searchQuery,
        role: _selectedRoleFilter,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> storeUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    bool isActive = true,
  }) async {
    _errorMessage = null;
    try {
      final newUser = await _posRepository.storeUser({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
        'is_active': isActive ? 1 : 0,
      });
      _users.insert(0, newUser);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser({
    required int id,
    required String name,
    required String email,
    String? password,
    required String role,
    String? phone,
    bool isActive = true,
  }) async {
    _errorMessage = null;
    try {
      final data = <String, dynamic>{
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'is_active': isActive ? 1 : 0,
      };
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }

      final updated = await _posRepository.updateUser(id, data);
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    _errorMessage = null;
    try {
      await _posRepository.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchRoles() async {
    _isLoadingRoles = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _posRepository.getRoles();
      _roles = res['roles'] as List<RoleModel>;
      _permissionModules = res['permission_modules'] as List<PermissionModuleModel>;
      _totalPermissionsCount = res['total_permissions_count'] as int? ?? 0;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingRoles = false;
      notifyListeners();
    }
  }

  Future<bool> storeRole(String name, List<String> permissions) async {
    _errorMessage = null;
    try {
      final newRole = await _posRepository.storeRole(name, permissions);
      _roles.add(newRole);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRole(int id, String name, List<String> permissions) async {
    _errorMessage = null;
    try {
      final updated = await _posRepository.updateRole(id, name, permissions);
      final index = _roles.indexWhere((r) => r.id == id);
      if (index != -1) {
        _roles[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRole(int id) async {
    _errorMessage = null;
    try {
      await _posRepository.deleteRole(id);
      _roles.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
