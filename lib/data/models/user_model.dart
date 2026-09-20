class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatar;
  final int? defaultWarehouseId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar,
    this.defaultWarehouseId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String roleStr = 'cashier';
    if (json['role'] != null) {
      roleStr = json['role'].toString();
    } else if (json['roles'] != null && json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      roleStr = (json['roles'] as List).first.toString();
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: roleStr,
      avatar: json['avatar'],
      defaultWarehouseId: json['default_warehouse_id'] != null
          ? int.tryParse(json['default_warehouse_id'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'default_warehouse_id': defaultWarehouseId,
    };
  }
}
