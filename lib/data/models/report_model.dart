class SalesReportData {
  final SalesKpis kpis;
  final List<DailyTrendModel> dailyTrends;

  SalesReportData({
    required this.kpis,
    required this.dailyTrends,
  });

  factory SalesReportData.fromJson(Map<String, dynamic> json) {
    return SalesReportData(
      kpis: SalesKpis.fromJson(json['kpis'] ?? {}),
      dailyTrends: (json['daily_trends'] as List? ?? [])
          .map((e) => DailyTrendModel.fromJson(e))
          .toList(),
    );
  }
}

class SalesKpis {
  final double totalSales;
  final int totalTransactions;
  final double totalSubtotal;
  final double totalDiscount;
  final double totalTax;
  final double averageOrderValue;
  final double totalCash;
  final double totalNonCash;
  final double totalHpp;
  final double grossProfit;
  final double profitMarginPercent;

  SalesKpis({
    required this.totalSales,
    required this.totalTransactions,
    required this.totalSubtotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.averageOrderValue,
    required this.totalCash,
    required this.totalNonCash,
    required this.totalHpp,
    required this.grossProfit,
    required this.profitMarginPercent,
  });

  factory SalesKpis.fromJson(Map<String, dynamic> json) {
    return SalesKpis(
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
      totalSubtotal: (json['total_subtotal'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0.0,
      totalTax: (json['total_tax'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
      totalCash: (json['total_cash'] as num?)?.toDouble() ?? 0.0,
      totalNonCash: (json['total_non_cash'] as num?)?.toDouble() ?? 0.0,
      totalHpp: (json['total_hpp'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (json['gross_profit'] as num?)?.toDouble() ?? 0.0,
      profitMarginPercent: (json['profit_margin_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyTrendModel {
  final String date;
  final String formattedDate;
  final double totalAmount;
  final int totalCount;

  DailyTrendModel({
    required this.date,
    required this.formattedDate,
    required this.totalAmount,
    required this.totalCount,
  });

  factory DailyTrendModel.fromJson(Map<String, dynamic> json) {
    return DailyTrendModel(
      date: json['date'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductPerformanceModel {
  final int productId;
  final String productName;
  final String productCode;
  final String categoryName;
  final double totalQty;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double marginPercent;

  ProductPerformanceModel({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.categoryName,
    required this.totalQty,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.marginPercent,
  });

  factory ProductPerformanceModel.fromJson(Map<String, dynamic> json) {
    return ProductPerformanceModel(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] ?? '',
      productCode: json['product_code'] ?? '',
      categoryName: json['category_name'] ?? 'Umum',
      totalQty: (json['total_qty'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (json['gross_profit'] as num?)?.toDouble() ?? 0.0,
      marginPercent: (json['margin_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryPerformanceModel {
  final String categoryName;
  final int productsCount;
  final double totalQty;
  final double totalRevenue;
  final double grossProfit;
  final double marginPercent;

  CategoryPerformanceModel({
    required this.categoryName,
    required this.productsCount,
    required this.totalQty,
    required this.totalRevenue,
    required this.grossProfit,
    required this.marginPercent,
  });

  factory CategoryPerformanceModel.fromJson(Map<String, dynamic> json) {
    return CategoryPerformanceModel(
      categoryName: json['category_name'] ?? 'Umum',
      productsCount: (json['products_count'] as num?)?.toInt() ?? 0,
      totalQty: (json['total_qty'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (json['gross_profit'] as num?)?.toDouble() ?? 0.0,
      marginPercent: (json['margin_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProfitLossReportData {
  final double grossSales;
  final double discounts;
  final double tax;
  final double netSales;
  final double extraIncome;
  final double totalHpp;
  final double grossProfit;
  final double grossMarginPercent;
  final double totalExpenses;
  final List<ExpenseCategoryBreakdown> expenseBreakdown;
  final double netProfit;
  final double netMarginPercent;
  final bool isProfitable;

  ProfitLossReportData({
    required this.grossSales,
    required this.discounts,
    required this.tax,
    required this.netSales,
    required this.extraIncome,
    required this.totalHpp,
    required this.grossProfit,
    required this.grossMarginPercent,
    required this.totalExpenses,
    required this.expenseBreakdown,
    required this.netProfit,
    required this.netMarginPercent,
    required this.isProfitable,
  });

  factory ProfitLossReportData.fromJson(Map<String, dynamic> json) {
    final revenue = json['revenue'] ?? {};
    final cogs = json['cogs'] ?? {};
    final expenses = json['expenses'] ?? {};
    final bottom = json['bottom_line'] ?? {};

    return ProfitLossReportData(
      grossSales: (revenue['gross_sales'] as num?)?.toDouble() ?? 0.0,
      discounts: (revenue['discounts'] as num?)?.toDouble() ?? 0.0,
      tax: (revenue['tax'] as num?)?.toDouble() ?? 0.0,
      netSales: (revenue['net_sales'] as num?)?.toDouble() ?? 0.0,
      extraIncome: (revenue['extra_income'] as num?)?.toDouble() ?? 0.0,
      totalHpp: (cogs['total_hpp'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (cogs['gross_profit'] as num?)?.toDouble() ?? 0.0,
      grossMarginPercent: (cogs['gross_margin_percent'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (expenses['total_expenses'] as num?)?.toDouble() ?? 0.0,
      expenseBreakdown: (expenses['breakdown'] as List? ?? [])
          .map((e) => ExpenseCategoryBreakdown.fromJson(e))
          .toList(),
      netProfit: (bottom['net_profit'] as num?)?.toDouble() ?? 0.0,
      netMarginPercent: (bottom['net_margin_percent'] as num?)?.toDouble() ?? 0.0,
      isProfitable: bottom['is_profitable'] == true,
    );
  }
}

class ExpenseCategoryBreakdown {
  final String category;
  final double amount;

  ExpenseCategoryBreakdown({required this.category, required this.amount});

  factory ExpenseCategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryBreakdown(
      category: json['category'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InventoryValuationData {
  final int totalProducts;
  final double totalStockQty;
  final double totalValuationCost;
  final double totalPotentialRevenue;
  final double potentialProfit;
  final int lowStockItems;
  final int outOfStockItems;

  InventoryValuationData({
    required this.totalProducts,
    required this.totalStockQty,
    required this.totalValuationCost,
    required this.totalPotentialRevenue,
    required this.potentialProfit,
    required this.lowStockItems,
    required this.outOfStockItems,
  });

  factory InventoryValuationData.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    return InventoryValuationData(
      totalProducts: (s['total_products'] as num?)?.toInt() ?? 0,
      totalStockQty: (s['total_stock_qty'] as num?)?.toDouble() ?? 0.0,
      totalValuationCost: (s['total_valuation_cost'] as num?)?.toDouble() ?? 0.0,
      totalPotentialRevenue: (s['total_potential_revenue'] as num?)?.toDouble() ?? 0.0,
      potentialProfit: (s['potential_profit'] as num?)?.toDouble() ?? 0.0,
      lowStockItems: (s['low_stock_items'] as num?)?.toInt() ?? 0,
      outOfStockItems: (s['out_of_stock_items'] as num?)?.toInt() ?? 0,
    );
  }
}

class CustomerSalesReportModel {
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final String customerCode;
  final int totalOrders;
  final double totalSpent;
  final double avgSpent;
  final String lastOrderDate;

  CustomerSalesReportModel({
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerCode,
    required this.totalOrders,
    required this.totalSpent,
    required this.avgSpent,
    required this.lastOrderDate,
  });

  factory CustomerSalesReportModel.fromJson(Map<String, dynamic> json) {
    return CustomerSalesReportModel(
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] ?? 'Pelanggan Umum',
      customerPhone: json['customer_phone'] ?? '-',
      customerCode: json['customer_code'] ?? '-',
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      avgSpent: (json['avg_spent'] as num?)?.toDouble() ?? 0.0,
      lastOrderDate: json['last_order_date'] ?? '-',
    );
  }
}

class PurchasesReportData {
  final double totalPurchases;
  final int totalOrders;
  final double totalDiscount;
  final List<SupplierPurchaseSummary> supplierBreakdown;

  PurchasesReportData({
    required this.totalPurchases,
    required this.totalOrders,
    required this.totalDiscount,
    required this.supplierBreakdown,
  });

  factory PurchasesReportData.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    final list = (json['supplier_breakdown'] as List? ?? [])
        .map((e) => SupplierPurchaseSummary.fromJson(e))
        .toList();

    return PurchasesReportData(
      totalPurchases: (s['total_purchases'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (s['total_orders'] as num?)?.toInt() ?? 0,
      totalDiscount: (s['total_discount'] as num?)?.toDouble() ?? 0.0,
      supplierBreakdown: list,
    );
  }
}

class SupplierPurchaseSummary {
  final int supplierId;
  final String supplierName;
  final String supplierCode;
  final int totalPoCount;
  final double totalAmount;

  SupplierPurchaseSummary({
    required this.supplierId,
    required this.supplierName,
    required this.supplierCode,
    required this.totalPoCount,
    required this.totalAmount,
  });

  factory SupplierPurchaseSummary.fromJson(Map<String, dynamic> json) {
    return SupplierPurchaseSummary(
      supplierId: (json['supplier_id'] as num?)?.toInt() ?? 0,
      supplierName: json['supplier_name'] ?? '',
      supplierCode: json['supplier_code'] ?? '',
      totalPoCount: (json['total_po_count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StockOpnameReportItem {
  final int id;
  final String opnameNumber;
  final String opnameDate;
  final String warehouseName;
  final String conductorName;
  final String status;
  final int totalItemsCount;
  final double totalDifferenceQty;
  final double totalDifferenceCost;

  StockOpnameReportItem({
    required this.id,
    required this.opnameNumber,
    required this.opnameDate,
    required this.warehouseName,
    required this.conductorName,
    required this.status,
    required this.totalItemsCount,
    required this.totalDifferenceQty,
    required this.totalDifferenceCost,
  });

  factory StockOpnameReportItem.fromJson(Map<String, dynamic> json) {
    return StockOpnameReportItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      opnameNumber: json['opname_number'] ?? '',
      opnameDate: json['opname_date'] ?? '-',
      warehouseName: json['warehouse_name'] ?? '-',
      conductorName: json['conductor_name'] ?? '-',
      status: json['status'] ?? '',
      totalItemsCount: (json['total_items_count'] as num?)?.toInt() ?? 0,
      totalDifferenceQty: (json['total_difference_qty'] as num?)?.toDouble() ?? 0.0,
      totalDifferenceCost: (json['total_difference_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PayableReportData {
  final double totalPayable;
  final double totalPaid;
  final double totalOutstanding;
  final List<PayableReportItem> payables;

  PayableReportData({
    required this.totalPayable,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.payables,
  });

  factory PayableReportData.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    final list = (json['payables'] as List? ?? [])
        .map((e) => PayableReportItem.fromJson(e))
        .toList();

    return PayableReportData(
      totalPayable: (s['total_payable'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (s['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalOutstanding: (s['total_outstanding'] as num?)?.toDouble() ?? 0.0,
      payables: list,
    );
  }
}

class PayableReportItem {
  final int receiptId;
  final String receiptNumber;
  final String poNumber;
  final String supplierName;
  final String receiptDate;
  final int daysOutstanding;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;

  PayableReportItem({
    required this.receiptId,
    required this.receiptNumber,
    required this.poNumber,
    required this.supplierName,
    required this.receiptDate,
    required this.daysOutstanding,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  factory PayableReportItem.fromJson(Map<String, dynamic> json) {
    return PayableReportItem(
      receiptId: (json['receipt_id'] as num?)?.toInt() ?? 0,
      receiptNumber: json['receipt_number'] ?? '',
      poNumber: json['po_number'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      receiptDate: json['receipt_date'] ?? '-',
      daysOutstanding: (json['days_outstanding'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReceivableReportData {
  final double totalReceivable;
  final double totalPaid;
  final double totalOutstanding;
  final List<ReceivableReportItem> receivables;

  ReceivableReportData({
    required this.totalReceivable,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.receivables,
  });

  factory ReceivableReportData.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    final list = (json['receivables'] as List? ?? [])
        .map((e) => ReceivableReportItem.fromJson(e))
        .toList();

    return ReceivableReportData(
      totalReceivable: (s['total_receivable'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (s['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalOutstanding: (s['total_outstanding'] as num?)?.toDouble() ?? 0.0,
      receivables: list,
    );
  }
}

class ReceivableReportItem {
  final int saleId;
  final String invoiceNumber;
  final String customerName;
  final String saleDate;
  final int daysOutstanding;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;

  ReceivableReportItem({
    required this.saleId,
    required this.invoiceNumber,
    required this.customerName,
    required this.saleDate,
    required this.daysOutstanding,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  factory ReceivableReportItem.fromJson(Map<String, dynamic> json) {
    return ReceivableReportItem(
      saleId: (json['sale_id'] as num?)?.toInt() ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      customerName: json['customer_name'] ?? 'Pelanggan Umum',
      saleDate: json['sale_date'] ?? '-',
      daysOutstanding: (json['days_outstanding'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CashFlowReportData {
  final double totalIncome;
  final double totalExpense;
  final double netCash;
  final List<CashFlowReportItem> cashFlows;

  CashFlowReportData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCash,
    required this.cashFlows,
  });

  factory CashFlowReportData.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    final list = (json['cash_flows'] as List? ?? [])
        .map((e) => CashFlowReportItem.fromJson(e))
        .toList();

    return CashFlowReportData(
      totalIncome: (s['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (s['total_expense'] as num?)?.toDouble() ?? 0.0,
      netCash: (s['net_cash'] as num?)?.toDouble() ?? 0.0,
      cashFlows: list,
    );
  }
}

class CashFlowReportItem {
  final int id;
  final String cashFlowNumber;
  final String type;
  final String category;
  final double amount;
  final String description;
  final String transactionDate;
  final String accountName;

  CashFlowReportItem({
    required this.id,
    required this.cashFlowNumber,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.accountName,
  });

  factory CashFlowReportItem.fromJson(Map<String, dynamic> json) {
    return CashFlowReportItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cashFlowNumber: json['cash_flow_number'] ?? '',
      type: json['type'] ?? 'income',
      category: json['category'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '-',
      transactionDate: json['transaction_date'] ?? '-',
      accountName: json['account_name'] ?? 'Kas',
    );
  }
}

class CashierShiftReportData {
  final int totalShifts;
  final double totalSales;
  final double totalExpenses;
  final double totalCashDifference;
  final List<CashierShiftReportItem> shifts;

  CashierShiftReportData({
    required this.totalShifts,
    required this.totalSales,
    required this.totalExpenses,
    required this.totalCashDifference,
    required this.shifts,
  });

  factory CashierShiftReportData.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    final list = (json['shifts'] as List? ?? [])
        .map((e) => CashierShiftReportItem.fromJson(e))
        .toList();

    return CashierShiftReportData(
      totalShifts: (s['total_shifts'] as num?)?.toInt() ?? 0,
      totalSales: (s['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (s['total_expenses'] as num?)?.toDouble() ?? 0.0,
      totalCashDifference: (s['total_cash_difference'] as num?)?.toDouble() ?? 0.0,
      shifts: list,
    );
  }
}

class CashierShiftReportItem {
  final int id;
  final String cashierName;
  final String warehouseName;
  final String openedAt;
  final String? closedAt;
  final double startingCash;
  final double totalSales;
  final double totalExpenses;
  final double expectedCash;
  final double actualCash;
  final double cashDifference;
  final String status;

  CashierShiftReportItem({
    required this.id,
    required this.cashierName,
    required this.warehouseName,
    required this.openedAt,
    this.closedAt,
    required this.startingCash,
    required this.totalSales,
    required this.totalExpenses,
    required this.expectedCash,
    required this.actualCash,
    required this.cashDifference,
    required this.status,
  });

  factory CashierShiftReportItem.fromJson(Map<String, dynamic> json) {
    final u = json['user'] ?? {};
    final w = json['warehouse'] ?? {};

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return CashierShiftReportItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cashierName: u['name'] ?? 'Kasir',
      warehouseName: w['name'] ?? 'Toko',
      openedAt: json['opened_at'] != null
          ? json['opened_at'].toString().split('T').first
          : '-',
      closedAt: json['closed_at']?.toString().split('T').first,
      startingCash: parseDouble(json['starting_cash']),
      totalSales: parseDouble(json['total_sales']),
      totalExpenses: parseDouble(json['total_expenses']),
      expectedCash: parseDouble(json['expected_cash']),
      actualCash: parseDouble(json['actual_cash']),
      cashDifference: parseDouble(json['cash_difference']),
      status: json['status'] ?? 'open',
    );
  }
}


