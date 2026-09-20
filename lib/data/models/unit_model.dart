class UnitModel {
  final int id;
  final String name;
  final String? shortName;
  final int productsCount;
  final bool isActive;

  UnitModel({
    required this.id,
    required this.name,
    this.shortName,
    this.productsCount = 0,
    this.isActive = true,
  });

  String get displayName {
    if (shortName != null &&
        shortName!.trim().isNotEmpty &&
        shortName!.trim().toLowerCase() != name.trim().toLowerCase()) {
      return '$name ($shortName)';
    }
    return name;
  }

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      shortName: json['short_name']?.toString(),
      productsCount: json['products_count'] != null ? int.tryParse(json['products_count'].toString()) ?? 0 : 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'products_count': productsCount,
        'is_active': isActive,
      };
}
