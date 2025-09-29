class Product {
  final String id;
  String name;
  String category; // 'phone', 'accessory', 'screen', 'pc'
  String brand; // 'Apple', 'Samsung', 'HP', etc.
  double price;
  String description;
  List<String> imageUrls;
  bool isInStock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    required this.description,
    required this.imageUrls,
    this.isInStock = true,
  });

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] as String? ?? '',
      imageUrls: List<String>.from(map['imageUrls'] as List<dynamic>? ?? []),
      isInStock: map['isInStock'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'brand': brand,
      'price': price,
      'description': description,
      'imageUrls': imageUrls,
      'isInStock': isInStock,
    };
  }

  bool get isOutOfStock => !isInStock;
}
