import 'package:cloud_firestore/cloud_firestore.dart';

enum StockMovementType {
  entry, // Entrée de stock
  exit, // Sortie de stock
  adjustment, // Ajustement manuel
  sale, // Vente
  return_, // Retour
  damaged, // Produit endommagé
  increase, // Alias pour entry (augmentation)
  decrease, // Alias pour exit (diminution)
}

class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int quantity; // Positif pour entrée, négatif pour sortie
  final int stockBefore; // Stock avant le mouvement
  final int stockAfter; // Stock après le mouvement
  final String reason; // Raison du mouvement
  final String? orderId; // ID de commande si lié à une vente
  final String? supplierId; // ID fournisseur si lié à un approvisionnement
  final String userId; // Utilisateur qui a effectué le mouvement
  final String userName;
  final DateTime createdAt;
  final DateTime date; // Alias pour createdAt
  final Map<String, dynamic> metadata; // Données supplémentaires

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    required this.reason,
    this.orderId,
    this.supplierId,
    required this.userId,
    required this.userName,
    DateTime? createdAt,
    DateTime? date,
    this.metadata = const {},
  }) : createdAt = createdAt ?? date ?? DateTime.now(),
       date = date ?? createdAt ?? DateTime.now();

  // Getters utiles
  bool get isEntry => quantity > 0;
  bool get isExit => quantity < 0;
  int get absoluteQuantity => quantity.abs();

  String get typeDisplayName {
    switch (type) {
      case StockMovementType.entry:
      case StockMovementType.increase:
        return 'Entrée de stock';
      case StockMovementType.exit:
      case StockMovementType.decrease:
        return 'Sortie de stock';
      case StockMovementType.adjustment:
        return 'Ajustement';
      case StockMovementType.sale:
        return 'Vente';
      case StockMovementType.return_:
        return 'Retour';
      case StockMovementType.damaged:
        return 'Endommagé';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'stockBefore': stockBefore,
      'stockAfter': stockAfter,
      'reason': reason,
      'orderId': orderId,
      'supplierId': supplierId,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'stockBefore': stockBefore,
      'stockAfter': stockAfter,
      'reason': reason,
      'orderId': orderId,
      'supplierId': supplierId,
      'userId': userId,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map, String docId) {
    return StockMovement(
      id: docId,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      type: _parseStockMovementType(map['type']),
      quantity: map['quantity'] ?? 0,
      stockBefore: map['stockBefore'] ?? 0,
      stockAfter: map['stockAfter'] ?? 0,
      reason: map['reason'] ?? '',
      orderId: map['orderId'],
      supplierId: map['supplierId'],
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  factory StockMovement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockMovement(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      type: _parseStockMovementType(data['type']),
      quantity: data['quantity'] ?? 0,
      stockBefore: data['stockBefore'] ?? 0,
      stockAfter: data['stockAfter'] ?? 0,
      reason: data['reason'] ?? '',
      orderId: data['orderId'],
      supplierId: data['supplierId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  static StockMovementType _parseStockMovementType(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'entry':
        return StockMovementType.entry;
      case 'exit':
        return StockMovementType.exit;
      case 'adjustment':
        return StockMovementType.adjustment;
      case 'sale':
        return StockMovementType.sale;
      case 'return_':
      case 'return':
        return StockMovementType.return_;
      case 'damaged':
        return StockMovementType.damaged;
      default:
        return StockMovementType.adjustment;
    }
  }

  StockMovement copyWith({
    String? productId,
    String? productName,
    StockMovementType? type,
    int? quantity,
    int? stockBefore,
    int? stockAfter,
    String? reason,
    String? orderId,
    String? supplierId,
    String? userId,
    String? userName,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return StockMovement(
      id: id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      stockBefore: stockBefore ?? this.stockBefore,
      stockAfter: stockAfter ?? this.stockAfter,
      reason: reason ?? this.reason,
      orderId: orderId ?? this.orderId,
      supplierId: supplierId ?? this.supplierId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
