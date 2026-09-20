class ShiftExpenseModel {
  final int id;
  final int cashierShiftId;
  final double amount;
  final String category;
  final String? notes;
  final String? expenseDate;
  final String? userName;

  ShiftExpenseModel({
    required this.id,
    required this.cashierShiftId,
    required this.amount,
    required this.category,
    this.notes,
    this.expenseDate,
    this.userName,
  });

  factory ShiftExpenseModel.fromJson(Map<String, dynamic> json) {
    return ShiftExpenseModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      cashierShiftId: json['cashier_shift_id'] is int
          ? json['cashier_shift_id']
          : int.tryParse(json['cashier_shift_id'].toString()) ?? 0,
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
      category: json['category'] ?? '',
      notes: json['notes'],
      expenseDate: json['expense_date']?.toString(),
      userName: json['user'] != null && json['user'] is Map<String, dynamic>
          ? json['user']['name']
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cashier_shift_id': cashierShiftId,
    'amount': amount,
    'category': category,
    'notes': notes,
    'expense_date': expenseDate,
  };
}

class ShiftModel {
  final int id;
  final int userId;
  final int warehouseId;
  final String? warehouseName;
  final String? userName;
  final double startingCash;
  final double totalSales;
  final double totalCashSales;
  final double totalNonCashSales;
  final int totalTransactions;
  final double totalExpenses;
  final double expectedCash;
  final double? actualCash;
  final double? difference;
  final double totalAgentCashIn;
  final double totalAgentCashOut;
  final double totalAgentProfit;
  final int ppobCount;
  final double ppobSales;
  final double ppobProfit;
  final int bankTransferCount;
  final int bankWithdrawalCount;
  final double bankAgentFee;
  final double bankAgentProfit;
  final String status;
  final String? openedAt;
  final String? closedAt;
  final String? notes;
  final List<ShiftExpenseModel> expenses;

  ShiftModel({
    required this.id,
    required this.userId,
    required this.warehouseId,
    this.warehouseName,
    this.userName,
    required this.startingCash,
    this.totalSales = 0.0,
    this.totalCashSales = 0.0,
    this.totalNonCashSales = 0.0,
    this.totalTransactions = 0,
    this.totalExpenses = 0.0,
    required this.expectedCash,
    this.actualCash,
    this.difference,
    this.totalAgentCashIn = 0.0,
    this.totalAgentCashOut = 0.0,
    this.totalAgentProfit = 0.0,
    this.ppobCount = 0,
    this.ppobSales = 0.0,
    this.ppobProfit = 0.0,
    this.bankTransferCount = 0,
    this.bankWithdrawalCount = 0,
    this.bankAgentFee = 0.0,
    this.bankAgentProfit = 0.0,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.notes,
    this.expenses = const [],
  });

  bool get isOpen => status == 'open';

  // Total gross cashier flow calculation
  double get totalDrawerCash => expectedCash;

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    List<ShiftExpenseModel> expList = [];
    if (json['expenses'] != null && json['expenses'] is List) {
      expList = (json['expenses'] as List)
          .map((e) => ShiftExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final ppob = json['ppob_summary'] is Map<String, dynamic> ? json['ppob_summary'] : null;
    final agent = json['agent_summary'] is Map<String, dynamic> ? json['agent_summary'] : null;

    return ShiftModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      warehouseId: json['warehouse_id'] is int
          ? json['warehouse_id']
          : int.tryParse(json['warehouse_id'].toString()) ?? 0,
      warehouseName: json['warehouse_name'] ?? (json['warehouse'] != null && json['warehouse'] is Map<String, dynamic>
          ? json['warehouse']['name']
          : null),
      userName: json['user_name'] ?? (json['user'] != null && json['user'] is Map<String, dynamic>
          ? json['user']['name']
          : null),
      startingCash: double.tryParse((json['starting_cash'] ?? 0).toString()) ?? 0.0,
      totalSales: double.tryParse((json['total_sales'] ?? 0).toString()) ?? 0.0,
      totalCashSales: double.tryParse((json['total_cash_sales'] ?? 0).toString()) ?? 0.0,
      totalNonCashSales: double.tryParse((json['total_non_cash_sales'] ?? 0).toString()) ?? 0.0,
      totalTransactions: int.tryParse((json['total_transactions'] ?? 0).toString()) ?? 0,
      totalExpenses: double.tryParse((json['total_expenses'] ?? 0).toString()) ?? 0.0,
      expectedCash: double.tryParse((json['expected_cash'] ?? 0).toString()) ?? 0.0,
      actualCash: json['actual_cash'] != null || json['closing_cash'] != null
          ? double.tryParse((json['actual_cash'] ?? json['closing_cash']).toString())
          : null,
      difference: json['difference'] != null || json['cash_difference'] != null
          ? double.tryParse((json['difference'] ?? json['cash_difference']).toString())
          : null,
      totalAgentCashIn: double.tryParse((json['total_agent_cash_in'] ?? 0).toString()) ?? 0.0,
      totalAgentCashOut: double.tryParse((json['total_agent_cash_out'] ?? 0).toString()) ?? 0.0,
      totalAgentProfit: double.tryParse((json['total_agent_profit'] ?? 0).toString()) ?? 0.0,
      ppobCount: ppob != null ? (int.tryParse(ppob['count']?.toString() ?? '0') ?? 0) : 0,
      ppobSales: ppob != null ? (double.tryParse(ppob['total_sales']?.toString() ?? '0') ?? 0.0) : 0.0,
      ppobProfit: ppob != null ? (double.tryParse(ppob['total_profit']?.toString() ?? '0') ?? 0.0) : 0.0,
      bankTransferCount: agent != null ? (int.tryParse(agent['transfer_count']?.toString() ?? '0') ?? 0) : 0,
      bankWithdrawalCount: agent != null ? (int.tryParse(agent['withdrawal_count']?.toString() ?? '0') ?? 0) : 0,
      bankAgentFee: agent != null ? (double.tryParse(agent['total_fee']?.toString() ?? '0') ?? 0.0) : 0.0,
      bankAgentProfit: agent != null ? (double.tryParse(agent['total_profit']?.toString() ?? '0') ?? 0.0) : 0.0,
      status: json['status'] ?? 'open',
      openedAt: json['opened_at']?.toString() ?? json['created_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
      notes: json['notes'],
      expenses: expList,
    );
  }
}
