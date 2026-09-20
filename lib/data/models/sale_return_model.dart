class SaleReturnModel {
  final int id;
  final String returnNumber;
  final int saleId;
  final String? invoiceNumber;
  final int? customerId;
  final String customerName;
  final int? warehouseId;
  final String warehouseName;
  final int? accountId;
  final String? accountName;
  final String? returnDate;
  final double subtotal;
  final double taxAmount;
  final double refundAmount;
  final String refundMethod; // cash, credit_deduction, exchange
  final String reason;
  final String status; // completed, cancelled
  final String? notes;
  final String? cashierName;
  final String? createdAt;
  final List<SaleReturnItemModel> items;

  SaleReturnModel({
    required this.id,
    required this.returnNumber,
    required this.saleId,
    this.invoiceNumber,
    this.customerId,
    required this.customerName,
    this.warehouseId,
    required this.warehouseName,
    this.accountId,
    this.accountName,
    this.returnDate,
    required this.subtotal,
    required this.taxAmount,
    required this.refundAmount,
    required this.refundMethod,
    required this.reason,
    required this.status,
    this.notes,
    this.cashierName,
    this.createdAt,
    this.items = const [],
  });

  factory SaleReturnModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<SaleReturnItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems.map((i) => SaleReturnItemModel.fromJson(i as Map<String, dynamic>)).toList();
    }

    return SaleReturnModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      returnNumber: json['return_number']?.toString() ?? '',
      saleId: json['sale_id'] is int ? json['sale_id'] : int.tryParse(json['sale_id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['sale']?['invoice_number']?.toString() ?? json['invoice_number']?.toString(),
      customerId: json['customer_id'] is int ? json['customer_id'] : int.tryParse(json['customer_id']?.toString() ?? ''),
      customerName: json['customer']?['name']?.toString() ?? 'Pelanggan Umum',
      warehouseId: json['warehouse_id'] is int ? json['warehouse_id'] : int.tryParse(json['warehouse_id']?.toString() ?? ''),
      warehouseName: json['warehouse']?['name']?.toString() ?? 'Gudang Utama',
      accountId: json['account_id'] is int ? json['account_id'] : int.tryParse(json['account_id']?.toString() ?? ''),
      accountName: json['account']?['name']?.toString(),
      returnDate: json['return_date']?.toString(),
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      refundAmount: double.tryParse(json['refund_amount']?.toString() ?? '0') ?? 0.0,
      refundMethod: json['refund_method']?.toString() ?? 'cash',
      reason: json['reason']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'completed',
      notes: json['notes']?.toString(),
      cashierName: json['creator']?['name']?.toString() ?? json['cashier_name']?.toString(),
      createdAt: json['created_at']?.toString(),
      items: itemsList,
    );
  }
}

class SaleReturnItemModel {
  final int id;
  final int saleReturnId;
  final int productId;
  final String productName;
  final String? productCode;
  final int? unitId;
  final String unitName;
  final double quantity;
  final double baseQuantity;
  final double unitPrice;
  final double subtotal;
  final String type; // return, replacement
  final String? batchNumber;

  SaleReturnItemModel({
    required this.id,
    required this.saleReturnId,
    required this.productId,
    required this.productName,
    this.productCode,
    this.unitId,
    required this.unitName,
    required this.quantity,
    required this.baseQuantity,
    required this.unitPrice,
    required this.subtotal,
    required this.type,
    this.batchNumber,
  });

  factory SaleReturnItemModel.fromJson(Map<String, dynamic> json) {
    return SaleReturnItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      saleReturnId: json['sale_return_id'] is int ? json['sale_return_id'] : int.tryParse(json['sale_return_id']?.toString() ?? '0') ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product']?['name']?.toString() ?? 'Produk #${json['product_id']}',
      productCode: json['product']?['code']?.toString(),
      unitId: json['unit_id'] is int ? json['unit_id'] : int.tryParse(json['unit_id']?.toString() ?? ''),
      unitName: json['unit']?['name']?.toString() ?? json['product']?['base_unit']?['name']?.toString() ?? 'Pcs',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      baseQuantity: double.tryParse(json['base_quantity']?.toString() ?? '0') ?? 0.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      type: json['type']?.toString() ?? 'return',
      batchNumber: json['batch_number']?.toString(),
    );
  }
}

class SaleReturnSummaryModel {
  final double totalRefund;
  final double totalItemsReturned;
  final int returnsCount;

  SaleReturnSummaryModel({
    required this.totalRefund,
    required this.totalItemsReturned,
    required this.returnsCount,
  });

  factory SaleReturnSummaryModel.fromJson(Map<String, dynamic> json) {
    return SaleReturnSummaryModel(
      totalRefund: double.tryParse(json['total_refund']?.toString() ?? '0') ?? 0.0,
      totalItemsReturned: double.tryParse(json['total_items_returned']?.toString() ?? '0') ?? 0.0,
      returnsCount: json['returns_count'] is int ? json['returns_count'] : int.tryParse(json['returns_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class SaleReturnsResultModel {
  final List<SaleReturnModel> returns;
  final SaleReturnSummaryModel summary;

  SaleReturnsResultModel({
    required this.returns,
    required this.summary,
  });

  factory SaleReturnsResultModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['returns'];
    List<SaleReturnModel> list = [];
    if (rawList is List) {
      list = rawList.map((i) => SaleReturnModel.fromJson(i as Map<String, dynamic>)).toList();
    }

    return SaleReturnsResultModel(
      returns: list,
      summary: SaleReturnSummaryModel.fromJson(json['summary'] ?? {}),
    );
  }
}
