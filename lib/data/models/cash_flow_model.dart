import 'package:intl/intl.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';

class CashFlowModel {
  final int id;
  final String cashFlowNumber;
  final int accountId;
  final String type; // income | expense
  final String category;
  final double amount;
  final DateTime transactionDate;
  final String? referenceType;
  final int? referenceId;
  final String? description;
  final int? createdBy;
  final AccountModel? account;
  final String? creatorName;
  final DateTime? createdAt;

  CashFlowModel({
    required this.id,
    required this.cashFlowNumber,
    required this.accountId,
    required this.type,
    required this.category,
    required this.amount,
    required this.transactionDate,
    this.referenceType,
    this.referenceId,
    this.description,
    this.createdBy,
    this.account,
    this.creatorName,
    this.createdAt,
  });

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';
  bool get isAutomatic => referenceType != null && referenceType!.isNotEmpty;

  String get typeLabel => isIncome ? 'Kas Masuk' : 'Kas Keluar';

  String get formattedAmount => CurrencyFormatter.format(amount);

  String get formattedDate => AppDateFormatter.format(transactionDate);

  factory CashFlowModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['transaction_date'] != null) {
      parsedDate = DateTime.tryParse(json['transaction_date'].toString()) ?? DateTime.now();
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString());
    }

    return CashFlowModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      cashFlowNumber: json['cash_flow_number']?.toString() ?? '',
      accountId: int.tryParse(json['account_id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'income',
      category: json['category']?.toString() ?? 'Umum',
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
      transactionDate: parsedDate,
      referenceType: json['reference_type']?.toString(),
      referenceId: int.tryParse(json['reference_id']?.toString() ?? ''),
      description: json['description']?.toString(),
      createdBy: int.tryParse(json['created_by']?.toString() ?? ''),
      account: json['account'] != null ? AccountModel.fromJson(json['account']) : null,
      creatorName: json['creator'] != null ? json['creator']['name']?.toString() : null,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cash_flow_number': cashFlowNumber,
      'account_id': accountId,
      'type': type,
      'category': category,
      'amount': amount,
      'transaction_date': DateFormat('yyyy-MM-dd').format(transactionDate),
      'reference_type': referenceType,
      'reference_id': referenceId,
      'description': description,
    };
  }
}

class CashFlowSummary {
  final double totalIncome;
  final double totalExpense;
  final double netFlow;

  CashFlowSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netFlow,
  });

  String get formattedIncome => CurrencyFormatter.format(totalIncome);

  String get formattedExpense => CurrencyFormatter.format(totalExpense);

  String get formattedNetFlow => CurrencyFormatter.format(netFlow);

  factory CashFlowSummary.fromJson(Map<String, dynamic> json) {
    return CashFlowSummary(
      totalIncome: double.tryParse((json['total_income'] ?? 0).toString()) ?? 0.0,
      totalExpense: double.tryParse((json['total_expense'] ?? 0).toString()) ?? 0.0,
      netFlow: double.tryParse((json['net_flow'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class CashFlowResponseData {
  final List<CashFlowModel> cashFlows;
  final CashFlowSummary summary;
  final int currentPage;
  final int lastPage;
  final int total;

  CashFlowResponseData({
    required this.cashFlows,
    required this.summary,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory CashFlowResponseData.fromJson(Map<String, dynamic> json) {
    final list = (json['cash_flows'] as List? ?? [])
        .map((e) => CashFlowModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final summary = json['summary'] != null
        ? CashFlowSummary.fromJson(json['summary'] as Map<String, dynamic>)
        : CashFlowSummary(totalIncome: 0, totalExpense: 0, netFlow: 0);

    final pagination = json['pagination'] as Map<String, dynamic>?;

    return CashFlowResponseData(
      cashFlows: list,
      summary: summary,
      currentPage: pagination != null ? (int.tryParse(pagination['current_page']?.toString() ?? '1') ?? 1) : 1,
      lastPage: pagination != null ? (int.tryParse(pagination['last_page']?.toString() ?? '1') ?? 1) : 1,
      total: pagination != null ? (int.tryParse(pagination['total']?.toString() ?? '0') ?? list.length) : list.length,
    );
  }
}
