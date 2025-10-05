class Promotion {
  final String id;
  String name;
  String description;
  List<String> productIds;
  String type; // 'percentage', 'fixed', 'bogo', 'free_shipping'
  double value;
  DateTime startDate;
  DateTime endDate;
  bool isActive;
  double? minimumAmount; // Montant minimum d'achat pour appliquer la promo
  String? promoCode; // Code promo optionnel
  int maxUses; // Nombre maximum d'utilisations (0 = illimité)
  int currentUses; // Nombre d'utilisations actuelles
  List<String> applicableProductIds; // Produits spécifiques
  List<String> applicableCategoryIds; // Catégories applicables

  Promotion({
    required this.id,
    required this.name,
    this.description = '',
    required this.productIds,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.minimumAmount,
    this.promoCode,
    this.maxUses = 0,
    this.currentUses = 0,
    this.applicableProductIds = const [],
    this.applicableCategoryIds = const [],
  });

  factory Promotion.fromMap(Map<String, dynamic> map, String docId) {
    return Promotion(
      id: docId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      productIds: List<String>.from(map['productIds'] as List? ?? []),
      type: map['type'] as String? ?? 'fixed',
      value: (map['value'] ?? 0).toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      isActive: map['isActive'] as bool? ?? true,
      minimumAmount: map['minimumAmount'] != null
          ? (map['minimumAmount'] as num).toDouble()
          : null,
      promoCode: map['promoCode'] as String?,
      maxUses: map['maxUses'] as int? ?? 0,
      currentUses: map['currentUses'] as int? ?? 0,
      applicableProductIds: List<String>.from(
        map['applicableProductIds'] as List? ?? [],
      ),
      applicableCategoryIds: List<String>.from(
        map['applicableCategoryIds'] as List? ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'productIds': productIds,
      'type': type,
      'value': value,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'minimumAmount': minimumAmount,
      'promoCode': promoCode,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'applicableProductIds': applicableProductIds,
      'applicableCategoryIds': applicableCategoryIds,
    };
  }

  // Vérifier si la promotion est actuellement valide
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (maxUses == 0 || currentUses < maxUses);
  }

  // Calculer le prix après remise
  double calculateDiscountedPrice(double originalPrice) {
    if (!isCurrentlyActive) return originalPrice;

    if (type == 'percentage') {
      return originalPrice * (1 - value / 100);
    } else if (type == 'fixed') {
      return (originalPrice - value).clamp(0, double.infinity);
    }
    return originalPrice;
  }

  // Obtenir le texte d'affichage de la remise
  String get discountText {
    if (type == 'percentage') {
      return '-${value.toStringAsFixed(0)}%';
    } else if (type == 'fixed') {
      return '-${value.toStringAsFixed(0)} FCFA';
    } else if (type == 'bogo') {
      return 'Achetez-en 1, obtenez-en ${value.toInt()}';
    } else if (type == 'free_shipping') {
      return 'Livraison gratuite';
    }
    return '';
  }
}
