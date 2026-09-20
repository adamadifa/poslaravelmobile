import 'package:poslaravelmobile/data/models/category_model.dart';
import 'package:poslaravelmobile/data/models/modifier_group_model.dart';

class ProductUnitOption {
  final int id;
  final String name;
  final String? shortName;
  final double ratio;

  ProductUnitOption({
    required this.id,
    required this.name,
    this.shortName,
    this.ratio = 1.0,
  });

  factory ProductUnitOption.fromJson(Map<String, dynamic> json) {
    return ProductUnitOption(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      shortName: json['short_name']?.toString(),
      ratio: double.tryParse((json['ratio'] ?? json['conversion_value'] ?? 1.0).toString()) ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'ratio': ratio,
      };
}

class ProductBarcodeItem {
  final int? id;
  final int unitId;
  final String barcode;
  final String? unitName;

  ProductBarcodeItem({
    this.id,
    required this.unitId,
    required this.barcode,
    this.unitName,
  });

  factory ProductBarcodeItem.fromJson(Map<String, dynamic> json) {
    return ProductBarcodeItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      unitId: int.tryParse(json['unit_id']?.toString() ?? '0') ?? 0,
      barcode: json['barcode']?.toString() ?? '',
      unitName: json['unit']?['name']?.toString() ?? json['unit_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'unit_id': unitId,
        'barcode': barcode,
      };
}

class ProductConversionItem {
  final int? id;
  final int fromUnitId;
  final int toUnitId;
  final double conversionValue;
  final String? fromUnitName;
  final String? toUnitName;

  ProductConversionItem({
    this.id,
    required this.fromUnitId,
    required this.toUnitId,
    required this.conversionValue,
    this.fromUnitName,
    this.toUnitName,
  });

  factory ProductConversionItem.fromJson(Map<String, dynamic> json) {
    return ProductConversionItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      fromUnitId: int.tryParse((json['from_unit_id'] ?? json['fromUnit']?['id'])?.toString() ?? '0') ?? 0,
      toUnitId: int.tryParse((json['to_unit_id'] ?? json['toUnit']?['id'])?.toString() ?? '0') ?? 0,
      conversionValue: double.tryParse((json['conversion_value'] ?? 1.0).toString()) ?? 1.0,
      fromUnitName: json['from_unit']?['name']?.toString() ?? json['fromUnit']?['name']?.toString(),
      toUnitName: json['to_unit']?['name']?.toString() ?? json['toUnit']?['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'from_unit_id': fromUnitId,
        'to_unit_id': toUnitId,
        'conversion_value': conversionValue,
      };
}

class ProductTieredPriceItem {
  final int? id;
  final int unitId;
  final int? customerGroupId;
  final double minQty;
  final double? maxQty;
  final double price;
  final String? unitName;
  final String? customerGroupName;

  ProductTieredPriceItem({
    this.id,
    required this.unitId,
    this.customerGroupId,
    required this.minQty,
    this.maxQty,
    required this.price,
    this.unitName,
    this.customerGroupName,
  });

  factory ProductTieredPriceItem.fromJson(Map<String, dynamic> json) {
    return ProductTieredPriceItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      unitId: int.tryParse((json['unit_id'] ?? json['unit']?['id'])?.toString() ?? '0') ?? 0,
      customerGroupId: json['customer_group_id'] != null
          ? int.tryParse(json['customer_group_id'].toString())
          : null,
      minQty: double.tryParse((json['min_qty'] ?? 1).toString()) ?? 1.0,
      maxQty: json['max_qty'] != null ? double.tryParse(json['max_qty'].toString()) : null,
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      unitName: json['unit']?['name']?.toString() ?? json['unit_name']?.toString(),
      customerGroupName: json['customer_group']?['name']?.toString() ?? json['customer_group_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'unit_id': unitId,
        if (customerGroupId != null) 'customer_group_id': customerGroupId,
        'min_qty': minQty,
        if (maxQty != null) 'max_qty': maxQty,
        'price': price,
      };
}

class ProductModel {
  final int id;
  final String name;
  final String? code;
  final String? barcode;
  final int? categoryId;
  final CategoryModel? category;
  final double costPrice;
  final double sellingPrice;
  final double stock;
  final int? baseUnitId;
  final String? unitName;
  final String? image;
  final bool hasVariants;
  final List<ModifierGroupModel> modifierGroups;
  final List<String> defaultNotes;
  final List<ProductUnitOption> availableUnits;
  final List<ProductBarcodeItem>? _barcodes;
  final List<ProductConversionItem>? _conversions;
  final List<ProductTieredPriceItem>? _tieredPrices;

  List<ProductBarcodeItem> get barcodes => _barcodes ?? const [];
  List<ProductConversionItem> get conversions => _conversions ?? const [];
  List<ProductTieredPriceItem> get tieredPrices => _tieredPrices ?? const [];

  ProductModel({
    required this.id,
    required this.name,
    this.code,
    this.barcode,
    this.categoryId,
    this.category,
    required this.costPrice,
    required this.sellingPrice,
    this.stock = 0.0,
    this.baseUnitId,
    this.unitName,
    this.image,
    this.hasVariants = false,
    this.modifierGroups = const [],
    this.defaultNotes = const [],
    this.availableUnits = const [],
    List<ProductBarcodeItem>? barcodes,
    List<ProductConversionItem>? conversions,
    List<ProductTieredPriceItem>? tieredPrices,
  })  : _barcodes = barcodes,
        _conversions = conversions,
        _tieredPrices = tieredPrices;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parsing category
    CategoryModel? cat;
    if (json['category'] != null && json['category'] is Map<String, dynamic>) {
      cat = CategoryModel.fromJson(json['category']);
    }

    // Parsing unit
    int? unitId;
    String? unit;
    if (json['base_unit'] != null && json['base_unit'] is Map<String, dynamic>) {
      unitId = int.tryParse(json['base_unit']['id']?.toString() ?? '');
      unit = json['base_unit']['name'] ?? json['base_unit']['code'];
    } else if (json['unit'] != null && json['unit'] is Map<String, dynamic>) {
      unitId = int.tryParse(json['unit']['id']?.toString() ?? '');
      unit = json['unit']['name'] ?? json['unit']['code'];
    } else if (json['base_unit_id'] != null) {
      unitId = int.tryParse(json['base_unit_id'].toString());
    } else if (json['unit_id'] != null) {
      unitId = int.tryParse(json['unit_id'].toString());
    }
    unitId ??= 1; // Fallback to primary unit

    if (json['unit_name'] != null && unit == null) {
      unit = json['unit_name'].toString();
    }

    // Parsing modifier groups
    List<ModifierGroupModel> modGroups = [];
    final rawModGroups = json['modifier_groups'] ?? json['modifierGroups'];
    if (rawModGroups != null && rawModGroups is List) {
      modGroups = rawModGroups
          .whereType<Map<String, dynamic>>()
          .map((g) => ModifierGroupModel.fromJson(g))
          .toList();
    }

    // Parsing default notes
    List<String> prodNotes = [];
    if (json['default_notes'] != null) {
      if (json['default_notes'] is List) {
        prodNotes = (json['default_notes'] as List).map((e) => e.toString()).toList();
      } else if (json['default_notes'] is String) {
        prodNotes = (json['default_notes'] as String).split(',').map((e) => e.trim()).toList();
      }
    }

    // Parsing Multi-Barcodes
    final List<ProductBarcodeItem> barcodesList = [];
    if (json['barcodes'] != null && json['barcodes'] is List) {
      for (final b in json['barcodes']) {
        if (b is Map<String, dynamic>) {
          barcodesList.add(ProductBarcodeItem.fromJson(b));
        }
      }
    }

    // Parsing Unit Conversions
    final List<ProductConversionItem> conversionsList = [];
    if (json['conversions'] != null && json['conversions'] is List) {
      for (final c in json['conversions']) {
        if (c is Map<String, dynamic>) {
          conversionsList.add(ProductConversionItem.fromJson(c));
        }
      }
    }

    // Parsing Tiered Prices
    final List<ProductTieredPriceItem> tieredPricesList = [];
    final rawTiered = json['tiered_prices'] ?? json['tieredPrices'];
    if (rawTiered != null && rawTiered is List) {
      for (final tp in rawTiered) {
        if (tp is Map<String, dynamic>) {
          tieredPricesList.add(ProductTieredPriceItem.fromJson(tp));
        }
      }
    }

    // Parsing available units (Base Unit + Conversions)
    final List<ProductUnitOption> unitsList = [];
    final seenUnitIds = <int>{};

    // 1. Add base unit
    if (unitId > 0) {
      unitsList.add(
        ProductUnitOption(
          id: unitId,
          name: unit ?? 'Pcs',
          shortName: unit ?? 'pcs',
          ratio: 1.0,
        ),
      );
      seenUnitIds.add(unitId);
    }

    // 2. Add converted units from conversions
    for (final conv in conversionsList) {
      if (conv.fromUnitId > 0 && !seenUnitIds.contains(conv.fromUnitId)) {
        final fromName = conv.fromUnitName ?? 'Satuan ${conv.fromUnitId}';
        unitsList.add(
          ProductUnitOption(
            id: conv.fromUnitId,
            name: fromName,
            shortName: fromName,
            ratio: conv.conversionValue,
          ),
        );
        seenUnitIds.add(conv.fromUnitId);
      }
    }

    // Parse stock (sum from stocks relation if present, or from stock / total_stock)
    double parsedStock = 0.0;
    if (json['stocks'] != null && json['stocks'] is List) {
      final stocksList = json['stocks'] as List;
      for (final s in stocksList) {
        if (s is Map<String, dynamic>) {
          parsedStock += double.tryParse((s['quantity'] ?? s['stock'] ?? 0).toString()) ?? 0.0;
        }
      }
    } else {
      parsedStock = double.tryParse((json['stock'] ?? json['total_stock'] ?? 0).toString()) ?? 0.0;
    }

    return ProductModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
      barcode: json['barcode'],
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      category: cat,
      costPrice: double.tryParse((json['cost_price'] ?? json['purchase_price'] ?? 0).toString()) ?? 0.0,
      sellingPrice: double.tryParse((json['selling_price'] ?? 0).toString()) ?? 0.0,
      stock: parsedStock,
      baseUnitId: unitId,
      unitName: unit,
      image: json['image'] ?? json['image_url'],
      hasVariants: json['has_variants'] == true || json['has_variants'] == 1,
      modifierGroups: modGroups,
      defaultNotes: prodNotes,
      availableUnits: unitsList,
      barcodes: barcodesList,
      conversions: conversionsList,
      tieredPrices: tieredPricesList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'barcode': barcode,
    'category_id': categoryId,
    'category': category?.toJson(),
    'cost_price': costPrice,
    'selling_price': sellingPrice,
    'stock': stock,
    'unit_name': unitName,
    'image': image,
    'has_variants': hasVariants,
    'modifier_groups': modifierGroups.map((g) => g.toJson()).toList(),
    'default_notes': defaultNotes,
    'available_units': availableUnits.map((u) => u.toJson()).toList(),
    'barcodes': barcodes.map((b) => b.toJson()).toList(),
    'conversions': conversions.map((c) => c.toJson()).toList(),
    'tiered_prices': tieredPrices.map((t) => t.toJson()).toList(),
  };
}
