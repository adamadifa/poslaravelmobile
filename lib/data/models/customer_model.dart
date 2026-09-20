class CustomerModel {
  final int id;
  final String name;
  final String? code;
  final String? phone;
  final String? email;
  final String? city;
  final String? address;
  final int? customerGroupId;
  final String? groupName;
  final double discountPercent;
  final double creditLimit;
  final int loyaltyPoints;
  final bool isActive;

  CustomerModel({
    required this.id,
    required this.name,
    this.code,
    this.phone,
    this.email,
    this.city,
    this.address,
    this.customerGroupId,
    this.groupName,
    this.discountPercent = 0,
    this.creditLimit = 0,
    this.loyaltyPoints = 0,
    this.isActive = true,
  });

  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    String? gName;
    double disc = 0;
    if (json['group'] is Map<String, dynamic>) {
      gName = json['group']['name']?.toString();
      disc = double.tryParse(json['group']['discount_percent']?.toString() ?? '0') ?? 0;
    }

    return CustomerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      customerGroupId: json['customer_group_id'] != null
          ? int.tryParse(json['customer_group_id'].toString())
          : null,
      groupName: gName,
      discountPercent: disc,
      creditLimit: double.tryParse(json['credit_limit']?.toString() ?? '0') ?? 0,
      loyaltyPoints: int.tryParse(json['loyalty_points']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'phone': phone,
    'email': email,
    'city': city,
    'address': address,
    'customer_group_id': customerGroupId,
    'credit_limit': creditLimit,
    'is_active': isActive,
  };
}
