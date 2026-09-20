import 'package:flutter/material.dart';

class PurchaseReceiptItemModel {
  final int id;
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final double quantityReceived;
  final double baseQuantity;
  final double unitCost;
  final double subtotal;
  final String? batchNumber;
  final String? expiryDate;

  PurchaseReceiptItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.quantityReceived,
    required this.baseQuantity,
    required this.unitCost,
    required this.subtotal,
    this.batchNumber,
    this.expiryDate,
  });

  factory PurchaseReceiptItemModel.fromJson(Map<String, dynamic> json) {
    String pName = 'Produk #${json['product_id']}';
    if (json['product'] != null && json['product'] is Map) {
      pName = json['product']['name']?.toString() ?? pName;
    }

    String uName = 'Pcs';
    if (json['unit'] != null && json['unit'] is Map) {
      uName = json['unit']['short_name']?.toString() ?? json['unit']['name']?.toString() ?? uName;
    }

    return PurchaseReceiptItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      unitId: int.tryParse(json['unit_id']?.toString() ?? '0') ?? 0,
      unitName: uName,
      quantityReceived: double.tryParse(json['quantity_received']?.toString() ?? '0') ?? 0,
      baseQuantity: double.tryParse(json['base_quantity']?.toString() ?? '0') ?? 0,
      unitCost: double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      batchNumber: json['batch_number']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
    );
  }
}

class PurchaseReceiptModel {
  final int id;
  final String grnNumber;
  final int? purchaseOrderId;
  final String? poNumber;
  final int supplierId;
  final String supplierName;
  final int warehouseId;
  final String warehouseName;
  final String receiptDate;
  final String? supplierInvoiceNumber;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final String paymentStatus;
  final double paidAmount;
  final String? paymentDueDate;
  final String? notes;
  final List<PurchaseReceiptItemModel> items;

  PurchaseReceiptModel({
    required this.id,
    required this.grnNumber,
    this.purchaseOrderId,
    this.poNumber,
    required this.supplierId,
    required this.supplierName,
    required this.warehouseId,
    required this.warehouseName,
    required this.receiptDate,
    this.supplierInvoiceNumber,
    required this.status,
    required this.subtotal,
    this.taxAmount = 0,
    required this.grandTotal,
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0,
    this.paymentDueDate,
    this.notes,
    this.items = const [],
  });

  factory PurchaseReceiptModel.fromJson(Map<String, dynamic> json) {
    String sName = 'Supplier #${json['supplier_id']}';
    if (json['supplier'] != null && json['supplier'] is Map) {
      sName = json['supplier']['name']?.toString() ?? sName;
    }

    String wName = 'Gudang #${json['warehouse_id']}';
    if (json['warehouse'] != null && json['warehouse'] is Map) {
      wName = json['warehouse']['name']?.toString() ?? wName;
    }

    String? poNum;
    if (json['purchase_order'] != null && json['purchase_order'] is Map) {
      poNum = json['purchase_order']['po_number']?.toString();
    }

    List<PurchaseReceiptItemModel> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      for (var item in json['items']) {
        if (item is Map<String, dynamic>) {
          itemsList.add(PurchaseReceiptItemModel.fromJson(item));
        }
      }
    }

    return PurchaseReceiptModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      grnNumber: json['grn_number']?.toString() ?? 'GRN-0000',
      purchaseOrderId: json['purchase_order_id'] != null
          ? int.tryParse(json['purchase_order_id'].toString())
          : null,
      poNumber: poNum,
      supplierId: int.tryParse(json['supplier_id']?.toString() ?? '0') ?? 0,
      supplierName: sName,
      warehouseId: int.tryParse(json['warehouse_id']?.toString() ?? '0') ?? 0,
      warehouseName: wName,
      receiptDate: json['receipt_date']?.toString() ?? '',
      supplierInvoiceNumber: json['supplier_invoice_number']?.toString(),
      status: json['status']?.toString() ?? 'confirmed',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0,
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0,
      paymentDueDate: json['payment_due_date']?.toString(),
      notes: json['notes']?.toString(),
      items: itemsList,
    );
  }

  double get remainingDebt => (grandTotal - paidAmount) > 0 ? (grandTotal - paidAmount) : 0;

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'paid':
        return 'Lunas';
      case 'partial':
        return 'Cicil (Parsial)';
      case 'unpaid':
        return 'Belum Lunas';
      default:
        return paymentStatus;
    }
  }

  Color get paymentStatusColor {
    switch (paymentStatus) {
      case 'paid':
        return const Color(0xFF059669);
      case 'partial':
        return const Color(0xFFD97706);
      case 'unpaid':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get paymentStatusBgColor {
    switch (paymentStatus) {
      case 'paid':
        return const Color(0xFFECFDF5);
      case 'partial':
        return const Color(0xFFFEF3C7);
      case 'unpaid':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}
