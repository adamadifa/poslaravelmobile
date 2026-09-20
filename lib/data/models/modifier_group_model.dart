class ModifierItemModel {
  final int id;
  final int modifierGroupId;
  final String name;
  final double priceAdjustment;
  final bool isDefault;

  ModifierItemModel({
    required this.id,
    required this.modifierGroupId,
    required this.name,
    this.priceAdjustment = 0.0,
    this.isDefault = false,
  });

  factory ModifierItemModel.fromJson(Map<String, dynamic> json) {
    return ModifierItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      modifierGroupId: json['modifier_group_id'] is int
          ? json['modifier_group_id']
          : int.tryParse(json['modifier_group_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      priceAdjustment: double.tryParse((json['price_adjustment'] ?? 0).toString()) ?? 0.0,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'modifier_group_id': modifierGroupId,
    'name': name,
    'price_adjustment': priceAdjustment,
    'is_default': isDefault,
  };

  Map<String, dynamic> toApiCheckout() => {
    'id': id,
    'name': name,
    'price_adjustment': priceAdjustment,
  };
}

class ModifierGroupModel {
  final int id;
  final String name;
  final String selectionType; // 'single' or 'multiple'
  final bool isRequired;
  final int minSelections;
  final int maxSelections;
  final List<ModifierItemModel> modifiers;

  ModifierGroupModel({
    required this.id,
    required this.name,
    this.selectionType = 'multiple',
    this.isRequired = false,
    this.minSelections = 0,
    this.maxSelections = 0,
    this.modifiers = const [],
  });

  factory ModifierGroupModel.fromJson(Map<String, dynamic> json) {
    final rawMods = json['modifiers'];
    List<ModifierItemModel> modList = [];
    if (rawMods != null && rawMods is List) {
      modList = rawMods
          .map((m) => ModifierItemModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return ModifierGroupModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      selectionType: json['selection_type']?.toString() ?? 'multiple',
      isRequired: json['is_required'] == true || json['is_required'] == 1,
      minSelections: int.tryParse((json['min_selections'] ?? 0).toString()) ?? 0,
      maxSelections: int.tryParse((json['max_selections'] ?? 0).toString()) ?? 0,
      modifiers: modList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'selection_type': selectionType,
    'is_required': isRequired,
    'min_selections': minSelections,
    'max_selections': maxSelections,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
  };
}
