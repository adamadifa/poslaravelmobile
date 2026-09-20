import 'package:poslaravelmobile/data/models/account_model.dart';

class PpobProductModel {
  final int id;
  final String category; // pulsa, paket_data, token_pln, ewallet, tagihan, other
  final String? provider; // Telkomsel, Indosat, XL, PLN, DANA, dll
  final String code;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final int? defaultAccountId;
  final AccountModel? defaultAccount;
  final bool isActive;
  final String? description;

  PpobProductModel({
    required this.id,
    required this.category,
    this.provider,
    required this.code,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    this.defaultAccountId,
    this.defaultAccount,
    required this.isActive,
    this.description,
  });

  double get margin => sellingPrice - costPrice;
  double get marginPercentage => costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0.0;

  String get categoryLabel {
    switch (category) {
      case 'pulsa':
        return 'Pulsa Reguler';
      case 'paket_data':
        return 'Paket Data / Kuota';
      case 'token_pln':
        return 'Token Listrik PLN';
      case 'ewallet':
        return 'Top Up E-Wallet';
      case 'tagihan':
        return 'Tagihan Pascabayar';
      default:
        return 'Lainnya';
    }
  }

  factory PpobProductModel.fromJson(Map<String, dynamic> json) {
    return PpobProductModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      category: json['category']?.toString() ?? 'pulsa',
      provider: json['provider']?.toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Produk PPOB',
      costPrice: double.tryParse((json['cost_price'] ?? 0).toString()) ?? 0.0,
      sellingPrice: double.tryParse((json['selling_price'] ?? 0).toString()) ?? 0.0,
      defaultAccountId: int.tryParse(json['default_account_id']?.toString() ?? ''),
      defaultAccount: json['default_account'] != null && json['default_account'] is Map
          ? AccountModel.fromJson(json['default_account'])
          : null,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'provider': provider,
      'code': code,
      'name': name,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'default_account_id': defaultAccountId,
      'is_active': isActive ? 1 : 0,
      'description': description,
    };
  }
}
