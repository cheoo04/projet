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

class OrderStatusEntry {
  final OrderStatus status;
  final DateTime timestamp;

  OrderStatusEntry({required this.status, required this.timestamp});

  factory OrderStatusEntry.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return OrderStatusEntry(
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String?),
        orElse: () => OrderStatus.pending,
      ),
      timestamp: parseDate(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'status': status.name, 'timestamp': timestamp};
  }
}

class Order {
  final String id;
  final String userId;
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
  final List<OrderStatusEntry> statusHistory;
  final bool pointsCredited;
  final int? pointsEarned;
  final int pointsRedeemed;

  Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.statusHistory = const [],
    this.pointsCredited = false,
    this.pointsEarned,
    this.pointsRedeemed = 0,
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
      userId: map['userId'] as String? ?? '',
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
      statusHistory:
          (map['statusHistory'] as List<dynamic>?)
              ?.map(
                (entry) =>
                    OrderStatusEntry.fromMap(entry as Map<String, dynamic>),
              )
              .toList() ??
          [],
      pointsCredited: map['pointsCredited'] as bool? ?? false,
      pointsEarned: map['pointsEarned'] as int?,
      pointsRedeemed: map['pointsRedeemed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
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
      'statusHistory': statusHistory.map((entry) => entry.toMap()).toList(),
      'pointsCredited': pointsCredited,
      'pointsEarned': pointsEarned,
      'pointsRedeemed': pointsRedeemed,
    };
  }

  Order copyWith({
    String? userId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? updatedAt,
    String? notes,
    List<OrderStatusEntry>? statusHistory,
    bool? pointsCredited,
    int? pointsEarned,
    int? pointsRedeemed,
  }) {
    return Order(
      id: id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      statusHistory: statusHistory ?? this.statusHistory,
      pointsCredited: pointsCredited ?? this.pointsCredited,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
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