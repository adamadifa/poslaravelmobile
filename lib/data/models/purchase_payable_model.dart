import 'purchase_receipt_model.dart';

class PurchasePayableData {
  final double totalOutstanding;
  final List<PurchaseReceiptModel> payables;

  PurchasePayableData({
    required this.totalOutstanding,
    required this.payables,
  });

  factory PurchasePayableData.fromJson(Map<String, dynamic> json) {
    List<PurchaseReceiptModel> list = [];
    if (json['payables'] != null && json['payables'] is List) {
      for (var item in json['payables']) {
        if (item is Map<String, dynamic>) {
          list.add(PurchaseReceiptModel.fromJson(item));
        }
      }
    }

    return PurchasePayableData(
      totalOutstanding: double.tryParse(json['total_outstanding']?.toString() ?? '0') ?? 0,
      payables: list,
    );
  }
}
