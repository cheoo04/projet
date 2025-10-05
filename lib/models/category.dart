class Category {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String iconName;
  final bool isActive;
  final DateTime createdAt;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.iconName,
    this.isActive = true,
    required this.createdAt,
    this.productCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconName': iconName,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'productCount': productCount,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      iconName: map['iconName'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      productCount: map['productCount'] ?? 0,
    );
  }
}
