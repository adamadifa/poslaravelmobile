class CategoryModel {
  final int id;
  final String name;
  final String? code;
  final String? slug;
  final String? icon;
  final int? parentId;
  final String? parentName;
  final String? description;
  final int productsCount;
  final bool isActive;
  final List<String> defaultNotes;

  CategoryModel({
    required this.id,
    required this.name,
    this.code,
    this.slug,
    this.icon,
    this.parentId,
    this.parentName,
    this.description,
    this.productsCount = 0,
    this.isActive = true,
    this.defaultNotes = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    List<String> notes = [];
    if (json['default_notes'] != null) {
      if (json['default_notes'] is List) {
        notes = (json['default_notes'] as List).map((e) => e.toString()).toList();
      } else if (json['default_notes'] is String) {
        notes = (json['default_notes'] as String).split(',').map((e) => e.trim()).toList();
      }
    }

    String? pName;
    if (json['parent'] != null && json['parent'] is Map<String, dynamic>) {
      pName = json['parent']['name']?.toString();
    }

    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? json['slug'],
      slug: json['slug']?.toString(),
      icon: json['icon']?.toString(),
      parentId: json['parent_id'] != null ? int.tryParse(json['parent_id'].toString()) : null,
      parentName: pName,
      description: json['description']?.toString(),
      productsCount: json['products_count'] != null ? int.tryParse(json['products_count'].toString()) ?? 0 : 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      defaultNotes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'slug': slug,
    'icon': icon,
    'parent_id': parentId,
    'description': description,
    'products_count': productsCount,
    'is_active': isActive,
    'default_notes': defaultNotes,
  };
}
