class Product {
  String id;
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
    required this.isInStock,
  });
}
