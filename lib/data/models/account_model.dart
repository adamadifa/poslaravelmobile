class AccountModel {
  final int id;
  final String accountCode;
  final String name;
  final String type; // cash, bank, bank_agent, ppob_provider, other
  final String? accountNumber;
  final String? accountHolder;
  final String? bankName;
  final double openingBalance;
  final double currentBalance;
  final double alertMinimumBalance;
  final bool isDefault;
  final bool isActive;
  final String? description;

  AccountModel({
    required this.id,
    required this.accountCode,
    required this.name,
    required this.type,
    this.accountNumber,
    this.accountHolder,
    this.bankName,
    required this.openingBalance,
    required this.currentBalance,
    required this.alertMinimumBalance,
    required this.isDefault,
    required this.isActive,
    this.description,
  });

  bool get isLowBalance => alertMinimumBalance > 0 && currentBalance <= alertMinimumBalance;

  String get typeLabel {
    switch (type) {
      case 'cash':
        return 'Kas Fisik Laci';
      case 'bank':
        return 'Bank Operasional';
      case 'bank_agent':
        return 'Agen Bank / EDC';
      case 'ppob_provider':
        return 'Deposit PPOB';
      default:
        return 'Lainnya';
    }
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      accountCode: json['account_code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Akun Kas',
      type: json['type']?.toString() ?? 'cash',
      accountNumber: json['account_number']?.toString(),
      accountHolder: json['account_holder']?.toString(),
      bankName: json['bank_name']?.toString(),
      openingBalance: double.tryParse((json['opening_balance'] ?? 0).toString()) ?? 0.0,
      currentBalance: double.tryParse((json['current_balance'] ?? json['balance'] ?? 0).toString()) ?? 0.0,
      alertMinimumBalance: double.tryParse((json['alert_minimum_balance'] ?? 0).toString()) ?? 0.0,
      isDefault: json['is_default'] == true || json['is_default'] == 1 || json['is_default'] == '1',
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_code': accountCode,
      'name': name,
      'type': type,
      'account_number': accountNumber,
      'account_holder': accountHolder,
      'bank_name': bankName,
      'opening_balance': openingBalance,
      'alert_minimum_balance': alertMinimumBalance,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'description': description,
    };
  }
}
