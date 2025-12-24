import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../widgets/optimized_image.dart';

/// Section "Produits similaires" pour la page détail produit
class SimilarProductsSection extends StatelessWidget {
  final String currentProductId;
  final String category;
  final String? brand;
  final Function(String productId)? onProductTap;

  const SimilarProductsSection({
    Key? key,
    required this.currentProductId,
    required this.category,
    this.brand,
    this.onProductTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Trouver les produits similaires (même catégorie, différent du produit actuel)
        final similarProducts = _getSimilarProducts(productProvider.products);

        if (similarProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Produits similaires',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Naviguer vers le catalogue avec filtre catégorie
                      Navigator.pushNamed(
                        context,
                        '/catalog',
                        arguments: {'category': category},
                      );
                    },
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
            ),
            
            SizedBox(
              height: 320,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: similarProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _SimilarProductCard(
                    product: similarProducts[index],
                    isDark: isDark,
                    onTap: () {
                      if (onProductTap != null) {
                        onProductTap!(similarProducts[index].id);
                      } else {
                        Navigator.pushReplacementNamed(
                          context,
                          '/product-detail',
                          arguments: similarProducts[index].id,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Product> _getSimilarProducts(List<Product> allProducts) {
    // Filtrer les produits de la même catégorie (excluant le produit actuel)
    var similar = allProducts.where((p) => 
      p.id != currentProductId && 
      p.category.toLowerCase() == category.toLowerCase() &&
      p.isInStock
    ).toList();

    // Si même marque, prioriser
    if (brand != null) {
      final sameBrand = similar.where((p) => 
        p.brand.toLowerCase() == brand!.toLowerCase()
      ).toList();
      
      final otherBrands = similar.where((p) => 
        p.brand.toLowerCase() != brand!.toLowerCase()
      ).toList();
      
      similar = [...sameBrand, ...otherBrands];
    }

    // Limiter à 10 produits
    return similar.take(10).toList();
  }
}

/// Carte compacte pour les produits similaires
class _SimilarProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onTap;

  const _SimilarProductCard({
    required this.product,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = product.originalPrice != null && 
                        product.originalPrice! > product.price;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.secondaryVioletDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image avec badge promo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: ProductImage(
                      imageUrl: product.imageUrls.isNotEmpty
                          ? product.imageUrls.first
                          : 'https://via.placeholder.com/200',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                // Badge promo
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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

                // Badge stock limité
                if (product.stock > 0 && product.stock <= 5)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stock limité',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marque
                  Text(
                    product.brand,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Nom
                  Text(
                    product.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Prix
                  Row(
                    children: [
                      Text(
                        _formatPrice(product.price),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryViolet,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          _formatPrice(product.originalPrice!),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Rating si disponible
                  if (product.rating != null && product.rating!.count > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating!.average.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.rating!.count})',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} F';
  }
}

/// Variante avec mode grille pour écrans larges
class SimilarProductsGrid extends StatelessWidget {
  final List<Product> products;
  final Function(String productId)? onProductTap;

  const SimilarProductsGrid({
    Key? key,
    required this.products,
    this.onProductTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Vous aimerez aussi',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length.clamp(0, 4),
          itemBuilder: (context, index) {
            return _SimilarProductCard(
              product: products[index],
              isDark: isDark,
              onTap: () {
                if (onProductTap != null) {
                  onProductTap!(products[index].id);
                } else {
                  Navigator.pushReplacementNamed(
                    context,
                    '/product-detail',
                    arguments: products[index].id,
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}
