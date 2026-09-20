import '../../core/utils/currency_formatter.dart';

class DiscountModel {
  final int id;
  final String name;
  final String? code;
  final String type;
  final double value;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final double buyQty;
  final double getQty;
  final int? rewardProductId;
  final String? rewardProductName;
  final int? customerGroupId;
  final String? customerGroupName;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final bool isCombinable;
  final bool isActive;
  final String? description;
  final List<int> productIds;
  final List<String> productNames;

  DiscountModel({
    required this.id,
    required this.name,
    this.code,
    required this.type,
    this.value = 0,
    this.minOrderAmount = 0,
    this.maxDiscountAmount = 0,
    this.buyQty = 0,
    this.getQty = 0,
    this.rewardProductId,
    this.rewardProductName,
    this.customerGroupId,
    this.customerGroupName,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isCombinable = false,
    this.isActive = true,
    this.description,
    this.productIds = const [],
    this.productNames = const [],
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    List<int> pIds = [];
    List<String> pNames = [];

    if (json['items'] != null && json['items'] is List) {
      for (var item in json['items']) {
        if (item is Map<String, dynamic>) {
          if (item['product_id'] != null) {
            pIds.add(int.tryParse(item['product_id'].toString()) ?? 0);
          }
          if (item['product'] != null && item['product']['name'] != null) {
            pNames.add(item['product']['name'].toString());
          }
        }
      }
    }

    return DiscountModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
      type: json['type'] ?? 'percentage_item',
      value: double.tryParse(json['value']?.toString() ?? '0') ?? 0,
      minOrderAmount: double.tryParse(json['min_order_amount']?.toString() ?? '0') ?? 0,
      maxDiscountAmount: double.tryParse(json['max_discount_amount']?.toString() ?? '0') ?? 0,
      buyQty: double.tryParse(json['buy_qty']?.toString() ?? '0') ?? 0,
      getQty: double.tryParse(json['get_qty']?.toString() ?? '0') ?? 0,
      rewardProductId: json['reward_product_id'] != null
          ? int.tryParse(json['reward_product_id'].toString())
          : null,
      rewardProductName: json['reward_product'] != null
          ? json['reward_product']['name']
          : null,
      customerGroupId: json['customer_group_id'] != null
          ? int.tryParse(json['customer_group_id'].toString())
          : null,
      customerGroupName: json['customer_group'] != null
          ? json['customer_group']['name']
          : null,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      isCombinable: json['is_combinable'] == true || json['is_combinable'] == 1 || json['is_combinable'] == '1',
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      description: json['description'],
      productIds: pIds,
      productNames: pNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type,
      'value': value,
      'min_order_amount': minOrderAmount,
      'max_discount_amount': maxDiscountAmount,
      'buy_qty': buyQty,
      'get_qty': getQty,
      'reward_product_id': rewardProductId,
      'customer_group_id': customerGroupId,
      'start_date': startDate,
      'end_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
      'is_combinable': isCombinable,
      'is_active': isActive,
      'description': description,
      'product_ids': productIds,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'percentage_item':
        return 'Diskon % Item';
      case 'fixed_item':
        return 'Potongan Rp Item';
      case 'percentage_invoice':
        return 'Diskon % Nota';
      case 'fixed_invoice':
        return 'Potongan Rp Nota';
      case 'buy_x_get_y':
        return 'Buy X Get Y';
      default:
        return 'Diskon';
    }
  }

  String get valueFormatted {
    if (type == 'buy_x_get_y') {
      return 'Beli ${buyQty.toStringAsFixed(0)} Dapat ${getQty.toStringAsFixed(0)} Free';
    }
    if (type == 'percentage_item' || type == 'percentage_invoice') {
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}%';
    }
    return CurrencyFormatter.format(value);
  }

  bool get isExpired {
    if (endDate == null || endDate!.isEmpty) return false;
    try {
      final end = DateTime.parse(endDate!);
      final now = DateTime.now();
      return DateTime(end.year, end.month, end.day, 23, 59, 59).isBefore(now);
    } catch (_) {
      return false;
    }
  }
}
