class DiningTableModel {
  final int id;
  final int? warehouseId;
  final String? warehouseName;
  final String tableNumber;
  final String? area;
  final int capacity;
  final String status;
  final int? currentSaleId;
  final int sortOrder;
  final bool isActive;

  DiningTableModel({
    required this.id,
    this.warehouseId,
    this.warehouseName,
    required this.tableNumber,
    this.area,
    this.capacity = 4,
    this.status = 'available',
    this.currentSaleId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
  bool get isCleaning => status == 'cleaning';

  factory DiningTableModel.fromJson(Map<String, dynamic> json) {
    String? whName;
    if (json['warehouse'] is Map<String, dynamic>) {
      whName = json['warehouse']['name']?.toString();
    }

    return DiningTableModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      warehouseId: json['warehouse_id'] != null ? int.tryParse(json['warehouse_id'].toString()) : null,
      warehouseName: whName,
      tableNumber: json['table_number']?.toString() ?? '',
      area: json['area']?.toString(),
      capacity: int.tryParse((json['capacity'] ?? 4).toString()) ?? 4,
      status: json['status']?.toString() ?? 'available',
      currentSaleId: json['current_sale_id'] != null
          ? int.tryParse(json['current_sale_id'].toString())
          : null,
      sortOrder: int.tryParse((json['sort_order'] ?? 0).toString()) ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'warehouse_id': warehouseId,
    'table_number': tableNumber,
    'area': area,
    'capacity': capacity,
    'status': status,
    'current_sale_id': currentSaleId,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
}
