import 'package:flutter/material.dart';

class PurchaseReturnItemModel {
  final int id;
  final int purchaseReturnId;
  final int? purchaseReceiptItemId;
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final double quantity;
  final double baseQuantity;
  final double unitCost;
  final double subtotal;
  final String? batchNumber;

  PurchaseReturnItemModel({
    required this.id,
    required this.purchaseReturnId,
    this.purchaseReceiptItemId,
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.quantity,
    required this.baseQuantity,
    required this.unitCost,
    required this.subtotal,
    this.batchNumber,
  });

  factory PurchaseReturnItemModel.fromJson(Map<String, dynamic> json) {
    String pName = 'Produk #${json['product_id']}';
    if (json['product'] != null && json['product'] is Map) {
      pName = json['product']['name']?.toString() ?? pName;
    }

    String uName = 'Pcs';
    if (json['unit'] != null && json['unit'] is Map) {
      uName = json['unit']['short_name']?.toString() ?? json['unit']['name']?.toString() ?? uName;
    }

    return PurchaseReturnItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      purchaseReturnId: int.tryParse(json['purchase_return_id']?.toString() ?? '0') ?? 0,
      purchaseReceiptItemId: json['purchase_receipt_item_id'] != null
          ? int.tryParse(json['purchase_receipt_item_id'].toString())
          : null,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      unitId: int.tryParse(json['unit_id']?.toString() ?? '0') ?? 0,
      unitName: uName,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      baseQuantity: double.tryParse(json['base_quantity']?.toString() ?? '0') ?? 0,
      unitCost: double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      batchNumber: json['batch_number']?.toString(),
    );
  }
}

class PurchaseReturnModel {
  final int id;
  final String returnNumber;
  final int? purchaseReceiptId;
  final String? grnNumber;
  final int supplierId;
  final String supplierName;
  final int warehouseId;
  final String warehouseName;
  final String returnDate;
  final String status;
  final double totalAmount;
  final String? reason;
  final String? userName;
  final List<PurchaseReturnItemModel> items;

  PurchaseReturnModel({
    required this.id,
    required this.returnNumber,
    this.purchaseReceiptId,
    this.grnNumber,
    required this.supplierId,
    required this.supplierName,
    required this.warehouseId,
    required this.warehouseName,
    required this.returnDate,
    required this.status,
    required this.totalAmount,
    this.reason,
    this.userName,
    this.items = const [],
  });

  factory PurchaseReturnModel.fromJson(Map<String, dynamic> json) {
    String sName = 'Supplier #${json['supplier_id']}';
    if (json['supplier'] != null && json['supplier'] is Map) {
      sName = json['supplier']['name']?.toString() ?? sName;
    }

    String wName = 'Gudang #${json['warehouse_id']}';
    if (json['warehouse'] != null && json['warehouse'] is Map) {
      wName = json['warehouse']['name']?.toString() ?? wName;
    }

    String? grnNum;
    if (json['purchase_receipt'] != null && json['purchase_receipt'] is Map) {
      grnNum = json['purchase_receipt']['grn_number']?.toString();
    } else if (json['receipt'] != null && json['receipt'] is Map) {
      grnNum = json['receipt']['grn_number']?.toString();
    }

    String? uName;
    if (json['user'] != null && json['user'] is Map) {
      uName = json['user']['name']?.toString();
    }

    List<PurchaseReturnItemModel> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      for (var item in json['items']) {
        if (item is Map<String, dynamic>) {
          itemsList.add(PurchaseReturnItemModel.fromJson(item));
        }
      }
    }

    return PurchaseReturnModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      returnNumber: json['return_number']?.toString() ?? 'PR-0000',
      purchaseReceiptId: json['purchase_receipt_id'] != null
          ? int.tryParse(json['purchase_receipt_id'].toString())
          : null,
      grnNumber: grnNum,
      supplierId: int.tryParse(json['supplier_id']?.toString() ?? '0') ?? 0,
      supplierName: sName,
      warehouseId: int.tryParse(json['warehouse_id']?.toString() ?? '0') ?? 0,
      warehouseName: wName,
      returnDate: json['return_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'confirmed',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      reason: json['reason']?.toString(),
      userName: uName,
      items: itemsList,
    );
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Selesai / Terkonfirmasi';
      case 'cancelled':
        return 'Dibatalkan';
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'draft':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFFECFDF5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      case 'draft':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}
