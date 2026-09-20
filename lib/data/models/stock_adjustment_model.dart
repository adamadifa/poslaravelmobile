import 'package:flutter/material.dart';

class StockAdjustmentItemModel {
  final int id;
  final int stockAdjustmentId;
  final int productId;
  final String productName;
  final String? productCode;
  final String unitName;
  final double quantity;
  final double baseQuantity;
  final double unitCost;
  final double totalCost;
  final String? batchNumber;

  StockAdjustmentItemModel({
    required this.id,
    required this.stockAdjustmentId,
    required this.productId,
    required this.productName,
    this.productCode,
    this.unitName = 'Pcs',
    required this.quantity,
    required this.baseQuantity,
    required this.unitCost,
    required this.totalCost,
    this.batchNumber,
  });

  factory StockAdjustmentItemModel.fromJson(Map<String, dynamic> json) {
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

    // Override unit if there is a linked unit object
    if (json['unit'] != null && json['unit'] is Map) {
      uName = json['unit']['short_name']?.toString() ?? json['unit']['name']?.toString() ?? uName;
    }

    return StockAdjustmentItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      stockAdjustmentId: int.tryParse(json['stock_adjustment_id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      productCode: pCode,
      unitName: uName,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      baseQuantity: double.tryParse(json['base_quantity']?.toString() ?? '0') ?? 0,
      unitCost: double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0,
      totalCost: double.tryParse(json['total_cost']?.toString() ?? '0') ?? 0,
      batchNumber: json['batch_number']?.toString(),
    );
  }
}

class StockAdjustmentModel {
  final int id;
  final String adjustmentNumber;
  final int warehouseId;
  final String warehouseName;
  final String adjustmentDate;
  final String type; // 'addition' or 'reduction'
  final String reason;
  final String status; // 'draft', 'approved', 'cancelled'
  final String? notes;
  final int? createdBy;
  final String? creatorName;
  final int? approvedBy;
  final String? approverName;
  final String? approvedAt;
  final List<StockAdjustmentItemModel> items;

  StockAdjustmentModel({
    required this.id,
    required this.adjustmentNumber,
    required this.warehouseId,
    required this.warehouseName,
    required this.adjustmentDate,
    required this.type,
    required this.reason,
    required this.status,
    this.notes,
    this.createdBy,
    this.creatorName,
    this.approvedBy,
    this.approverName,
    this.approvedAt,
    required this.items,
  });

  factory StockAdjustmentModel.fromJson(Map<String, dynamic> json) {
    String wName = 'Gudang Utama';
    if (json['warehouse'] != null && json['warehouse'] is Map) {
      wName = json['warehouse']['name']?.toString() ?? wName;
    }

    String? cName;
    if (json['creator'] != null && json['creator'] is Map) {
      cName = json['creator']['name']?.toString();
    }

    String? aName;
    if (json['approver'] != null && json['approver'] is Map) {
      aName = json['approver']['name']?.toString();
    }

    List<StockAdjustmentItemModel> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      for (var item in json['items']) {
        if (item is Map<String, dynamic>) {
          itemList.add(StockAdjustmentItemModel.fromJson(item));
        }
      }
    }

    return StockAdjustmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      adjustmentNumber: json['adjustment_number']?.toString() ?? 'ADJ-DRAFT',
      warehouseId: int.tryParse(json['warehouse_id']?.toString() ?? '0') ?? 0,
      warehouseName: wName,
      adjustmentDate: json['adjustment_date']?.toString() ?? '',
      type: json['type']?.toString() ?? 'addition',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'draft',
      notes: json['notes']?.toString(),
      createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
      creatorName: cName,
      approvedBy: json['approved_by'] != null ? int.tryParse(json['approved_by'].toString()) : null,
      approverName: aName,
      approvedAt: json['approved_at']?.toString(),
      items: itemList,
    );
  }

  // Computed
  bool get isDraft => status == 'draft';
  bool get isApproved => status == 'approved';
  bool get isCancelled => status == 'cancelled';
  bool get canEdit => isDraft;
  bool get isAddition => type == 'addition';

  double get totalQuantity => items.fold(0.0, (sum, i) => sum + i.quantity);
  double get totalValue => items.fold(0.0, (sum, i) => sum + i.totalCost);

  String get typeLabel => isAddition ? 'Penambahan Stok (+)' : 'Pengurangan Stok (-)';

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'approved':
        return 'Disetujui';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return const Color(0xFF64748B);
      case 'approved':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'draft':
        return const Color(0xFFF1F5F9);
      case 'approved':
        return const Color(0xFFECFDF5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get typeColor => isAddition ? const Color(0xFF059669) : const Color(0xFFDC2626);
  Color get typeBgColor => isAddition ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2);
}
