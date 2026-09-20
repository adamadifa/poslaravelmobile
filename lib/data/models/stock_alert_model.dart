import 'package:poslaravelmobile/data/models/stock_batch_model.dart';

class LowStockItemModel {
  final int id;
  final String name;
  final String? code;
  final String? barcode;
  final String? productType;
  final String? categoryName;
  final String unitName;
  final double currentStock;
  final double minStock;
  final double deficit;
  final double stockPercentage;
  final bool isOutOfStock;
  final double costPrice;
  final double sellingPrice;

  LowStockItemModel({
    required this.id,
    required this.name,
    this.code,
    this.barcode,
    this.productType,
    this.categoryName,
    required this.unitName,
    required this.currentStock,
    required this.minStock,
    required this.deficit,
    required this.stockPercentage,
    required this.isOutOfStock,
    required this.costPrice,
    required this.sellingPrice,
  });

  factory LowStockItemModel.fromJson(Map<String, dynamic> json) {
    final cur = double.tryParse((json['current_stock'] ?? json['stock'] ?? 0).toString()) ?? 0.0;
    final min = double.tryParse((json['min_stock'] ?? 0).toString()) ?? 0.0;
    final def = double.tryParse((json['deficit'] ?? (min - cur > 0 ? min - cur : 0)).toString()) ?? 0.0;
    final pct = double.tryParse((json['stock_percentage'] ?? (min > 0 ? (cur / min) * 100 : 0)).toString()) ?? 0.0;

    String uName = 'Pcs';
    if (json['base_unit'] != null && json['base_unit'] is Map<String, dynamic>) {
      uName = json['base_unit']['name'] ?? json['base_unit']['code'] ?? 'Pcs';
    } else if (json['unit_name'] != null) {
      uName = json['unit_name'].toString();
    }

    String? catName;
    if (json['category'] != null && json['category'] is Map<String, dynamic>) {
      catName = json['category']['name']?.toString();
    }

    return LowStockItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      barcode: json['barcode']?.toString(),
      productType: json['product_type']?.toString(),
      categoryName: catName,
      unitName: uName,
      currentStock: cur,
      minStock: min,
      deficit: def,
      stockPercentage: pct,
      isOutOfStock: cur <= 0 || json['is_out_of_stock'] == true,
      costPrice: double.tryParse((json['purchase_price'] ?? json['cost_price'] ?? 0).toString()) ?? 0.0,
      sellingPrice: double.tryParse((json['selling_price'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class StockAlertSummaryModel {
  final int totalLowStock;
  final int outOfStockCount;
  final int totalExpiring;
  final int expiredCount;
  final int expiringSoonCount;
  final double expiringValuation;

  StockAlertSummaryModel({
    required this.totalLowStock,
    required this.outOfStockCount,
    required this.totalExpiring,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.expiringValuation,
  });

  factory StockAlertSummaryModel.fromJson(Map<String, dynamic> json) {
    return StockAlertSummaryModel(
      totalLowStock: int.tryParse(json['total_low_stock']?.toString() ?? '0') ?? 0,
      outOfStockCount: int.tryParse(json['out_of_stock_count']?.toString() ?? '0') ?? 0,
      totalExpiring: int.tryParse(json['total_expiring']?.toString() ?? '0') ?? 0,
      expiredCount: int.tryParse(json['expired_count']?.toString() ?? '0') ?? 0,
      expiringSoonCount: int.tryParse(json['expiring_soon_count']?.toString() ?? '0') ?? 0,
      expiringValuation: double.tryParse(json['expiring_valuation']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class StockAlertsResultModel {
  final List<LowStockItemModel> lowStockProducts;
  final List<StockBatchModel> expiringBatches;
  final StockAlertSummaryModel summary;

  StockAlertsResultModel({
    required this.lowStockProducts,
    required this.expiringBatches,
    required this.summary,
  });

  factory StockAlertsResultModel.fromJson(Map<String, dynamic> json) {
    List<LowStockItemModel> lowList = [];
    if (json['low_stock_products'] != null && json['low_stock_products'] is List) {
      for (var item in json['low_stock_products']) {
        if (item is Map<String, dynamic>) {
          lowList.add(LowStockItemModel.fromJson(item));
        }
      }
    }

    List<StockBatchModel> expList = [];
    if (json['expiring_batches'] != null && json['expiring_batches'] is List) {
      for (var item in json['expiring_batches']) {
        if (item is Map<String, dynamic>) {
          expList.add(StockBatchModel.fromJson(item));
        }
      }
    }

    return StockAlertsResultModel(
      lowStockProducts: lowList,
      expiringBatches: expList,
      summary: json['summary'] != null && json['summary'] is Map<String, dynamic>
          ? StockAlertSummaryModel.fromJson(json['summary'])
          : StockAlertSummaryModel(
              totalLowStock: lowList.length,
              outOfStockCount: lowList.where((e) => e.isOutOfStock).length,
              totalExpiring: expList.length,
              expiredCount: expList.where((e) => e.isExpired).length,
              expiringSoonCount: expList.where((e) => !e.isExpired).length,
              expiringValuation: 0.0,
            ),
    );
  }
}
