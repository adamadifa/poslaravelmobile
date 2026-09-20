import 'package:flutter/material.dart';

class StockTransferItemModel {
  final int id;
  final int stockTransferId;
  final int productId;
  final String productName;
  final String? productCode;
  final int unitId;
  final String unitName;
  final double quantitySent;
  final double quantityReceived;
  final double baseQuantitySent;
  final double baseQuantityReceived;
  final double unitCost;
  final String? batchNumber;

  StockTransferItemModel({
    required this.id,
    required this.stockTransferId,
    required this.productId,
    required this.productName,
    this.productCode,
    required this.unitId,
    this.unitName = 'Pcs',
    required this.quantitySent,
    required this.quantityReceived,
    required this.baseQuantitySent,
    required this.baseQuantityReceived,
    required this.unitCost,
    this.batchNumber,
  });

  factory StockTransferItemModel.fromJson(Map<String, dynamic> json) {
    String pName = 'Produk #${json['product_id']}';
    String? pCode;
    String uName = 'Pcs';

    if (json['product'] != null && json['product'] is Map) {
      pName = json['product']['name']?.toString() ?? pName;
      pCode = json['product']['code']?.toString();
      if (json['product']['base_unit'] != null && json['product']['base_unit'] is Map) {
        uName = json['product']['base_unit']['short_name']?.toString() ??
            json['product']['base_unit']['name']?.toString() ??
            uName;
      }
    }

    if (json['unit'] != null && json['unit'] is Map) {
      uName = json['unit']['short_name']?.toString() ??
          json['unit']['name']?.toString() ??
          uName;
    }

    return StockTransferItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      stockTransferId: int.tryParse(json['stock_transfer_id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: pName,
      productCode: pCode,
      unitId: int.tryParse(json['unit_id']?.toString() ?? '0') ?? 1,
      unitName: uName,
      quantitySent: double.tryParse(json['quantity_sent']?.toString() ?? '0') ?? 0,
      quantityReceived: double.tryParse(json['quantity_received']?.toString() ?? '0') ?? 0,
      baseQuantitySent: double.tryParse(json['base_quantity_sent']?.toString() ?? '0') ?? 0,
      baseQuantityReceived: double.tryParse(json['base_quantity_received']?.toString() ?? '0') ?? 0,
      unitCost: double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0,
      batchNumber: json['batch_number']?.toString(),
    );
  }

  double get lineTotalCost => quantitySent * unitCost;
}

class StockTransferModel {
  final int id;
  final String transferNumber;
  final int fromWarehouseId;
  final String fromWarehouseName;
  final int toWarehouseId;
  final String toWarehouseName;
  final String transferDate;
  final String status; // 'draft', 'in_transit', 'completed', 'cancelled'
  final String? notes;
  final int? sentBy;
  final String? senderName;
  final String? sentAt;
  final int? receivedBy;
  final String? receiverName;
  final String? receivedAt;
  final List<StockTransferItemModel> items;

  StockTransferModel({
    required this.id,
    required this.transferNumber,
    required this.fromWarehouseId,
    required this.fromWarehouseName,
    required this.toWarehouseId,
    required this.toWarehouseName,
    required this.transferDate,
    required this.status,
    this.notes,
    this.sentBy,
    this.senderName,
    this.sentAt,
    this.receivedBy,
    this.receiverName,
    this.receivedAt,
    required this.items,
  });

  factory StockTransferModel.fromJson(Map<String, dynamic> json) {
    String fromName = 'Gudang Asal';
    if (json['from_warehouse'] != null && json['from_warehouse'] is Map) {
      fromName = json['from_warehouse']['name']?.toString() ?? fromName;
    }

    String toName = 'Gudang Tujuan';
    if (json['to_warehouse'] != null && json['to_warehouse'] is Map) {
      toName = json['to_warehouse']['name']?.toString() ?? toName;
    }

    String? sName;
    if (json['sender'] != null && json['sender'] is Map) {
      sName = json['sender']['name']?.toString();
    }

    String? rName;
    if (json['receiver'] != null && json['receiver'] is Map) {
      rName = json['receiver']['name']?.toString();
    }

    List<StockTransferItemModel> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      for (var item in json['items']) {
        if (item is Map<String, dynamic>) {
          itemList.add(StockTransferItemModel.fromJson(item));
        }
      }
    }

    return StockTransferModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      transferNumber: json['transfer_number']?.toString() ?? 'TRF-DRAFT',
      fromWarehouseId: int.tryParse(json['from_warehouse_id']?.toString() ?? '0') ?? 0,
      fromWarehouseName: fromName,
      toWarehouseId: int.tryParse(json['to_warehouse_id']?.toString() ?? '0') ?? 0,
      toWarehouseName: toName,
      transferDate: json['transfer_date']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'draft',
      notes: json['notes']?.toString(),
      sentBy: json['sent_by'] != null ? int.tryParse(json['sent_by'].toString()) : null,
      senderName: sName,
      sentAt: json['sent_at']?.toString(),
      receivedBy: json['received_by'] != null ? int.tryParse(json['received_by'].toString()) : null,
      receiverName: rName,
      receivedAt: json['received_at']?.toString(),
      items: itemList,
    );
  }

  int get totalItemsCount => items.length;

  double get totalQuantitySent => items.fold(0.0, (sum, i) => sum + i.quantitySent);

  double get totalQuantityReceived => items.fold(0.0, (sum, i) => sum + i.quantityReceived);

  double get totalValuation => items.fold(0.0, (sum, i) => sum + i.lineTotalCost);

  bool get isDraft => status == 'draft';
  bool get isInTransit => status == 'in_transit';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'in_transit':
        return 'Dalam Pengiriman (In Transit)';
      case 'completed':
        return 'Selesai Diterima';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return const Color(0xFF64748B);
      case 'in_transit':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'draft':
        return const Color(0xFFF1F5F9);
      case 'in_transit':
        return const Color(0xFFEFF6FF);
      case 'completed':
        return const Color(0xFFECFDF5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}
