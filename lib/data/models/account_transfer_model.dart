import 'package:intl/intl.dart';
import 'package:poslaravelmobile/core/utils/currency_formatter.dart';
import 'package:poslaravelmobile/core/utils/date_formatter.dart';
import 'package:poslaravelmobile/data/models/account_model.dart';

class AccountTransferModel {
  final int id;
  final String transferNumber;
  final int fromAccountId;
  final int toAccountId;
  final double amount;
  final double transferFee;
  final DateTime transferDate;
  final String? referenceNumber;
  final String? notes;
  final int? createdBy;
  final AccountModel? fromAccount;
  final AccountModel? toAccount;
  final String? creatorName;
  final DateTime? createdAt;

  AccountTransferModel({
    required this.id,
    required this.transferNumber,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.transferFee,
    required this.transferDate,
    this.referenceNumber,
    this.notes,
    this.createdBy,
    this.fromAccount,
    this.toAccount,
    this.creatorName,
    this.createdAt,
  });

  double get totalDeduction => amount + transferFee;

  String get formattedAmount => CurrencyFormatter.format(amount);
  String get formattedFee => CurrencyFormatter.format(transferFee);
  String get formattedTotalDeduction => CurrencyFormatter.format(totalDeduction);
  String get formattedDate => AppDateFormatter.format(transferDate);

  factory AccountTransferModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['transfer_date'] != null) {
      parsedDate = DateTime.tryParse(json['transfer_date'].toString()) ?? DateTime.now();
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString());
    }

    return AccountTransferModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      transferNumber: json['transfer_number']?.toString() ?? '',
      fromAccountId: int.tryParse(json['from_account_id']?.toString() ?? '0') ?? 0,
      toAccountId: int.tryParse(json['to_account_id']?.toString() ?? '0') ?? 0,
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
      transferFee: double.tryParse((json['transfer_fee'] ?? 0).toString()) ?? 0.0,
      transferDate: parsedDate,
      referenceNumber: json['reference_number']?.toString(),
      notes: json['notes']?.toString(),
      createdBy: int.tryParse(json['created_by']?.toString() ?? ''),
      fromAccount: json['from_account'] != null ? AccountModel.fromJson(json['from_account']) : null,
      toAccount: json['to_account'] != null ? AccountModel.fromJson(json['to_account']) : null,
      creatorName: json['creator'] != null ? json['creator']['name']?.toString() : null,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transfer_number': transferNumber,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'transfer_fee': transferFee,
      'transfer_date': DateFormat('yyyy-MM-dd').format(transferDate),
      'reference_number': referenceNumber,
      'notes': notes,
    };
  }
}

class AccountTransferSummary {
  final double totalTransferred;
  final double totalFee;

  AccountTransferSummary({
    required this.totalTransferred,
    required this.totalFee,
  });

  String get formattedTotalTransferred => CurrencyFormatter.format(totalTransferred);
  String get formattedTotalFee => CurrencyFormatter.format(totalFee);

  factory AccountTransferSummary.fromJson(Map<String, dynamic> json) {
    return AccountTransferSummary(
      totalTransferred: double.tryParse((json['total_transferred'] ?? 0).toString()) ?? 0.0,
      totalFee: double.tryParse((json['total_fee'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class AccountTransferResponseData {
  final List<AccountTransferModel> transfers;
  final AccountTransferSummary summary;
  final int currentPage;
  final int lastPage;
  final int total;

  AccountTransferResponseData({
    required this.transfers,
    required this.summary,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory AccountTransferResponseData.fromJson(Map<String, dynamic> json) {
    final list = (json['transfers'] as List? ?? [])
        .map((e) => AccountTransferModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final summary = json['summary'] != null
        ? AccountTransferSummary.fromJson(json['summary'] as Map<String, dynamic>)
        : AccountTransferSummary(totalTransferred: 0, totalFee: 0);

    final pagination = json['pagination'] as Map<String, dynamic>?;

    return AccountTransferResponseData(
      transfers: list,
      summary: summary,
      currentPage: pagination != null ? (int.tryParse(pagination['current_page']?.toString() ?? '1') ?? 1) : 1,
      lastPage: pagination != null ? (int.tryParse(pagination['last_page']?.toString() ?? '1') ?? 1) : 1,
      total: pagination != null ? (int.tryParse(pagination['total']?.toString() ?? '0') ?? list.length) : list.length,
    );
  }
}
