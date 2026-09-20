class AccountMutationModel {
  final int id;
  final int accountId;
  final int? userId;
  final String? userName;
  final String mutationType; // debit (keluar) vs credit (masuk)
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? description;
  final DateTime? createdAt;

  AccountMutationModel({
    required this.id,
    required this.accountId,
    this.userId,
    this.userName,
    required this.mutationType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.description,
    this.createdAt,
  });

  bool get isCredit => mutationType.toLowerCase() == 'credit';
  bool get isDebit => mutationType.toLowerCase() == 'debit';

  factory AccountMutationModel.fromJson(Map<String, dynamic> json) {
    return AccountMutationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      accountId: int.tryParse(json['account_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? ''),
      userName: json['user']?['name']?.toString(),
      mutationType: json['mutation_type']?.toString() ?? 'debit',
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
      balanceBefore: double.tryParse((json['balance_before'] ?? 0).toString()) ?? 0.0,
      balanceAfter: double.tryParse((json['balance_after'] ?? 0).toString()) ?? 0.0,
      referenceType: json['reference_type']?.toString(),
      referenceId: int.tryParse(json['reference_id']?.toString() ?? ''),
      description: json['description']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
