class PaymentModel {
  final int id;
  final String paymentNumber;
  final String paymentType;
  final int accountId;
  final String accountName;
  final int? payableId;
  final String payableType;
  final int? supplierId;
  final String? supplierName;
  final int? customerId;
  final String? customerName;
  final String paymentDate;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String? createdByName;

  PaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.paymentType,
    required this.accountId,
    required this.accountName,
    this.payableId,
    required this.payableType,
    this.supplierId,
    this.supplierName,
    this.customerId,
    this.customerName,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    this.createdByName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    String accName = 'Kas/Bank';
    if (json['account'] != null && json['account'] is Map) {
      accName = json['account']['name']?.toString() ?? accName;
    }

    String? supName;
    if (json['supplier'] != null && json['supplier'] is Map) {
      supName = json['supplier']['name']?.toString();
    }

    String? cusName;
    if (json['customer'] != null && json['customer'] is Map) {
      cusName = json['customer']['name']?.toString();
    }

    String? creator;
    if (json['creator'] != null && json['creator'] is Map) {
      creator = json['creator']['name']?.toString();
    }

    return PaymentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      paymentNumber: json['payment_number']?.toString() ?? 'PAY-0000',
      paymentType: json['payment_type']?.toString() ?? 'payable',
      accountId: int.tryParse(json['account_id']?.toString() ?? '0') ?? 0,
      accountName: accName,
      payableId: json['payable_id'] != null ? int.tryParse(json['payable_id'].toString()) : null,
      payableType: json['payable_type']?.toString() ?? '',
      supplierId: json['supplier_id'] != null ? int.tryParse(json['supplier_id'].toString()) : null,
      supplierName: supName,
      customerId: json['customer_id'] != null ? int.tryParse(json['customer_id'].toString()) : null,
      customerName: cusName,
      paymentDate: json['payment_date']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      referenceNumber: json['reference_number']?.toString(),
      notes: json['notes']?.toString(),
      createdByName: creator,
    );
  }
}
