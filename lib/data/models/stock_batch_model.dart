import 'package:flutter/material.dart';
import 'package:poslaravelmobile/data/models/stock_movement_model.dart';

class StockBatchModel {
  final int id;
  final int productId;
  final String productName;
  final String? productCode;
  final String unitName;
  final int warehouseId;
  final String warehouseName;
  final int? purchaseReceiptItemId;
  final String batchNumber;
  final String? expiryDate;
  final String entryDate;
  final double qtyIn;
  final double qtyRemaining;
  final double unitCost;

  StockBatchModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productCode,
    required this.unitName,
    required this.warehouseId,
    required this.warehouseName,
    this.purchaseReceiptItemId,
    required this.batchNumber,
    this.expiryDate,
    required this.entryDate,
    required this.qtyIn,
    required this.qtyRemaining,
    required this.unitCost,
  });

  factory StockBatchModel.fromJson(Map<String, dynamic> json) {
    String pName = 'Produk #${json['product_id']}';
    String? pCode;
    String uName = 'Pcs';

    if (json['product'] != null && json['product'] is Map) {
      pName = json['product']['name']?.toString() ?? pName;
      pCode = json['product']['code']?.toString();

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

    return StockBatchModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      productCode: pCode,
      unitName: uName,
      warehouseId: int.tryParse(json['warehouse_id']?.toString() ?? '0') ?? 0,
      warehouseName: wName,
      purchaseReceiptItemId: json['purchase_receipt_item_id'] != null
          ? int.tryParse(json['purchase_receipt_item_id'].toString())
          : null,
      batchNumber: json['batch_number']?.toString() ?? 'BATCH-000',
      expiryDate: json['expiry_date']?.toString(),
      entryDate: json['entry_date']?.toString() ?? '',
      qtyIn: double.tryParse(json['qty_in']?.toString() ?? '0') ?? 0,
      qtyRemaining: double.tryParse(json['qty_remaining']?.toString() ?? '0') ?? 0,
      unitCost: double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0,
    );
  }

  double get totalValuation => qtyRemaining * unitCost;

  double get consumedQty => qtyIn >= qtyRemaining ? (qtyIn - qtyRemaining) : 0;

  double get remainingRatio => qtyIn > 0 ? (qtyRemaining / qtyIn) : 0;

  bool get isExpired {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    try {
      final exp = DateTime.parse(expiryDate!);
      return exp.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool get isExpiringSoon {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    try {
      final exp = DateTime.parse(expiryDate!);
      final now = DateTime.now();
      final diff = exp.difference(now).inDays;
      return diff >= 0 && diff <= 30;
    } catch (_) {
      return false;
    }
  }

  Color get expiryBadgeColor {
    if (isExpired) return const Color(0xFFDC2626);
    if (isExpiringSoon) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  Color get expiryBadgeBgColor {
    if (isExpired) return const Color(0xFFFEE2E2);
    if (isExpiringSoon) return const Color(0xFFFEF3C7);
    return const Color(0xFFECFDF5);
  }

  String get expiryStatusLabel {
    if (expiryDate == null || expiryDate!.isEmpty) return 'Tanpa Exp';
    if (isExpired) return 'Kadaluarsa ($expiryDate)';
    if (isExpiringSoon) return 'Segera Exp ($expiryDate)';
    return 'Exp: $expiryDate';
  }
}

class StockBatchesResult {
  final List<StockBatchModel> batches;
  final double totalStock;
  final double totalValuation;
  final int totalBatchesCount;

  StockBatchesResult({
    required this.batches,
    required this.totalStock,
    required this.totalValuation,
    required this.totalBatchesCount,
  });

  factory StockBatchesResult.fromJson(Map<String, dynamic> json) {
    List<StockBatchModel> list = [];
    if (json['batches'] != null && json['batches'] is List) {
      for (var item in json['batches']) {
        if (item is Map<String, dynamic>) {
          list.add(StockBatchModel.fromJson(item));
        }
      }
    }

    return StockBatchesResult(
      batches: list,
      totalStock: double.tryParse(json['total_stock']?.toString() ?? '0') ?? 0,
      totalValuation: double.tryParse(json['total_valuation']?.toString() ?? '0') ?? 0,
      totalBatchesCount: int.tryParse(json['total_batches_count']?.toString() ?? '0') ?? list.length,
    );
  }
}

class WarehouseStockModel {
  final int warehouseId;
  final String warehouseName;
  final double quantity;

  WarehouseStockModel({
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
  });

  factory WarehouseStockModel.fromJson(Map<String, dynamic> json) {
    String wName = 'Gudang';
    if (json['warehouse'] != null && json['warehouse'] is Map) {
      wName = json['warehouse']['name']?.toString() ?? wName;
    }
    return WarehouseStockModel(
      warehouseId: int.tryParse(json['warehouse_id']?.toString() ?? '0') ?? 0,
      warehouseName: wName,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    );
  }
}

class ProductStockCardData {
  final int productId;
  final String productName;
  final String unitName;
  final double totalStock;
  final List<WarehouseStockModel> stocksByWarehouse;
  final List<StockBatchModel> fifoBatches;
  final List<StockMovementModel> recentMovements;

  ProductStockCardData({
    required this.productId,
    required this.productName,
    this.unitName = 'Pcs',
    required this.totalStock,
    required this.stocksByWarehouse,
    required this.fifoBatches,
    required this.recentMovements,
  });

  factory ProductStockCardData.fromJson(Map<String, dynamic> json) {
    String pName = 'Produk';
    String uName = 'Pcs';
    int pId = 0;
    if (json['product'] != null && json['product'] is Map) {
      pName = json['product']['name']?.toString() ?? pName;
      pId = int.tryParse(json['product']['id']?.toString() ?? '0') ?? 0;
      if (json['product']['base_unit'] != null && json['product']['base_unit'] is Map) {
        uName = json['product']['base_unit']['short_name']?.toString() ??
            json['product']['base_unit']['name']?.toString() ??
            uName;
      }
    }

    List<WarehouseStockModel> stocksList = [];
    if (json['stocks_by_warehouse'] != null && json['stocks_by_warehouse'] is List) {
      for (var s in json['stocks_by_warehouse']) {
        if (s is Map<String, dynamic>) {
          stocksList.add(WarehouseStockModel.fromJson(s));
        }
      }
    }

    List<StockBatchModel> bList = [];
    if (json['fifo_batches'] != null && json['fifo_batches'] is List) {
      for (var b in json['fifo_batches']) {
        if (b is Map<String, dynamic>) {
          bList.add(StockBatchModel.fromJson(b));
        }
      }
    }

    List<StockMovementModel> mList = [];
    if (json['recent_movements'] != null && json['recent_movements'] is List) {
      for (var m in json['recent_movements']) {
        if (m is Map<String, dynamic>) {
          mList.add(StockMovementModel.fromJson(m));
        }
      }
    }

    return ProductStockCardData(
      productId: pId,
      productName: pName,
      unitName: uName,
      totalStock: double.tryParse(json['total_stock']?.toString() ?? '0') ?? 0,
      stocksByWarehouse: stocksList,
      fifoBatches: bList,
      recentMovements: mList,
    );
  }
}
