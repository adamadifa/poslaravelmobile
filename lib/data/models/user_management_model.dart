class StaffUserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final bool isActive;
  final String? avatar;
  final List<String> roles;
  final String primaryRole;
  final String createdAt;

  StaffUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.isActive,
    this.avatar,
    required this.roles,
    required this.primaryRole,
    required this.createdAt,
  });

  factory StaffUserModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'] as List? ?? [];
    final roleNames = rawRoles.map((r) {
      if (r is Map) return (r['name'] ?? '').toString();
      return r.toString();
    }).where((element) => element.isNotEmpty).toList();

    return StaffUserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '-',
      email: json['email'] ?? '-',
      phone: json['phone'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
      avatar: json['avatar'],
      roles: roleNames,
      primaryRole: roleNames.isNotEmpty ? roleNames.first : 'staff',
      createdAt: json['created_at'] != null ? json['created_at'].toString().split('T').first : '-',
    );
  }

  String get roleDisplay {
    switch (primaryRole.toLowerCase()) {
      case 'super_admin':
        return 'Super Admin';
      case 'owner':
        return 'Owner / Pemilik';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Kasir';
      default:
        return primaryRole.replaceAll('_', ' ').toUpperCase();
    }
  }
}

class RoleModel {
  final int id;
  final String name;
  final int usersCount;
  final List<String> permissions;

  RoleModel({
    required this.id,
    required this.name,
    required this.usersCount,
    required this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'] as List? ?? [];
    final permNames = rawPerms.map((p) {
      if (p is Map) return (p['name'] ?? '').toString();
      return p.toString();
    }).where((p) => p.isNotEmpty).toList();

    return RoleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '-',
      usersCount: (json['users_count'] as num?)?.toInt() ?? 0,
      permissions: permNames,
    );
  }

  String get displayName {
    switch (name.toLowerCase()) {
      case 'super_admin':
        return 'Super Administrator';
      case 'owner':
        return 'Owner / Pemilik Toko';
      case 'manager':
        return 'Store Manager';
      case 'cashier':
        return 'Kasir POS';
      default:
        return name.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool get isSuperAdmin => name.toLowerCase() == 'super_admin';
}

class PermissionModuleModel {
  final String name;
  final String icon;
  final String color;
  final Map<String, String> permissions;

  PermissionModuleModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.permissions,
  });

  factory PermissionModuleModel.fromMap(String name, Map<String, dynamic> map) {
    final rawPerms = map['permissions'] as Map<String, dynamic>? ?? {};
    final perms = rawPerms.map((k, v) => MapEntry(k, v.toString()));

    return PermissionModuleModel(
      name: name,
      icon: map['icon'] ?? 'settings',
      color: map['color'] ?? 'slate',
      permissions: perms,
    );
  }
}
