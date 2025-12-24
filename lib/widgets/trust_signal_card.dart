import 'package:flutter/material.dart';
import 'safe_network_avatar.dart';

/// Widget réutilisable pour afficher un signal de confiance
/// Utilisé dans la section "Vos garanties" de la page produit
class TrustSignalCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? extra;
  final VoidCallback? onTap;

  const TrustSignalCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.extra,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône avec fond coloré
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 14),

            // Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  if (extra != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      extra!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Chevron si cliquable
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Section complète "Vos garanties" avec tous les signaux de confiance
class TrustSignalsSection extends StatelessWidget {
  final bool freeShipping;
  final String shippingDelay;
  final int warrantyMonths;
  final String warrantyType;
  final int returnDays;
  final bool freeReturn;
  final bool isVerified;
  final String? verifiedSource;

  const TrustSignalsSection({
    super.key,
    this.freeShipping = false,
    this.shippingDelay = '3-5 jours',
    this.warrantyMonths = 12,
    this.warrantyType = 'revendeur',
    this.returnDays = 7,
    this.freeReturn = true,
    this.isVerified = false,
    this.verifiedSource,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.grey[900]?.withOpacity(0.5) 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(
            children: [
              Icon(
                Icons.verified_user,
                size: 20,
                color: const Color(0xFF9B6DB8),
              ),
              const SizedBox(width: 8),
              Text(
                'Vos garanties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Livraison
          TrustSignalCard(
            icon: Icons.local_shipping_outlined,
            iconColor: const Color(0xFF3B82F6),
            title: 'Livraison $shippingDelay',
            subtitle: freeShipping 
                ? 'Gratuite dès 150 000 FCFA' 
                : 'Frais selon destination',
            extra: 'Suivi en temps réel',
          ),

          Divider(color: Colors.grey[300], height: 1),

          // Garantie
          TrustSignalCard(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF16A34A),
            title: warrantyType == 'constructeur'
                ? 'Garantie constructeur $warrantyMonths mois'
                : 'Garantie revendeur $warrantyMonths mois',
            subtitle: isVerified && verifiedSource != null
                ? verifiedSource!
                : 'Défauts de fabrication',
            extra: 'Service après-vente disponible',
          ),

          Divider(color: Colors.grey[300], height: 1),

          // Retour
          TrustSignalCard(
            icon: Icons.replay_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: freeReturn 
                ? 'Retour gratuit sous $returnDays jours' 
                : 'Retour sous $returnDays jours',
            subtitle: 'Produit non ouvert',
          ),

          Divider(color: Colors.grey[300], height: 1),

          // Paiement sécurisé
          TrustSignalCard(
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF9B6DB8),
            title: 'Paiement 100% sécurisé',
            subtitle: 'Vos données sont protégées',
            extra: 'Achat protégé',
          ),
        ],
      ),
    );
  }
}

/// Widget d'étoiles de notation
class RatingStars extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;
  final bool compact;

  const RatingStars({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 16,
    this.showCount = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Étoiles
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          if (rating >= starValue) {
            icon = Icons.star;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(
            icon,
            size: size,
            color: Colors.amber,
          );
        }),

        // Texte de notation
        if (showCount && count > 0) ...[
          const SizedBox(width: 6),
          Text(
            compact 
                ? '(${_formatCount(count)})' 
                : '${rating.toStringAsFixed(1)} ($count avis)',
            style: TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

/// Badge de promotion
class PromoBadge extends StatelessWidget {
  final int discountPercent;
  final bool small;

  const PromoBadge({
    super.key,
    required this.discountPercent,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(small ? 4 : 6),
      ),
      child: Text(
        '-$discountPercent%',
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget prix avec ancien prix barré
class PriceDisplay extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final bool large;
  final bool showSavings;

  const PriceDisplay({
    super.key,
    required this.price,
    this.originalPrice,
    this.large = false,
    this.showSavings = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = originalPrice != null && originalPrice! > price;
    final savings = hasDiscount ? originalPrice! - price : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Prix actuel
            Text(
              _formatPrice(price),
              style: TextStyle(
                fontSize: large ? 28 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9B6DB8),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'FCFA',
              style: TextStyle(
                fontSize: large ? 16 : 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9B6DB8),
              ),
            ),

            // Prix original barré
            if (hasDiscount) ...[
              const SizedBox(width: 10),
              Text(
                '${_formatPrice(originalPrice!)} FCFA',
                style: TextStyle(
                  fontSize: large ? 16 : 13,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),

        // Économie
        if (showSavings && hasDiscount) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Économisez ${_formatPrice(savings)} FCFA',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

/// Chip de livraison compact
class ShippingChip extends StatelessWidget {
  final String delay;
  final bool isFree;

  const ShippingChip({
    super.key,
    required this.delay,
    this.isFree = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 12,
            color: Color(0xFF3B82F6),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              isFree ? 'Gratuit' : delay,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B82F6),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de garantie compact
class WarrantyChip extends StatelessWidget {
  final int months;

  const WarrantyChip({
    super.key,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified,
            size: 12,
            color: Color(0xFF16A34A),
          ),
          const SizedBox(width: 3),
          Text(
            '${months}m',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher un avis client
class ReviewCard extends StatelessWidget {
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final String timeAgo;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final VoidCallback? onHelpful;
  final List<String> imageUrls;

  const ReviewCard({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.timeAgo,
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.onHelpful,
    this.imageUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header : Avatar + Nom + Date
          Row(
            children: [
              // Avatar
              SafeNetworkAvatar(
                imageUrl: userPhotoUrl,
                fallbackText: userName,
                radius: 20,
              ),
              const SizedBox(width: 12),
              
              // Nom + Verified
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerifiedPurchase) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Color(0xFF16A34A),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Achat vérifié',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Étoiles
          RatingStars(
            rating: rating,
            showCount: false,
            size: 18,
          ),
          
          const SizedBox(height: 10),
          
          // Commentaire
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.4,
            ),
          ),
          
          // Images de l'avis (si présentes)
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrls[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Bouton "Utile"
          if (onHelpful != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: onHelpful,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          helpfulCount > 0 
                              ? 'Utile ($helpfulCount)'
                              : 'Utile',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Section d'avis clients avec distribution
class ReviewsSection extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;
  final List<Widget> reviewCards;
  final VoidCallback? onSeeAll;
  final VoidCallback? onAddReview;

  const ReviewsSection({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    this.distribution = const {},
    this.reviewCards = const [],
    this.onSeeAll,
    this.onAddReview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avis clients',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (onSeeAll != null && totalReviews > 3)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text('Voir tous ($totalReviews)'),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Résumé des notes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey[900]?.withValues(alpha: 0.5) 
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Note moyenne
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9B6DB8),
                      ),
                    ),
                    RatingStars(
                      rating: averageRating,
                      showCount: false,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews avis',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 24),
                
                // Distribution
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final stars = 5 - index;
                      final count = distribution[stars] ?? 0;
                      final percentage = totalReviews > 0 
                          ? (count / totalReviews) 
                          : 0.0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$stars',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: isDark 
                                      ? Colors.grey[700] 
                                      : Colors.grey[300],
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.amber,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton ajouter un avis
          if (onAddReview != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Donner mon avis'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF9B6DB8)),
                  foregroundColor: const Color(0xFF9B6DB8),
                ),
              ),
            ),
          ],
          
          // Liste des avis
          if (reviewCards.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...reviewCards,
          ] else if (totalReviews == 0) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun avis pour le moment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Soyez le premier à donner votre avis !',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
