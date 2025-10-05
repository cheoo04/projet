class Product {
  final String id;
  String name;
  String category; // 'phone', 'accessory', 'screen', 'pc'
  String brand; // 'Apple', 'Samsung', 'HP', etc.
  double price;
  String description;
  List<String> imageUrls;
  bool isInStock;
  int stock;
  String supplierReference; // Référence fournisseur (GTIN/MPN)
  Map<String, String> specs; // Spécifications techniques (poids, dimensions…)
  DateTime createdAt; // Date de création ou mise en ligne

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    required this.description,
    required this.imageUrls,
    this.isInStock = true,
    this.stock = 0,
    this.supplierReference = '',
    this.specs = const {}, // valeur par défaut vide
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] as String? ?? '',
      imageUrls: List<String>.from(map['imageUrls'] as List<dynamic>? ?? []),
      isInStock: map['isInStock'] as bool? ?? true,
      stock: map['stock'] as int? ?? 0, // ← Lecture du stock
      supplierReference: map['supplierReference'] as String? ?? '',
      specs: Map<String, String>.from(map['specs'] as Map? ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'brand': brand,
    'price': price,
    'description': description,
    'imageUrls': imageUrls,
    'isInStock': isInStock,
    'stock': stock, // ← Ajout au Map
    'supplierReference': supplierReference,
    'specs': specs,
    'createdAt': createdAt.toIso8601String(),
  };

  bool get isOutOfStock => !isInStock;
}
