import 'package:flutter/material.dart';

class StockOpnameItemModel {
  final int id;
  final int stockOpnameId;
  final int productId;
  final String productName;
  final String? productCode;
  final String unitName;
  final double systemQty;
  final double physicalQty;
  final double differenceQty;
  final double unitCost;
  final double differenceValue;
  final String? reason;

  StockOpnameItemModel({
    required this.id,
    required this.stockOpnameId,
    required this.productId,
    required this.productName,
    this.productCode,
    this.unitName = 'Pcs',
    required this.systemQty,
    required this.physicalQty,
    required this.differenceQty,
    required this.unitCost,
    required this.differenceValue,
    this.reason,
  });

  factory StockOpnameItemModel.fromJson(Map<String, dynamic> json) {
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

    final double sys = double.tryParse(json['system_qty']?.toString() ?? '0') ?? 0;
    final double phys = double.tryParse(json['physical_qty']?.toString() ?? '0') ?? 0;
    final double diff = json['difference_qty'] != null
        ? (double.tryParse(json['difference_qty'].toString()) ?? (phys - sys))
        : (phys - sys);
    final double cost = double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0;
    final double val = json['difference_value'] != null
        ? (double.tryParse(json['difference_value'].toString()) ?? (diff * cost))
        : (diff * cost);

    return StockOpnameItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      stockOpnameId: int.tryParse(json['stock_opname_id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      productCode: pCode,
      unitName: uName,
      systemQty: sys,
      physicalQty: phys,
      differenceQty: diff,
      unitCost: cost,
      differenceValue: val,
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'physical_qty': physicalQty,
        'reason': reason,
      };

  bool get hasDifference => differenceQty != 0;
  bool get isSurplus => differenceQty > 0;
  bool get isDeficit => differenceQty < 0;

  Color get diffColor {
    if (isSurplus) return const Color(0xFF059669);
    if (isDeficit) return const Color(0xFFDC2626);
    return const Color(0xFF64748B);
  }
}

class StockOpnameModel {
  final int id;
  final String opnameNumber;
  final int warehouseId;
  final String warehouseName;
  final String opnameDate;
  final String status; // 'draft', 'in_progress', 'completed', 'cancelled'
  final String? notes;
  final int? conductedBy;
  final String? conductorName;
  final int? approvedBy;
  final String? approverName;
  final String? approvedAt;
  final List<StockOpnameItemModel> items;

  StockOpnameModel({
    required this.id,
    required this.opnameNumber,
    required this.warehouseId,
    required this.warehouseName,
    required this.opnameDate,
    required this.status,
    this.notes,
    this.conductedBy,
    this.conductorName,
    this.approvedBy,
    this.approverName,
    this.approvedAt,
    required this.items,
  });

  factory StockOpnameModel.fromJson(Map<String, dynamic> json) {
    String wName = 'Gudang Utama';
    if (json['warehouse'] != null && json['warehouse'] is Map) {
      wName = json['warehouse']['name']?.toString() ?? wName;
    }

    String? cName;
    if (json['conductor'] != null && json['conductor'] is Map) {
      cName = json['conductor']['name']?.toString();
    }

    String? aName;
    if (json['approver'] != null && json['approver'] is Map) {
      aName = json['approver']['name']?.toString();
    }

    List<StockOpnameItemModel> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      for (var item in json['items']) {
        if (item is Map<String, dynamic>) {
          itemList.add(StockOpnameItemModel.fromJson(item));
        }
      }
    }

    return StockOpnameModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      opnameNumber: json['opname_number']?.toString() ?? 'SO-DRAFT',
      warehouseId: int.tryParse(json['warehouse_id']?.toString() ?? '0') ?? 0,
      warehouseName: wName,
      opnameDate: json['opname_date']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'draft',
      notes: json['notes']?.toString(),
      conductedBy: json['conducted_by'] != null ? int.tryParse(json['conducted_by'].toString()) : null,
      conductorName: cName,
      approvedBy: json['approved_by'] != null ? int.tryParse(json['approved_by'].toString()) : null,
      approverName: aName,
      approvedAt: json['approved_at']?.toString(),
      items: itemList,
    );
  }

  int get totalItemsCount => items.length;

  int get diffItemsCount => items.where((i) => i.hasDifference).length;

  double get totalDifferenceQty => items.fold(0.0, (sum, i) => sum + i.differenceQty);

  double get totalDifferenceValue => items.fold(0.0, (sum, i) => sum + i.differenceValue);

  bool get isDraft => status == 'draft';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canEdit => isDraft || isInProgress;

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Selesai (Completed)';
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
      case 'in_progress':
        return const Color(0xFFD97706);
      case 'completed':
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
      case 'in_progress':
        return const Color(0xFFFEF3C7);
      case 'completed':
        return const Color(0xFFECFDF5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}
