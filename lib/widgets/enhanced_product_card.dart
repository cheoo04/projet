import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../models/product_extensions.dart';

/// ============================================================
/// ENHANCED PRODUCT CARD - Pour listes et détails
/// ============================================================
/// 
/// Usage recommandé :
/// - Listes verticales (ListView)
/// - Sections "Produits similaires"
/// - Mode compact pour listes horizontales
/// 
/// Fonctionnalités :
/// - Mode compact intégré (compact: true)
/// - Badge vérifié sur l'image
/// - Affichage de l'économie (-30 000 FCFA)
/// - Wishlist button configurable
/// - Design léger adapté aux listes
/// 
/// Voir aussi : OptimizedProductCard pour grilles de catalogue
/// ============================================================

/// Widget ProductCard optimisé avec signaux de confiance
/// Affiche : badges, prix barré, rating, livraison, garantie
/// 
/// Hiérarchie visuelle :
/// ┌─────────────────────────┐
/// │  [IMAGE PRODUIT]        │
/// │   Badge: "En stock" ✓   │ (vert en haut à droite)
/// │   Badge: "-15%" 🔴      │ (rouge en haut à gauche si promo)
/// │   ♡ Wishlist            │ (bas droite sur image)
/// ├─────────────────────────┤
/// │  Apple                  │ (marque, gris, petit)
/// │  AirPods Pro (2ème...)  │ (nom, gras, 2 lignes max)
/// │                         │
/// │  250 000 FCFA           │ (prix actuel, gras, violet)
/// │  280 000 FCFA           │ (prix barré si promo, gris)
/// │                         │
/// │  ⭐ 4.7 (128) • 432 vendus │ (social proof)
/// │                         │
/// │  🚚 2-3 jours • ✓ 12m   │ (signaux confiance)
/// └─────────────────────────┘
class EnhancedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToWishlist;
  final bool showWishlistButton;
  final bool compact;

  const EnhancedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToWishlist,
    this.showWishlistButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badges
            _buildImageSection(context),

            // Informations produit
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Marque
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Nom produit
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),

                    // Section prix
                    _buildPriceSection(context),
                    
                    if (!compact) ...[
                      const SizedBox(height: 6),
                      
                      // Social proof
                      _buildSocialProof(context),
                      
                      const SizedBox(height: 6),
                      
                      // Signaux de confiance
                      _buildTrustSignals(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section image avec badges
  Widget _buildImageSection(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          // Image produit
          Positioned.fill(
            child: product.imageUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.phone_android,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.phone_android,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  ),
          ),

          // Badge promo (haut gauche)
          if (product.discountPercent != null && product.discountPercent! > 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${product.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Badge stock (haut droite)
          Positioned(
            top: 8,
            right: 8,
            child: _buildStockBadge(),
          ),

          // Bouton wishlist (bas droite)
          if (showWishlistButton)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: onAddToWishlist,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            
          // Badge vérifié (si authentifié)
          if (product.authenticity.verified)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'Vérifié',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Badge de statut du stock
  Widget _buildStockBadge() {
    final status = product.stockStatus;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            status == StockStatus.lowStock 
                ? 'Reste ${product.stock}' 
                : status.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Section prix avec prix barré si promo
  Widget _buildPriceSection(BuildContext context) {
    final hasPromo = product.originalPrice != null && 
                     product.originalPrice! > product.price;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prix actuel
        Text(
          '${_formatPrice(product.price)} FCFA',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryViolet,
          ),
        ),
        
        // Prix barré si promo
        if (hasPromo)
          Row(
            children: [
              Text(
                '${_formatPrice(product.originalPrice!)} FCFA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '-${_formatPrice(product.savings!)} FCFA',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Social proof : rating + ventes
  Widget _buildSocialProof(BuildContext context) {
    final hasRating = product.rating != null && product.rating!.count > 0;
    final hasSales = product.soldCount > 0;
    
    if (!hasRating && !hasSales) return const SizedBox.shrink();
    
    return Row(
      children: [
        // Rating
        if (hasRating) ...[
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            product.rating!.average.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' (${product.rating!.count})',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
        
        // Séparateur
        if (hasRating && hasSales)
          Text(
            ' • ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        
        // Ventes
        if (hasSales)
          Text(
            '${product.soldCount} vendus',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  /// Signaux de confiance compacts
  Widget _buildTrustSignals(BuildContext context) {
    return Row(
      children: [
        // Livraison
        Icon(
          Icons.local_shipping_outlined,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 3),
        Text(
          product.shipping.delayText,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        
        Text(
          ' • ',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        
        // Garantie
        Icon(
          Icons.verified_outlined,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 3),
        Text(
          '${product.warranty.months}m',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        
        // Livraison gratuite
        if (product.shipping.isFree) ...[
          Text(
            ' • ',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const Icon(
            Icons.check_circle,
            size: 12,
            color: AppTheme.success,
          ),
          const SizedBox(width: 2),
          const Text(
            'Gratuit',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Formate le prix avec séparateur de milliers
  String _formatPrice(double price) {
    final priceInt = price.toInt();
    return priceInt.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

/// Version compacte pour les listes horizontales
class CompactProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final double width;

  const CompactProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: EnhancedProductCard(
        product: product,
        onTap: onTap,
        showWishlistButton: false,
        compact: true,
      ),
    );
  }
}
