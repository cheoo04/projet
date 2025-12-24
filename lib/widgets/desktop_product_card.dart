import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_extensions.dart';
import '../providers/promotion_provider.dart';
import 'trust_signal_card.dart';

/// ============================================================
/// DESKTOP PRODUCT CARD - Version étendue pour écrans larges
/// ============================================================
/// 
/// Usage recommandé :
/// - Grilles desktop (4-5 colonnes)
/// - Affichage enrichi avec plus d'informations
/// 
/// Différences avec OptimizedProductCard :
/// - Taille plus grande
/// - Affiche rating et nombre de ventes
/// - Bouton "Ajouter au panier" visible
/// - Description courte visible
/// - Hover effects
/// ============================================================

class DesktopProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const DesktopProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  State<DesktopProductCard> createState() => _DesktopProductCardState();
}

class _DesktopProductCardState extends State<DesktopProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          transform: _isHovered 
              ? (Matrix4.identity()..translate(0, -4, 0))
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section avec badges
              _buildImageSection(isDark),
              
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Marque et rating
                      _buildBrandAndRating(isDark),
                      const SizedBox(height: 6),
                      
                      // Nom produit
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Description courte (seulement si assez d'espace)
                      if (widget.product.shortDescription != null) ...[
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            widget.product.shortDescription!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Prix et bouton
                      _buildPriceAndAction(isDark),
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

  /// Construit l'image réseau avec fallback pour le web et retry automatique
  Widget _buildNetworkImage(String imageUrl, bool isDark) {
    // Sur web, utiliser le widget avec retry
    if (kIsWeb) {
      return _RetryNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        isDark: isDark,
      );
    }
    
    // Sur mobile, utiliser CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        child: Icon(
          Icons.phone_android,
          size: 60,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    final badges = widget.product.allBadges;
    
    return Stack(
      children: [
        // Image - utilise Expanded pour prendre l'espace disponible
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AspectRatio(
            aspectRatio: 1.0, // Ratio carré pour meilleure adaptation
            child: widget.product.imageUrls.isNotEmpty
                ? _buildNetworkImage(widget.product.imageUrls.first, isDark)
                : Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.phone_android,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
          ),
        ),

        // Badge stock (haut droite)
        Positioned(
          top: 12,
          right: 12,
          child: _buildStockBadge(),
        ),

        // Badge promo (haut gauche)
        if (widget.product.discountPercent != null && widget.product.discountPercent! > 0)
          Positioned(
            top: 12,
            left: 12,
            child: PromoBadge(
              discountPercent: widget.product.discountPercent!,
              small: false,
            ),
          ),

        // Autres badges (sous le badge promo)
        if (badges.where((b) => b.type != 'PROMO').isNotEmpty)
          Positioned(
            top: widget.product.discountPercent != null ? 48 : 12,
            left: 12,
            child: _buildOtherBadges(badges),
          ),

        // Bouton favoris (bas droite)
        Positioned(
          bottom: 12,
          right: 12,
          child: _buildFavoriteButton(),
        ),
        
        // Overlay au hover
        if (_isHovered)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBrandAndRating(bool isDark) {
    final hasRating = widget.product.rating != null && widget.product.rating!.count > 0;
    
    return Row(
      children: [
        // Marque - avec contrainte de taille max
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.product.brand,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        
        // Rating - plus compact
        if (hasRating) ...[
          const SizedBox(width: 8),
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            widget.product.rating!.average.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            ' (${widget.product.rating!.count})',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockBadge() {
    final status = widget.product.stockStatus;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            status == StockStatus.lowStock 
                ? 'Reste ${widget.product.stock}'
                : status.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherBadges(List<ProductBadge> badges) {
    final otherBadges = badges.where((b) => b.type != 'PROMO').take(2).toList();
    if (otherBadges.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final badge in otherBadges)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badge.color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: widget.onFavorite,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isHovered 
              ? const Color(0xFF9B6DB8).withOpacity(0.1)
              : Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 22,
          color: widget.isFavorite ? Colors.red : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildPriceAndAction(bool isDark) {
    // Utiliser PromotionProvider pour calculer le prix effectif (avec fallback)
    double effectivePrice = widget.product.price;
    bool hasPromoFromProvider = false;
    
    try {
      final promotionProvider = context.read<PromotionProvider>();
      effectivePrice = promotionProvider.getEffectivePrice(widget.product);
      hasPromoFromProvider = effectivePrice < widget.product.price;
    } catch (_) {
      // Provider non disponible, utiliser les valeurs du produit
    }
    
    final originalPrice = widget.product.price;
    final hasDiscount = hasPromoFromProvider || 
        (widget.product.originalPrice != null && widget.product.originalPrice! > widget.product.price);
    final displayOriginalPrice = widget.product.originalPrice ?? originalPrice;
    final displayCurrentPrice = hasPromoFromProvider ? effectivePrice : widget.product.price;
    
    return Row(
      children: [
        // Prix
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Prix original barré
              if (hasDiscount)
                Text(
                  '${_formatPrice(displayOriginalPrice)} FCFA',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              
              // Prix actuel
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(displayCurrentPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9B6DB8),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'FCFA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9B6DB8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Bouton ajouter au panier - compact
        SizedBox(
          width: 44,
          height: 44,
          child: ElevatedButton(
            onPressed: widget.product.stock > 0 ? widget.onAddToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B6DB8),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _isHovered ? 4 : 0,
            ),
            child: const Icon(Icons.add_shopping_cart, size: 20),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

/// Grille de produits responsive qui utilise DesktopProductCard sur desktop
class ResponsiveProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(Product)? onAddToCart;
  final Function(Product)? onFavorite;
  final Set<String>? favoriteIds;
  final EdgeInsetsGeometry? padding;
  final bool isDesktop;

  const ResponsiveProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.onAddToCart,
    this.onFavorite,
    this.favoriteIds,
    this.padding,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isDesktop ? 4 : 2;
    final childAspectRatio = isDesktop ? 0.65 : 0.68;
    
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: isDesktop ? 24 : 12,
        mainAxisSpacing: isDesktop ? 24 : 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isFavorite = favoriteIds?.contains(product.id) ?? false;
        
        if (isDesktop) {
          return DesktopProductCard(
            product: product,
            onTap: () => onProductTap(product),
            onAddToCart: onAddToCart != null ? () => onAddToCart!(product) : null,
            onFavorite: onFavorite != null ? () => onFavorite!(product) : null,
            isFavorite: isFavorite,
          );
        }
        
        // Version mobile - utiliser OptimizedProductCard existant
        return _MobileProductCard(
          product: product,
          onTap: () => onProductTap(product),
          onFavorite: onFavorite != null ? () => onFavorite!(product) : null,
          isFavorite: isFavorite,
        );
      },
    );
  }
}

/// Version simplifiée pour mobile (wrapper)
class _MobileProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const _MobileProductCard({
    required this.product,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    // Réutilise la logique de OptimizedProductCard sans dépendance
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.phone_android, size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.phone_android, size: 40),
                      ),
              ),
            ),
            
            // Contenu
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${product.price.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9B6DB8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget d'image réseau avec retry automatique pour le web
class _RetryNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final bool isDark;
  final int maxRetries;

  const _RetryNetworkImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.isDark = false,
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
        _currentUrl = '${widget.imageUrl}${widget.imageUrl.contains('?') ? '&' : '?'}retry=$_retryCount';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? Colors.grey[800] : Colors.grey[200];
    
    if (_hasError && _retryCount >= widget.maxRetries) {
      return Container(
        color: bgColor,
        child: Icon(
          Icons.phone_android,
          size: 60,
          color: Colors.grey[400],
        ),
      );
    }

    return Image.network(
      _currentUrl,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          if (_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isLoading = false);
            });
          }
          return child;
        }
        return Container(
          color: bgColor,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (_retryCount < widget.maxRetries) {
          Future.delayed(Duration(milliseconds: 500 * (_retryCount + 1)), () {
            if (mounted && !_hasError) {
              _retry();
            }
          });
          return Container(
            color: bgColor,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        
        if (!_hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hasError = true);
          });
        }
        return Container(
          color: bgColor,
          child: Icon(
            Icons.phone_android,
            size: 60,
            color: Colors.grey[400],
          ),
        );
      },
    );
  }
}
