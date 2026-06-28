import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_extensions.dart';
import '../providers/promotion_provider.dart';
import 'trust_signal_card.dart';

/// ============================================================
/// OPTIMIZED PRODUCT CARD - Pour grilles de catalogue
/// ============================================================
/// 
/// Usage recommandé :
/// - Grilles de produits (GridView)
/// - Résultats de recherche
/// - Pages de catégories
/// 
/// Fonctionnalités :
/// - Taille configurable (width, height)
/// - État favoris (isFavorite, onFavorite)
/// - Tous les badges (promo, NEW, BESTSELLER, etc.)
/// - Chips de confiance (ShippingChip, WarrantyChip)
/// - Inclut ProductGrid pour usage rapide
/// 
/// Voir aussi : EnhancedProductCard pour listes verticales
/// ============================================================

/// Carte produit optimisée pour le catalogue
/// Affiche les signaux de confiance : stock, rating, livraison, garantie
class OptimizedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double? width;
  final double? height;

  const OptimizedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWidth = width ?? 180.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badges
            _buildImageSection(cardWidth),
            
            // Contenu texte
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Marque + nom
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Prix
                    _buildPriceSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'image réseau avec fallback pour le web et retry automatique
  Widget _buildNetworkImage(String imageUrl) {
    // Sur web, utiliser Image.network avec retry
    if (kIsWeb) {
      return _RetryNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
      );
    }
    
    // Sur mobile, utiliser CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
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
          size: 50,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildImageSection(double cardWidth) {
    // Réduire la hauteur de l'image pour éviter l'overflow
    final imageHeight = cardWidth * 0.65;
    final badges = product.allBadges;
    
    // Debug: afficher l'URL de l'image
    if (product.imageUrls.isNotEmpty) {
      debugPrint('🖼️ Product ${product.name} - Image URL: ${product.imageUrls.first}');
    }
    
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: product.imageUrls.isNotEmpty
                ? _buildNetworkImage(product.imageUrls.first)
                : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.phone_android,
                      size: 50,
                      color: Colors.grey[400],
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

        // Badge promo (haut gauche)
        if (product.discountPercent != null && product.discountPercent! > 0)
          Positioned(
            top: 8,
            left: 8,
            child: PromoBadge(
              discountPercent: product.discountPercent!,
              small: true,
            ),
          ),

        // Autres badges (sous le badge promo)
        if (badges.where((b) => b.type != 'PROMO').isNotEmpty)
          Positioned(
            top: product.discountPercent != null ? 36 : 8,
            left: 8,
            child: _buildOtherBadges(badges),
          ),

        // Bouton favoris (bas droite)
        Positioned(
          bottom: 8,
          right: 8,
          child: _buildFavoriteButton(),
        ),
      ],
    );
  }

  Widget _buildStockBadge() {
    final status = product.stockStatus;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            status == StockStatus.lowStock 
                ? 'Reste ${product.stock}'
                : status.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherBadges(List<ProductBadge> badges) {
    final otherBadges = badges.where((b) => b.type != 'PROMO').take(1).toList();
    if (otherBadges.isEmpty) return const SizedBox.shrink();
    
    final badge = otherBadges.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badge.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badge.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavorite,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFavorite ? Colors.red : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    // Utiliser PromotionProvider pour calculer le prix effectif (avec fallback)
    double effectivePrice = product.price;
    bool hasPromoFromProvider = false;
    
    try {
      final promotionProvider = context.read<PromotionProvider>();
      effectivePrice = promotionProvider.getEffectivePrice(product);
      hasPromoFromProvider = effectivePrice < product.price;
    } catch (_) {
      // Provider non disponible, utiliser les valeurs du produit
    }
    
    final originalPrice = product.price;
    final hasDiscount = hasPromoFromProvider || 
        (product.originalPrice != null && product.originalPrice! > product.price);
    final displayOriginalPrice = product.originalPrice ?? originalPrice;
    final displayCurrentPrice = hasPromoFromProvider ? effectivePrice : product.price;
    
    // Layout simplifié pour éviter l'overflow
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Prix actuel
        Flexible(
          child: Text(
            '${_formatPrice(displayCurrentPrice)} F',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9B6DB8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Prix original barré (compact)
        if (hasDiscount) ...[
          const SizedBox(width: 4),
          Text(
            '${_formatPrice(displayOriginalPrice)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialProof() {
    final hasRating = product.rating != null && product.rating!.count > 0;
    final hasSoldCount = product.soldCount > 0;
    
    if (!hasRating && !hasSoldCount) {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        // Rating
        if (hasRating) ...[
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 2),
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
              color: Colors.grey[500],
            ),
          ),
        ],
        
        // Séparateur
        if (hasRating && hasSoldCount)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '•',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        
        // Vendus
        if (hasSoldCount)
          Text(
            '${_formatSoldCount(product.soldCount)} vendus',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildTrustChips() {
    return Row(
      children: [
        // Garantie seulement
        WarrantyChip(
          months: product.warranty.months,
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String _formatSoldCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

/// Version compacte de la carte pour les listes horizontales
/// Version compacte simplifiée pour l'accueil
/// Affiche uniquement : image, badge promo, marque, nom et prix
class CompactProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final double width;

  const CompactProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.width = 165,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge promo seulement - ratio 4:3 pour laisser place au contenu
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: product.imageUrls.isNotEmpty
                          ? (kIsWeb 
                              ? _RetryNetworkImage(
                                  imageUrl: product.imageUrls.first,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: product.imageUrls.first,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.phone_android),
                                  ),
                                ))
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.phone_android),
                            ),
                    ),
                  ),
                  
                  // Badge promo uniquement (haut gauche)
                  if (product.discountPercent != null && product.discountPercent! > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: PromoBadge(
                        discountPercent: product.discountPercent!,
                        small: true,
                      ),
                    ),
                ],
              ),
            ),
            
            // Contenu simplifié - flex 2 pour garantir l'espace
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Marque
                  Text(
                    product.brand,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  
                  // Nom produit
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Prix avec contrainte pour éviter overflow
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9B6DB8),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 1),
                          child: Text(
                            'FCFA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9B6DB8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

/// Grid de produits avec ProductCard optimisées
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product)? onProductTap;
  final Function(Product)? onFavorite;
  final Set<String> favorites;
  final int crossAxisCount;
  final EdgeInsets padding;

  const ProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onFavorite,
    this.favorites = const {},
    this.crossAxisCount = 2,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.55,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return OptimizedProductCard(
          product: product,
          onTap: () => onProductTap?.call(product),
          onFavorite: () => onFavorite?.call(product),
          isFavorite: favorites.contains(product.id),
        );
      },
    );
  }
}

/// Widget d'image réseau avec retry automatique pour le web
/// Réessaie jusqu'à 3 fois en cas d'échec avec délai croissant
class _RetryNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final int maxRetries;

  const _RetryNetworkImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.maxRetries = 3,
  });

  @override
  State<_RetryNetworkImage> createState() => _RetryNetworkImageState();
}

class _RetryNetworkImageState extends State<_RetryNetworkImage> {
  int _retryCount = 0;
  bool _hasError = false;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.imageUrl;
  }

  void _retry() {
    if (_retryCount < widget.maxRetries && mounted) {
      setState(() {
        _retryCount++;
        _hasError = false;
        _isLoading = true;
        // Ajouter un paramètre unique pour forcer le rechargement
        _currentUrl = '${widget.imageUrl}${widget.imageUrl.contains('?') ? '&' : '?'}retry=$_retryCount';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _retryCount >= widget.maxRetries) {
      return Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.phone_android,
          size: 50,
          color: Colors.grey[400],
        ),
      );
    }

    return Image.network(
      _currentUrl,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Image chargée avec succès
          if (_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isLoading = false);
            });
          }
          return child;
        }
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Retry après un délai croissant
        if (_retryCount < widget.maxRetries) {
          Future.delayed(Duration(milliseconds: 500 * (_retryCount + 1)), () {
            if (mounted && !_hasError) {
              _retry();
            }
          });
          // Afficher le loading pendant le retry
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        
        // Après tous les retries, afficher le placeholder
        if (!_hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hasError = true);
          });
        }
        return Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.phone_android,
            size: 50,
            color: Colors.grey[400],
          ),
        );
      },
    );
  }
}