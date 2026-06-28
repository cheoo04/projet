import '../services/product_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_toast.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_theme.dart';
import '../widgets/ui_components.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/styled_dialogs.dart';
import '../widgets/optimized_image.dart';
import '../widgets/trust_signal_card.dart';
import '../widgets/variant_selector.dart';
import '../widgets/similar_products_section.dart';
import '../widgets/add_review_dialog.dart';
import '../widgets/comparison_banner.dart';
import '../widgets/responsive_scaffold.dart';
import '../models/product.dart';
import '../models/product_extensions.dart';
import '../models/review.dart';
import '../providers/app_providers.dart';
import '../services/favorites_service.dart';
import '../services/share_service.dart';
import '../services/review_service.dart';
import '../web_config/navigation_helper.dart';
import 'all_reviews_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Écran de détail produit avec design moderne
class ModernProductDetailScreen extends StatefulWidget {
  final String productId;
  
  const ModernProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ModernProductDetailScreen> createState() => _ModernProductDetailScreenState();
}

class _ModernProductDetailScreenState extends State<ModernProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  Product? _product;
  bool _isLoading = true;
  bool _isFavorite = false;
  
  // Variantes sélectionnées
  Map<String, ProductVariant?> _selectedVariants = {};
  int _priceAdjustment = 0;
  
  // Avis réels depuis Firestore
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  StreamSubscription<Product>? _productSub;
  
  @override
  void initState() {
    super.initState();
    _loadProduct();
    _subscribeToProductStream();
  }
  
  /// Charger le produit depuis Firestore
  Future<void> _loadProduct() async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Si les produits ne sont pas chargés, les charger
      if (productProvider.products.isEmpty) {
        await productProvider.loadProducts();
      }
      
      // Trouver le produit
      final product = productProvider.products.firstWhere(
        (p) => p.id == widget.productId,
        orElse: () => throw Exception('Produit non trouvé'),
      );

      // Vérifier si le produit est en favoris
      // catchError : si l'auth anonyme n'est pas encore prête au refresh,
      // on affiche quand même le produit sans crash
      bool isFav = false;
      try {
        isFav = await FavoritesService.isFavorite(product.id);
      } catch (_) {
        // Auth pas encore prête — pas grave, on réessaie si l'utilisateur
        // interagit avec le bouton favoris
      }
      
      setState(() {
        _product = product;
        _isFavorite = isFav;
        _isLoading = false;
      });
      
      // Charger les avis depuis Firestore
      _loadReviews();
    } catch (e) {
      if (mounted) {
        // Ne passer en état d'erreur que si le stream n'a pas déjà
        // fourni le produit entre-temps
        if (_product == null) {
          setState(() {
            _isLoading = false;
          });
          AppToast.error(context, 'Impossible de charger ce produit.');
        }
      }
    }
  }
  
  /// Charger les avis depuis Firestore
  Future<void> _loadReviews() async {
    if (_product == null) return;
    
    setState(() => _isLoadingReviews = true);
    
    try {
      final reviews = await ReviewService.fetchProductReviews(
        _product!.id,
        limit: 5,
        approvedOnly: true,
      );
      
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  void _subscribeToProductStream() {
    // Cancel existing
    _productSub?.cancel();
    _productSub = ProductService()
        .getProductStream(widget.productId)
        .listen((updatedProduct) {
      if (!mounted) return;
      setState(() {
        _product = updatedProduct;
        _isLoading = false; // stream a fourni le produit
      });
    }, onError: (err) {
      debugPrint('Erreur stream produit: $err');
    });
  }
  
  /// Basculer l'état favori
  Future<void> _toggleFavorite() async {
    if (_product == null) return;
    
    final newState = await FavoritesService.toggleFavorite(_product!.id);
    
    setState(() {
      _isFavorite = newState;
    });
    
    if (mounted) {
      CustomSnackBar.show(
        context,
        message: newState 
            ? '${_product!.name} ajouté aux favoris ❤️'
            : '${_product!.name} retiré des favoris',
        type: newState ? SnackBarType.success : SnackBarType.info,
      );
    }
  }

  /// Ajouter ou retirer le produit de la comparaison
  void _toggleComparison(BuildContext context) {
    if (_product == null) return;

    final comparison = context.read<ComparisonProvider>();
    final product = _product!;

    if (comparison.contains(product.id)) {
      comparison.remove(product.id);
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '${product.name} retiré de la comparaison',
          type: SnackBarType.info,
        );
      }
      return;
    }

    final result = comparison.add(product.id, product.category);

    if (!mounted) return;

    switch (result) {
      case ComparisonAddResult.alreadyFull:
        CustomSnackBar.show(
          context,
          message:
              'Maximum ${ComparisonProvider.maxProducts} produits en comparaison',
          type: SnackBarType.error,
        );
        break;
      case ComparisonAddResult.categoryMismatch:
        CustomSnackBar.show(
          context,
          message:
              "Vous comparez déjà des produits d'une autre catégorie. "
              'Videz la comparaison pour changer.',
          type: SnackBarType.error,
        );
        break;
      case ComparisonAddResult.added:
        CustomSnackBar.show(
          context,
          message: '${product.name} ajouté à la comparaison',
          type: SnackBarType.success,
        );
        break;
    }
  }
  
  /// Partager le produit
  Future<void> _shareProduct() async {
    if (_product == null) return;
    
    await ShareService.shareProduct(_product!, context);
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // États de chargement et erreur
    if (_isLoading) {
      return ResponsiveScaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_product == null) {
      return ResponsiveScaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Produit introuvable'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AppNavigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }
    
    final images = _product!.imageUrls.isNotEmpty 
        ? _product!.imageUrls 
        : ['https://via.placeholder.com/400x300'];
    
    return ResponsiveScaffold(
      showDesktopHeader: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar avec image et bouton retour
              _buildAppBar(context, isDark, images),

              // Contenu
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations principales
                    _buildProductInfo(context),
                    
                    // Sélecteur de variantes (couleur, stockage)
                    _buildVariantsSection(context),
                    
                    // Section Social Proof (rating + vendus)
                    _buildSocialProofSection(context),
                    
                    // Section Signaux de Confiance
                    _buildTrustSignalsSection(context),
                    
                    const Divider(height: 32),
                    
                    // Points forts
                    _buildHighlightsSection(context),
                    
                    // Description
                    _buildDescription(context),
                    
                    const Divider(height: 32),
                    
                    // Caractéristiques
                    _buildSpecifications(context),
                    
                    const Divider(height: 32),
                    
                    // Section Avis Clients
                    _buildReviewsSection(context),
                    
                    const Divider(height: 32),
                    
                    // Produits similaires
                    SimilarProductsSection(
                      currentProductId: _product!.id,
                      category: _product!.category,
                      brand: _product!.brand,
                      onProductTap: (productId) {
                        AppNavigator.toProductDetail(context, productId);
                      },
                    ),
                    
                    const SizedBox(height: 100), // Espace pour le bouton fixe
                  ],
                ),
              ),
            ],
          ),
          const ComparisonBanner(),
        ],
      ),
      
      // Boutons d'action fixes en bas
      bottomNavigationBar: _buildBottomActions(context, isDark),
    );
  }
  
  /// App Bar avec galerie d'images
  Widget _buildAppBar(BuildContext context, bool isDark, List<String> images) {
    final expandedHeight = (MediaQuery.of(context).size.height * 0.45).clamp(260.0, 400.0) as double;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: isDark ? AppTheme.secondaryVioletDark : Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => AppNavigator.pop(context),
      ),
      actions: [
        // Bouton Favoris
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isFavorite 
                  ? Colors.red.withOpacity(0.8)
                  : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
          ),
          onPressed: _toggleFavorite,
        ),
        // Bouton Comparer
        Builder(
          builder: (context) {
            final comparison = context.watch<ComparisonProvider>();
            final isInComparison =
                _product != null && comparison.contains(_product!.id);

            return IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isInComparison
                      ? AppTheme.primaryViolet.withOpacity(0.8)
                      : Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: Colors.white,
                ),
              ),
              onPressed: () => _toggleComparison(context),
            );
          },
        ),
        // Bouton Partage
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: _shareProduct,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Carrousel d'images
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return ProductImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
            
            // Indicateurs de page
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentImageIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentImageIndex
                          ? AppTheme.primaryViolet
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productSub?.cancel();
    super.dispose();
  }
  
  /// Informations principales du produit
  Widget _buildProductInfo(BuildContext context) {
    final theme = Theme.of(context);
    final product = _product!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marque et catégorie
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.brand,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryViolet,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.grey200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.category,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Nom du produit
          Text(
            product.name,
            style: theme.textTheme.displaySmall,
          ),
          
          const SizedBox(height: 12),
          
          // Prix avec promo
          PriceDisplay(
            price: product.price,
            originalPrice: product.originalPrice,
            large: true,
            showSavings: true,
          ),
          
          const SizedBox(height: 12),
          
          // Badge stock amélioré
          Row(
            children: [
              StockBadge(
                isInStock: product.isInStock,
                stock: product.stock,
                lowStockThreshold: product.lowStockThreshold,
              ),
              if (product.stock > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '${product.stock} exemplaire${product.stock > 1 ? 's' : ''} disponible${product.stock > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Sélecteur de quantité
          Row(
            children: [
              Text(
                'Quantité :',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              
              // Stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.grey300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _quantity.toString(),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _quantity < product.stock // Max = stock
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Sélecteur de variantes (couleur, stockage)
  Widget _buildVariantsSection(BuildContext context) {
    final product = _product!;
    
    // Si pas de variantes, ne rien afficher
    if (product.variants.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductVariantsSelector(
            variants: product.variants,
            onSelectionChanged: (selected) {
              setState(() {
                _selectedVariants = selected;
              });
            },
            onPriceAdjustmentChanged: (adjustment) {
              setState(() {
                _priceAdjustment = adjustment;
              });
            },
          ),
          
          // Afficher l'ajustement de prix si applicable
          if (_priceAdjustment != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _priceAdjustment > 0 
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _priceAdjustment > 0 
                        ? Icons.arrow_upward 
                        : Icons.arrow_downward,
                    size: 16,
                    color: _priceAdjustment > 0 
                        ? Colors.orange.shade700 
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _priceAdjustment > 0 
                        ? '+${_formatPriceInt(_priceAdjustment)}' 
                        : _formatPriceInt(_priceAdjustment),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _priceAdjustment > 0 
                          ? Colors.orange.shade700 
                          : Colors.green.shade700,
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
  
  /// Formater un prix entier
  String _formatPriceInt(int price) {
    return '${price.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} FCFA';
  }
  
  /// Description du produit
  Widget _buildDescription(BuildContext context) {
    final product = _product!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            product.description.isNotEmpty 
                ? product.description 
                : 'Aucune description disponible.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
  
  /// Caractéristiques techniques
  Widget _buildSpecifications(BuildContext context) {
    final product = _product!;
    final specs = product.specifications;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caractéristiques',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          
          if (specs.isEmpty)
            Text(
              'Aucune caractéristique disponible.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )
          else
            ...specs.entries.map((spec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      spec.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      spec.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  /// Section Social Proof (avis + vendus)
  Widget _buildSocialProofSection(BuildContext context) {
    final product = _product!;
    final hasRating = product.rating != null && product.rating!.count > 0;
    final hasSoldCount = product.soldCount > 0;
    
    if (!hasRating && !hasSoldCount) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating avec étoiles
          if (hasRating) ...[
            Row(
              children: [
                RatingStars(
                  rating: product.rating!.average,
                  count: product.rating!.count,
                  size: 20,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Naviguer vers la page des avis
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllReviewsScreen(
                          productId: product.id,
                          productName: product.name,
                          averageRating: product.rating?.average,
                          totalReviews: product.rating?.count,
                          distribution: product.rating?.distribution,
                        ),
                      ),
                    );
                  },
                  child: const Text('Voir tous'),
                ),
              ],
            ),
          ],
          
          // Social proof text
          if (hasSoldCount) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${product.soldCount} personnes ont acheté ce produit',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
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

  /// Section Signaux de Confiance
  Widget _buildTrustSignalsSection(BuildContext context) {
    final product = _product!;
    
    return TrustSignalsSection(
      freeShipping: product.shipping.isFree,
      shippingDelay: product.shipping.delayText,
      warrantyMonths: product.warranty.months,
      warrantyType: product.warranty.type,
      returnDays: product.returnPolicy.days,
      freeReturn: product.returnPolicy.freeReturn,
      isVerified: product.authenticity.verified,
      verifiedSource: product.authenticity.source.isNotEmpty 
          ? product.authenticity.source 
          : null,
    );
  }

  /// Section Points Forts
  Widget _buildHighlightsSection(BuildContext context) {
    final product = _product!;
    
    if (product.highlights.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Points forts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          ...product.highlights.map((highlight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    highlight,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 24),
        ],
      ),
    );
  }

  /// Section Avis Clients
  Widget _buildReviewsSection(BuildContext context) {
    final product = _product!;
    final hasRating = product.rating != null && product.rating!.count > 0;
    
    // Distribution des avis (données réelles)
    final distribution = hasRating 
        ? product.rating!.distribution 
        : <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    
    // Utiliser les vrais avis depuis Firestore
    final reviewCards = _reviews.map((review) => ReviewCard(
      userName: review.userName,
      rating: review.rating.toDouble(),
      comment: review.comment,
      timeAgo: review.timeAgo,
      isVerifiedPurchase: review.isVerifiedPurchase,
      helpfulCount: review.helpfulCount,
      userPhotoUrl: review.userPhotoUrl,
      onHelpful: () async {
        await ReviewService.markHelpful(review.id);
        CustomSnackBar.show(
          context,
          message: 'Merci pour votre retour !',
          type: SnackBarType.success,
        );
      },
    )).toList();
    
    // Afficher un loader si les avis sont en cours de chargement
    if (_isLoadingReviews && _reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avis clients',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    
    return ReviewsSection(
      averageRating: hasRating ? product.rating!.average : 0,
      totalReviews: hasRating ? product.rating!.count : 0,
      distribution: distribution,
      reviewCards: reviewCards,
      onSeeAll: (hasRating || _reviews.isNotEmpty) ? () {
        // Naviguer vers la page des avis
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllReviewsScreen(
              productId: product.id,
              productName: product.name,
              averageRating: product.rating?.average,
              totalReviews: product.rating?.count,
              distribution: product.rating?.distribution,
            ),
          ),
        );
      } : null,
      onAddReview: () {
        // Vérifier si l'utilisateur est connecté
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.isAnonymous) {
          _showLoginRequiredForReview();
          return;
        }
        // Ouvrir le formulaire d'ajout d'avis
        _openAddReviewDialog();
      },
    );
  }
  
  /// Ouvrir le dialogue d'ajout d'avis
  Future<void> _openAddReviewDialog() async {
    final result = await AddReviewDialog.show(
      context,
      productId: _product!.id,
      productName: _product!.name,
      onReviewAdded: (review) {
        // L'avis sera visible après modération
      },
    );
    
    if (result == true) {
      // Rafraîchir les avis
      _loadReviews();
    }
  }

  /// Dialogue pour demander la connexion avant de laisser un avis
  void _showLoginRequiredForReview() async {
    final shouldLogin = await StyledDialogs.showAuthRequiredDialog(
      context,
      customMessage: 'Connectez-vous pour laisser un avis sur ce produit.',
    );
    
    if (shouldLogin == true && mounted) {
      AppNavigator.push(context, AppNavigator.authRoute);
    }
  }
  
  /// Boutons d'action en bas
  Widget _buildBottomActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryVioletDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton WhatsApp avec style vert
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25D366).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openWhatsApp,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.chat_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Bouton Ajouter au panier
            Expanded(
              child: PrimaryButton(
                text: 'Ajouter au panier',
                icon: Icons.shopping_cart_outlined,
                height: 52,
                onPressed: _addToCart,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Ouvrir WhatsApp
  void _openWhatsApp() async {
    // Vérifier si l'utilisateur est connecté (et pas anonyme)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      // Montrer un dialogue stylé pour se connecter
      final shouldLogin = await StyledDialogs.showAuthRequiredDialog(
        context,
        customMessage: 'Pour commander via WhatsApp, connectez-vous ou créez un compte.\n\nCela nous permet de mieux vous servir !',
      );
      
      if (shouldLogin == true && mounted) {
        AppNavigator.push(context, AppNavigator.authRoute);
      }
      return;
    }
    
    final product = _product!;
    
    // Construire le message avec les infos client
    String message = '🛍️ *Nouvelle demande - Pharrell Phone*\n\n';
    
    // Ajouter les infos du client
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      message += '👤 *Client :* ${user.displayName}\n';
    }
    if (user.email != null && user.email!.isNotEmpty) {
      message += '📧 *Email :* ${user.email}\n';
    }
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      message += '📞 *Téléphone :* ${user.phoneNumber}\n';
    }
    
    message += '\n📱 *Produit :* ${product.name}\n';
    message += '💰 *Prix :* ${product.price.toStringAsFixed(0)} FCFA\n';
    message += '🔢 *Quantité :* $_quantity\n';
    message += '💵 *Total :* ${(product.price * _quantity).toStringAsFixed(0)} FCFA\n\n';
    message += 'Merci !';
    
    final url = Uri.parse('https://wa.me/2250788711896?text=${Uri.encodeComponent(message)}');
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Impossible d\'ouvrir WhatsApp');
      }
    }
  }
  
  /// Ajouter au panier
  void _addToCart() {
    final product = _product!;
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    // Ajouter la quantité au panier
    for (int i = 0; i < _quantity; i++) {
      cart.addItem(product);
    }
    
    CustomSnackBar.cartAdded(
      context,
      quantity: _quantity,
      productName: product.name,
      onViewCart: () => AppNavigator.push(context, AppNavigator.cartRoute),
    );
  }
}