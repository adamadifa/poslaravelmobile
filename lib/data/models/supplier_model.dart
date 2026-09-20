class SupplierModel {
  final int id;
  final String? code;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? taxId;
  final int paymentTermDays;
  final bool isActive;

  SupplierModel({
    required this.id,
    this.code,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.taxId,
    this.paymentTermDays = 0,
    this.isActive = true,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? '',
      contactPerson: json['contact_person']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      taxId: json['tax_id']?.toString(),
      paymentTermDays: int.tryParse((json['payment_term_days'] ?? 0).toString()) ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'contact_person': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'tax_id': taxId,
        'payment_term_days': paymentTermDays,
        'is_active': isActive,
      };
}
