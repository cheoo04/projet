class Product {
  final String id;
  final String name;
  final String category; // 'phone', 'accessory', 'screen', 'pc'
  final String brand; // 'Apple', 'Samsung', 'HP', etc.
  final double price;
  final String description;
  final List<String> imageUrls;
  final bool isInStock;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.isInStock,
  });
}
