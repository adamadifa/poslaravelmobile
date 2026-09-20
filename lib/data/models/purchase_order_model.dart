import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

class PurchaseOrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productCode;
  final int unitId;
  final String unitName;
  final double quantityOrdered;
  final double quantityReceived;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double subtotal;

  PurchaseOrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productCode,
    required this.unitId,
    required this.unitName,
    required this.quantityOrdered,
    this.quantityReceived = 0,
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.subtotal,
  });

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    String pName = 'Produk #${json['product_id']}';
    String? pCode;
    if (json['product'] != null && json['product'] is Map) {
      pName = json['product']['name']?.toString() ?? pName;
      pCode = json['product']['code']?.toString();
    }

    String uName = 'Pcs';
    if (json['unit'] != null && json['unit'] is Map) {
      uName = json['unit']['short_name']?.toString() ?? json['unit']['name']?.toString() ?? uName;
    }

    return PurchaseOrderItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      productCode: pCode,
      unitId: int.tryParse(json['unit_id']?.toString() ?? '0') ?? 0,
      unitName: uName,
      quantityOrdered: double.tryParse(json['quantity_ordered']?.toString() ?? '0') ?? 0,
      quantityReceived: double.tryParse(json['quantity_received']?.toString() ?? '0') ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      discountPercent: double.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'unit_id': unitId,
        'quantity_ordered': quantityOrdered,
        'unit_price': unitPrice,
        'discount_percent': discountPercent,
        'discount_amount': discountAmount,
        'subtotal': subtotal,
      };

  double get remainingQuantity => (quantityOrdered - quantityReceived) > 0 ? (quantityOrdered - quantityReceived) : 0;
  bool get isFullyReceived => quantityReceived >= quantityOrdered && quantityOrdered > 0;
}

class PurchaseOrderModel {
  final int id;
  final String poNumber;
  final int supplierId;
  final String supplierName;
  final String? supplierPhone;
  final int warehouseId;
  final String warehouseName;
  final String orderDate;
  final String? expectedDate;
  final String status;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double shippingCost;
  final double grandTotal;
  final String? notes;
  final List<PurchaseOrderItemModel> items;

  PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    this.supplierPhone,
    required this.warehouseId,
    required this.warehouseName,
    required this.orderDate,
    this.expectedDate,
    required this.status,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.shippingCost = 0,
    required this.grandTotal,
    this.notes,
    this.items = const [],
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    String sName = 'Supplier #${json['supplier_id']}';
    String? sPhone;
    if (json['supplier'] != null && json['supplier'] is Map) {
      sName = json['supplier']['name']?.toString() ?? sName;
      sPhone = json['supplier']['phone']?.toString();
    }

    String wName = 'Gudang #${json['warehouse_id']}';
    if (json['warehouse'] != null && json['warehouse'] is Map) {
      wName = json['warehouse']['name']?.toString() ?? wName;
    }

    List<PurchaseOrderItemModel> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      for (var item in json['items']) {
        if (item is Map<String, dynamic>) {
          itemsList.add(PurchaseOrderItemModel.fromJson(item));
        }
      }
    }

    return PurchaseOrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      poNumber: json['po_number']?.toString() ?? 'PO-0000',
      supplierId: int.tryParse(json['supplier_id']?.toString() ?? '0') ?? 0,
      supplierName: sName,
      supplierPhone: sPhone,
      warehouseId: int.tryParse(json['warehouse_id']?.toString() ?? '0') ?? 0,
      warehouseName: wName,
      orderDate: json['order_date']?.toString() ?? '',
      expectedDate: json['expected_date']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0,
      shippingCost: double.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0,
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString(),
      items: itemsList,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Terkirim';
      case 'partial':
        return 'Parsial';
      case 'received':
        return 'Diterima';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return const Color(0xFF64748B); // slate
      case 'sent':
        return const Color(0xFF2563EB); // blue
      case 'partial':
        return const Color(0xFFD97706); // amber
      case 'received':
        return const Color(0xFF059669); // green
      case 'cancelled':
        return const Color(0xFFDC2626); // red
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'draft':
        return const Color(0xFFF1F5F9);
      case 'sent':
        return const Color(0xFFEFF6FF);
      case 'partial':
        return const Color(0xFFFEF3C7);
      case 'received':
        return const Color(0xFFECFDF5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String get formattedGrandTotal => CurrencyFormatter.format(grandTotal);

  bool get canEdit => status == 'draft' || status == 'sent';
  bool get canReceive => status == 'sent' || status == 'partial';
  bool get canCancel => status == 'draft' || status == 'sent';
}
