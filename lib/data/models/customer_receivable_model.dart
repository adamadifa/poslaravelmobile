import 'sale_model.dart';

class CustomerReceivableData {
  final double totalOutstanding;
  final List<SaleModel> receivables;

  CustomerReceivableData({
    required this.totalOutstanding,
    required this.receivables,
  });

  factory CustomerReceivableData.fromJson(Map<String, dynamic> json) {
    List<SaleModel> list = [];
    if (json['receivables'] != null && json['receivables'] is List) {
      for (var item in json['receivables']) {
        if (item is Map<String, dynamic>) {
          list.add(SaleModel.fromJson(item));
        }
      }
    }

    return CustomerReceivableData(
      totalOutstanding: double.tryParse(json['total_outstanding']?.toString() ?? '0') ?? 0,
      receivables: list,
    );
  }
}
