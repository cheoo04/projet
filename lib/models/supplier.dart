class Supplier {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String contact;
  final String website;
  final bool isActive;
  final DateTime createdAt;
  final List<String> productIds;
  final Map<String, dynamic> paymentTerms;
  final double rating;

  Supplier({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.contact,
    this.website = '',
    this.isActive = true,
    required this.createdAt,
    this.productIds = const [],
    this.paymentTerms = const {},
    this.rating = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'contact': contact,
      'website': website,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'productIds': productIds,
      'paymentTerms': paymentTerms,
      'rating': rating,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      contact: map['contact'] ?? '',
      website: map['website'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      productIds: List<String>.from(map['productIds'] ?? []),
      paymentTerms: Map<String, dynamic>.from(map['paymentTerms'] ?? {}),
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }
}
