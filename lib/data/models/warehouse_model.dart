class WarehouseModel {
  final int id;
  final String? code;
  final String name;
  final String? address;
  final String? phone;
  final bool isDefault;
  final bool isActive;

  WarehouseModel({
    required this.id,
    this.code,
    required this.name,
    this.address,
    this.phone,
    this.isDefault = false,
    this.isActive = true,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'address': address,
        'phone': phone,
        'is_default': isDefault,
        'is_active': isActive,
      };
}
