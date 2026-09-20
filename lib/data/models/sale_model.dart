import 'package:flutter/material.dart';

class SaleItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productCode;
  final int? unitId;
  final String unitName;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final double discountAmount;
  final double total;
  final String? notes;

  SaleItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productCode,
    this.unitId,
    required this.unitName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.notes,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    int pId = int.tryParse((json['product_id'] ?? json['product']?['id'] ?? 0).toString()) ?? 0;
    int? uId = int.tryParse((json['unit_id'] ?? json['unit']?['id'] ?? json['product']?['base_unit_id'] ?? '').toString());
    String pName = json['product_name'] ?? json['product']?['name'] ?? 'Item';
    String uName = json['unit_name'] ?? json['unit']?['name'] ?? json['product']?['base_unit']?['name'] ?? 'Pcs';

    return SaleItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: pId,
      productName: pName,
      productCode: json['product']?['code'] ?? json['product_code'],
      unitId: uId,
      unitName: uName,
      quantity: double.tryParse((json['quantity'] ?? 0).toString()) ?? 0.0,
      unitPrice: double.tryParse((json['unit_price'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      subtotal: double.tryParse((json['subtotal'] ?? 0).toString()) ?? 0.0,
      discountAmount: double.tryParse((json['discount_amount'] ?? json['discount'] ?? 0).toString()) ?? 0.0,
      total: double.tryParse((json['total'] ?? json['subtotal'] ?? 0).toString()) ?? 0.0,
      notes: json['notes']?.toString(),
    );
  }
}

class SaleModel {
  final int id;
  final String invoiceNumber;
  final String? saleDate;
  final String customerName;
  final String? customerPhone;
  final String warehouseName;
  final String cashierName;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;
  final double paidAmount;
  final double changeAmount;
  final String? notes;
  final String? createdAt;
  final List<SaleItemModel> items;

  final int? customerId;
  final String? paymentDueDate;

  SaleModel({
    required this.id,
    required this.invoiceNumber,
    this.saleDate,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.warehouseName,
    required this.cashierName,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentDueDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.grandTotal,
    required this.paidAmount,
    required this.changeAmount,
    this.notes,
    this.createdAt,
    required this.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    List<SaleItemModel> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      for (var it in json['items']) {
        if (it is Map<String, dynamic>) {
          itemList.add(SaleItemModel.fromJson(it));
        }
      }
    }

    String custName = json['customer_name'] ?? json['customer']?['name'] ?? 'Pelanggan Umum';
    String whName = json['warehouse_name'] ?? json['warehouse']?['name'] ?? 'Gudang Utama';
    String cashName = json['cashier_name'] ?? json['user']?['name'] ?? 'Kasir';
    int? cId = json['customer_id'] != null ? int.tryParse(json['customer_id'].toString()) : null;

    return SaleModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? 'Faktur',
      saleDate: json['sale_date']?.toString(),
      customerId: cId,
      customerName: custName,
      customerPhone: json['customer']?['phone']?.toString(),
      warehouseName: whName,
      cashierName: cashName,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentStatus: json['payment_status']?.toString() ?? 'paid',
      paymentDueDate: json['payment_due_date']?.toString(),
      subtotal: double.tryParse((json['subtotal'] ?? json['total_amount'] ?? 0).toString()) ?? 0.0,
      discountAmount: double.tryParse((json['discount_amount'] ?? 0).toString()) ?? 0.0,
      taxAmount: double.tryParse((json['tax_amount'] ?? 0).toString()) ?? 0.0,
      grandTotal: double.tryParse((json['grand_total'] ?? 0).toString()) ?? 0.0,
      paidAmount: double.tryParse((json['paid_amount'] ?? json['grand_total'] ?? 0).toString()) ?? 0.0,
      changeAmount: double.tryParse((json['change_amount'] ?? 0).toString()) ?? 0.0,
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      items: itemList,
    );
  }

  bool get isCash => paymentMethod.toLowerCase() == 'cash';
  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

  double get remainingReceivable => (grandTotal - paidAmount) > 0 ? (grandTotal - paidAmount) : 0;

  String get paymentStatusLabel {
    switch (paymentStatus.toLowerCase()) {
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
    switch (paymentStatus.toLowerCase()) {
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
    switch (paymentStatus.toLowerCase()) {
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

class SalesSummaryModel {
  final double totalSalesAmount;
  final int totalTransactionsCount;
  final double totalCashAmount;
  final double totalNonCashAmount;

  SalesSummaryModel({
    required this.totalSalesAmount,
    required this.totalTransactionsCount,
    required this.totalCashAmount,
    required this.totalNonCashAmount,
  });

  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesSummaryModel(
      totalSalesAmount: double.tryParse((json['total_sales_amount'] ?? 0).toString()) ?? 0.0,
      totalTransactionsCount: int.tryParse((json['total_transactions_count'] ?? 0).toString()) ?? 0,
      totalCashAmount: double.tryParse((json['total_cash_amount'] ?? 0).toString()) ?? 0.0,
      totalNonCashAmount: double.tryParse((json['total_non_cash_amount'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class SalesHistoryResultModel {
  final List<SaleModel> sales;
  final SalesSummaryModel summary;

  SalesHistoryResultModel({
    required this.sales,
    required this.summary,
  });

  factory SalesHistoryResultModel.fromJson(Map<String, dynamic> json) {
    List<SaleModel> sList = [];
    final rawList = json['sales'] is Map && json['sales']['data'] is List
        ? json['sales']['data'] as List
        : (json['sales'] is List ? json['sales'] as List : (json['data'] is List ? json['data'] as List : []));

    for (var it in rawList) {
      if (it is Map<String, dynamic>) {
        sList.add(SaleModel.fromJson(it));
      }
    }

    final sum = json['summary'] != null && json['summary'] is Map<String, dynamic>
        ? SalesSummaryModel.fromJson(json['summary'])
        : SalesSummaryModel(
            totalSalesAmount: sList.fold(0.0, (acc, s) => acc + s.grandTotal),
            totalTransactionsCount: sList.length,
            totalCashAmount: sList.where((s) => s.isCash).fold(0.0, (acc, s) => acc + s.grandTotal),
            totalNonCashAmount: sList.where((s) => !s.isCash).fold(0.0, (acc, s) => acc + s.grandTotal),
          );

    return SalesHistoryResultModel(
      sales: sList,
      summary: sum,
    );
  }
}
