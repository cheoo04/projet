class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;
  final bool isModerated;
  final bool isApproved;
  final String? moderatorId;
  final String? moderatorNote;
  final DateTime? moderatedAt;
  final List<String> imageUrls;
  final bool isVerifiedPurchase;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isModerated = false,
    this.isApproved = false,
    this.moderatorId,
    this.moderatorNote,
    this.moderatedAt,
    this.imageUrls = const [],
    this.isVerifiedPurchase = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isModerated': isModerated,
      'isApproved': isApproved,
      'moderatorId': moderatorId,
      'moderatorNote': moderatorNote,
      'moderatedAt': moderatedAt?.millisecondsSinceEpoch,
      'imageUrls': imageUrls,
      'isVerifiedPurchase': isVerifiedPurchase,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isModerated: map['isModerated'] ?? false,
      isApproved: map['isApproved'] ?? false,
      moderatorId: map['moderatorId'],
      moderatorNote: map['moderatorNote'],
      moderatedAt: map['moderatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['moderatedAt'])
          : null,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isVerifiedPurchase: map['isVerifiedPurchase'] ?? false,
    );
  }
}
