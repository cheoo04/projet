import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  }) : totalPrice = unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}

class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  }) : totalAmount = items.fold(0, (somme, item) => somme + item.totalPrice);

  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    // Backward compatibility: createdAt / updatedAt may be stored as Timestamp (recommended) or ISO String (legacy)
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return Order(
      id: docId,
      customerName: map['customerName'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String?),
        orElse: () => OrderStatus.pending,
      ),
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      // Store as DateTime; Firestore plugin will serialize to Timestamp
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'notes': notes,
    };
  }

  Order copyWith({
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? updatedAt,
    String? notes,
  }) {
    return Order(
      id: id,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }
}

enum OrderStatus {
  pending('En attente', '⏳'),
  confirmed('Confirmée', '✅'),
  preparing('En préparation', '📦'),
  shipped('Expédiée', '🚚'),
  delivered('Livrée', '✨'),
  cancelled('Annulée', '❌');

  const OrderStatus(this.displayName, this.emoji);

  final String displayName;
  final String emoji;

  String get fullDisplay => '$emoji $displayName';
}
