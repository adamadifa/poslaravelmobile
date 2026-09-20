import 'package:flutter/material.dart';

class StockMovementModel {
  final int id;
  final int productId;
  final String productName;
  final String? productCode;
  final String? productType;
  final String unitName;
  final int warehouseId;
  final String warehouseName;
  final String referenceType;
  final int? referenceId;
  final String type; // 'in' or 'out'
  final double quantity;
  final double unitCost;
  final double beforeStock;
  final double afterStock;
  final String? description;
  final String? creatorName;
  final String createdAt;

  StockMovementModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productCode,
    this.productType,
    required this.unitName,
    required this.warehouseId,
    required this.warehouseName,
    required this.referenceType,
    this.referenceId,
    required this.type,
    required this.quantity,
    required this.unitCost,
    required this.beforeStock,
    required this.afterStock,
    this.description,
    this.creatorName,
    required this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    String pName = 'Produk #${json['product_id']}';
    String? pCode;
    String? pType;
    String uName = 'Pcs';

    if (json['product'] != null && json['product'] is Map) {
      pName = json['product']['name']?.toString() ?? pName;
      pCode = json['product']['code']?.toString();
      pType = json['product']['product_type']?.toString();

      if (json['product']['base_unit'] != null && json['product']['base_unit'] is Map) {
        uName = json['product']['base_unit']['short_name']?.toString() ??
            json['product']['base_unit']['name']?.toString() ??
            uName;
      }
    }

    String wName = 'Gudang #${json['warehouse_id']}';
    if (json['warehouse'] != null && json['warehouse'] is Map) {
      wName = json['warehouse']['name']?.toString() ?? wName;
    }

    String? cName;
    if (json['creator'] != null && json['creator'] is Map) {
      cName = json['creator']['name']?.toString();
    }

    return StockMovementModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      productCode: pCode,
      productType: pType,
      unitName: uName,
      warehouseId: int.tryParse(json['warehouse_id']?.toString() ?? '0') ?? 0,
      warehouseName: wName,
      referenceType: json['reference_type']?.toString() ?? '-',
      referenceId: json['reference_id'] != null ? int.tryParse(json['reference_id'].toString()) : null,
      type: (json['type']?.toString().toLowerCase() == 'out') ? 'out' : 'in',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      unitCost: double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0,
      beforeStock: double.tryParse(json['before_stock']?.toString() ?? '0') ?? 0,
      afterStock: double.tryParse(json['after_stock']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString(),
      creatorName: cName,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  bool get isIncoming => type == 'in';

  String get typeLabel => isIncoming ? 'Masuk' : 'Keluar';

  Color get typeColor => isIncoming ? const Color(0xFF059669) : const Color(0xFFDC2626);

  Color get typeBgColor => isIncoming ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2);

  String get referenceTypeLabel {
    switch (referenceType) {
      case 'Sale':
      case 'PosSale':
        return 'Penjualan Kasir';
      case 'PurchaseReceipt':
        return 'Penerimaan (GRN)';
      case 'PurchaseReturn':
        return 'Retur Pembelian';
      case 'StockAdjustment':
      case 'Adjustment':
        return 'Penyesuaian Stok';
      case 'StockTransfer':
      case 'Transfer':
        return 'Transfer Gudang';
      case 'Production':
      case 'BOM':
        return 'Produksi / Resep';
      case 'Opname':
        return 'Stock Opname';
      default:
        return referenceType;
    }
  }

  IconData get referenceIcon {
    switch (referenceType) {
      case 'Sale':
      case 'PosSale':
        return Icons.shopping_cart_outlined;
      case 'PurchaseReceipt':
        return Icons.inventory_2_outlined;
      case 'PurchaseReturn':
        return Icons.keyboard_return_outlined;
      case 'StockAdjustment':
      case 'Adjustment':
        return Icons.tune_outlined;
      case 'StockTransfer':
      case 'Transfer':
        return Icons.swap_horiz_outlined;
      case 'Production':
      case 'BOM':
        return Icons.restaurant_outlined;
      default:
        return Icons.history_outlined;
    }
  }
}

class StockMovementSummaryModel {
  final double totalIn;
  final double totalOut;
  final double? currentStock;
  final int movementsCount;

  StockMovementSummaryModel({
    required this.totalIn,
    required this.totalOut,
    this.currentStock,
    required this.movementsCount,
  });

  factory StockMovementSummaryModel.fromJson(Map<String, dynamic> json) {
    return StockMovementSummaryModel(
      totalIn: double.tryParse(json['total_in']?.toString() ?? '0') ?? 0,
      totalOut: double.tryParse(json['total_out']?.toString() ?? '0') ?? 0,
      currentStock: json['current_stock'] != null ? double.tryParse(json['current_stock'].toString()) : null,
      movementsCount: int.tryParse(json['movements_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class StockMovementsResult {
  final List<StockMovementModel> movements;
  final StockMovementSummaryModel summary;

  StockMovementsResult({
    required this.movements,
    required this.summary,
  });

  factory StockMovementsResult.fromJson(Map<String, dynamic> json) {
    List<StockMovementModel> list = [];
    if (json['movements'] != null && json['movements'] is List) {
      for (var item in json['movements']) {
        if (item is Map<String, dynamic>) {
          list.add(StockMovementModel.fromJson(item));
        }
      }
    }

    StockMovementSummaryModel sum = StockMovementSummaryModel(
      totalIn: 0,
      totalOut: 0,
      movementsCount: list.length,
    );
    if (json['summary'] != null && json['summary'] is Map<String, dynamic>) {
      sum = StockMovementSummaryModel.fromJson(json['summary']);
    }

    return StockMovementsResult(
      movements: list,
      summary: sum,
    );
  }
}
