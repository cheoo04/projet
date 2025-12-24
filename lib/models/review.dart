/// Avis client sur un produit
class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
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
  final int helpfulCount;          // Nombre de "utile"
  final String? response;          // Réponse du vendeur
  final DateTime? responseAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
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
    this.helpfulCount = 0,
    this.response,
    this.responseAt,
  });

  /// Formatage de la date relative
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return 'Il y a ${(difference.inDays / 365).floor()} an${(difference.inDays / 365).floor() > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  /// Initiales du nom pour l'avatar
  String get initials {
    final parts = userName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
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
      'helpfulCount': helpfulCount,
      'response': response,
      'responseAt': responseAt?.millisecondsSinceEpoch,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    // Helper pour parser les dates (Timestamp ou int)
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is DateTime) return value;
      // Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }
    
    return Review(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonyme',
      userPhotoUrl: map['userPhotoUrl'],
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      isModerated: map['isModerated'] ?? false,
      isApproved: map['isApproved'] ?? false,
      moderatorId: map['moderatorId'],
      moderatorNote: map['moderatorNote'],
      moderatedAt: parseDate(map['moderatedAt']),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isVerifiedPurchase: map['isVerifiedPurchase'] ?? false,
      helpfulCount: map['helpfulCount'] ?? 0,
      response: map['response'],
      responseAt: parseDate(map['responseAt']),
    );
  }
}
