import 'package:poslaravelmobile/data/models/modifier_group_model.dart';
import 'package:poslaravelmobile/data/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  double qty;
  double unitPrice;
  double discountAmount;
  String? notes;
  int? unitId;
  String? unitName;
  int? variantId;
  String? variantName;
  List<ModifierItemModel> selectedModifiers;

  CartItemModel({
    required this.product,
    this.qty = 1.0,
    double? unitPrice,
    this.discountAmount = 0.0,
    this.notes,
    int? unitId,
    String? unitName,
    this.variantId,
    this.variantName,
    List<ModifierItemModel>? selectedModifiers,
  })  : unitPrice = unitPrice ?? product.sellingPrice,
        unitId = unitId ?? product.baseUnitId ?? 1,
        unitName = unitName ?? product.unitName,
        selectedModifiers = selectedModifiers ?? [];

  double get modifiersExtraTotal =>
      selectedModifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);

  double get effectiveUnitPrice => unitPrice + modifiersExtraTotal;

  double get subtotal => (effectiveUnitPrice * qty) - discountAmount;

  Map<String, dynamic> toApiCheckoutItem() {
    return {
      'product_id': product.id,
      'unit_id': unitId ?? product.baseUnitId ?? 1,
      'quantity': qty,
      'price': effectiveUnitPrice,
      'unit_price': effectiveUnitPrice,
      'discount': discountAmount,
      'notes': notes,
      if (selectedModifiers.isNotEmpty)
        'modifiers': selectedModifiers.map((m) => m.toApiCheckout()).toList(),
    };
  }

  CartItemModel copyWith({
    ProductModel? product,
    double? qty,
    double? unitPrice,
    double? discountAmount,
    String? notes,
    int? unitId,
    String? unitName,
    int? variantId,
    String? variantName,
    List<ModifierItemModel>? selectedModifiers,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      notes: notes ?? this.notes,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      selectedModifiers: selectedModifiers ?? List.from(this.selectedModifiers),
    );
  }
}

