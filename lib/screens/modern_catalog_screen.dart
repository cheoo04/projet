import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../providers/promotion_provider.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/optimized_product_card.dart';
import '../widgets/desktop_product_card.dart';
import '../widgets/desktop_header.dart';
import '../widgets/ui_components.dart';
import '../widgets/comparison_banner.dart';
import '../web_config/responsive_config.dart';
import '../web_config/navigation_helper.dart';

/// Catalogue moderne inspiré de l'image fournie
/// Design sombre avec cards violettes et support thème clair
class ModernCatalogScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialSearchQuery;
  final bool initialFocusSearch;
  
  const ModernCatalogScreen({
    Key? key,
    this.initialCategory,
    this.initialSearchQuery,
    this.initialFocusSearch = false,
  }) : super(key: key);

  @override
  State<ModernCatalogScreen> createState() => _ModernCatalogScreenState();
}

class _ModernCatalogScreenState extends State<ModernCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Tous',
    'Smartphones',
    'Accessoires',
    'Promotions',
    'Nouveautés',
  ];
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Appliquer les paramètres initiaux du widget
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
      debugPrint('🔍 ModernCatalogScreen - initialCategory: ${widget.initialCategory} → _selectedCategory: $_selectedCategory');
    } else if (widget.initialCategory != null) {
      debugPrint('⚠️ ModernCatalogScreen - initialCategory "${widget.initialCategory}" non trouvée dans $_categories');
    }
    
    // Appliquer la recherche initiale si fournie
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = widget.initialSearchQuery!;
      debugPrint('🔍 ModernCatalogScreen - initialSearchQuery: ${widget.initialSearchQuery}');
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
      
      // Focus sur la recherche si demandé
      if (widget.initialFocusSearch) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _searchFocusNode.requestFocus();
          }
        });
      }
      
      // Fallback: Récupérer les arguments via ModalRoute (pour mobile)
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        final category = args['category'] as String?;
        if (category != null && _categories.contains(category) && _selectedCategory == 'Tous') {
          setState(() {
            _selectedCategory = category;
          });
        }
        final focusSearch = args['focusSearch'] as bool?;
        if (focusSearch == true) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _searchFocusNode.requestFocus();
            }
          });
        }
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }
  
  Future<void> _loadProducts() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadMoreProducts() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.loadMoreProducts();
    } catch (e) {
      // Silencieux pour pagination
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header : Desktop header ou header mobile
                if (isDesktop)
                  const DesktopHeader()
                else
                  _buildHeader(context, isDark),
                
                // Filtres catégories
                _buildCategoryFilters(context),
                
                // Liste des produits
                Expanded(
                  child: _buildProductGrid(context),
                ),
              ],
            ),
          ),
          const ComparisonBanner(),
        ],
      ),
      floatingActionButton: Consumer<ComparisonProvider>(
        builder: (context, comparison, _) {
          // Quand le bandeau de comparaison est visible (Positioned bottom: 16,
          // hauteur ~60px), on remonte le FAB pour éviter qu'ils se chevauchent.
          final bottomOffset = comparison.productIds.isEmpty ? 0.0 : 76.0;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomOffset),
            child: FloatingActionButton(
              onPressed: () => AppNavigator.push(context, '/chat'),
              backgroundColor: AppTheme.primaryViolet,
              tooltip: 'Besoin d\'aide ?',
              child: const Icon(Icons.support_agent, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
  
  /// Header avec recherche et panier
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryVioletDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et icônes
          Row(
            children: [
              // Bouton retour
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              
              // Titre
              Expanded(
                child: Text(
                  'Catalogue',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              
              // Icône panier avec badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => _navigateToCart(),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        return CounterBadge(count: cart.itemCount);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barre de recherche
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Filtres par catégorie (chips horizontaux)
  Widget _buildCategoryFilters(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: AppTheme.primaryViolet,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.grey800
                  : AppTheme.grey100,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Grille de produits
  Widget _buildProductGrid(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
      // Utiliser les produits depuis le provider
      var products = productProvider.products;
      
      // Récupérer le PromotionProvider de manière sécurisée
      PromotionProvider? promotionProvider;
      try {
        promotionProvider = context.read<PromotionProvider>();
      } catch (_) {
        // Provider non disponible
      }
      
      // Filtrer par catégorie
      if (_selectedCategory != 'Tous') {
        if (_selectedCategory == 'Promotions') {
          // Filtrer les produits en promotion:
          // 1. Promo manuelle (originalPrice > price)
          // 2. OU promo système via PromotionProvider
          products = products.where((p) {
            // Promo manuelle
            if (p.originalPrice != null && p.originalPrice! > p.price) {
              return true;
            }
            // Promo système
            if (promotionProvider != null) {
              return promotionProvider.hasActivePromotion(p);
            }
            return false;
          }).toList();
        } else if (_selectedCategory == 'Nouveautés') {
          // Produits créés dans les 30 derniers jours
          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          products = products.where((p) => p.createdAt.isAfter(thirtyDaysAgo)).toList();
        } else {
          // Filtrer par catégorie standard
          products = products.where((p) => p.category == _selectedCategory).toList();
        }
      }
      
      // Filtrer par recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        products = products.where((p) => 
          p.name.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query)
        ).toList();
      }
      
      // Afficher skeleton pendant le premier chargement
      if (_isLoading && products.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      // État vide
      if (products.isEmpty) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'Aucun produit trouvé',
          message: 'Essayez de modifier vos filtres ou votre recherche',
          buttonText: 'Réinitialiser',
          onButtonPressed: () {
            setState(() {
              _selectedCategory = 'Tous';
              _searchQuery = '';
              _searchController.clear();
            });
          },
        );
      }
    
      return RefreshIndicator(
        onRefresh: _loadProducts,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktop = ResponsiveBreakpoints.isDesktop(context);
            final isTablet = ResponsiveBreakpoints.isTablet(context);
            
            // Calcul dynamique basé sur la largeur disponible
            // Largeur maximale d'une carte selon le device
            double maxCardWidth;
            double minCardWidth;
            double cardHeight;
            
            if (isDesktop) {
              maxCardWidth = 280.0;
              minCardWidth = 220.0;
              cardHeight = 420.0;
            } else if (isTablet) {
              maxCardWidth = 240.0;
              minCardWidth = 180.0;
              cardHeight = 380.0;
            } else {
              // Mobile : 2 colonnes fixes
              maxCardWidth = 220.0;
              minCardWidth = 150.0;
              // Hauteur proportionnelle à la largeur disponible
              final approxCardWidth = (screenWidth - 16 * 2 - 10) / 2;
              cardHeight = approxCardWidth * 1.55; // ratio portrait naturel
            }

            final spacing = isDesktop ? 20.0 : 10.0;
            final padding = ResponsiveBreakpoints.horizontalPadding(context);

            // Calculer le nombre de colonnes
            final availableWidth = screenWidth - (padding * 2);
            int crossAxisCount = ResponsiveBreakpoints.isMobile(context)
                ? 2
                : (availableWidth / minCardWidth).floor();
            crossAxisCount = crossAxisCount.clamp(2, 6);

            // Largeur et ratio réels
            final totalSpacing = spacing * (crossAxisCount - 1);
            final cardWidth = (availableWidth - totalSpacing) / crossAxisCount;
            // Sur mobile on recalcule cardHeight avec la vraie cardWidth
            final effectiveCardHeight = ResponsiveBreakpoints.isMobile(context)
                ? cardWidth * 1.55
                : cardHeight;
            final childAspectRatio = cardWidth / effectiveCardHeight;
            
            // Mode ultra-compact: basculer en liste horizontale statique
            if (!isDesktop && screenWidth <= 380) {
              final cardWidth = 180.0;
              return SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  itemCount: products.length + (_isLoading ? 1 : 0),
                  separatorBuilder: (_, __) => SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    if (index >= products.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final product = products[index];
                    return CompactProductCard(
                      product: product,
                      width: cardWidth,
                      onTap: () => _navigateToProduct(product),
                    );
                  },
                ),
              );
            }

            return GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: products.length + (_isLoading ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= products.length) {
                  return const Card(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final product = products[index];
                
                // Utiliser DesktopProductCard sur desktop/tablet
                if (isDesktop || isTablet) {
                  return DesktopProductCard(
                    product: product,
                    onTap: () => _navigateToProduct(product),
                    onAddToCart: () => _addToCart(product),
                  );
                }
                
                // OptimizedProductCard sur mobile
                return OptimizedProductCard(
                  product: product,
                  onTap: () => _navigateToProduct(product),
                );
              },
            );
          },
        ),
      );
    });
  }
  
  /// Ajouter au panier
  void _addToCart(Product product) {
    if (!product.isInStock) {
      CustomSnackBar.warning(context, 'Produit en rupture de stock');
      return;
    }
    
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(product);
    
    CustomSnackBar.cartAdded(
      context,
      quantity: 1,
      productName: product.name,
      onViewCart: () => _navigateToCart(),
    );
  }
  
  /// Navigation vers produit (compatible web/mobile)
  void _navigateToProduct(Product product) {
    AppNavigator.toProductDetail(context, product.id);
  }
  
  /// Navigation vers panier
  void _navigateToCart() {
    AppNavigator.push(context, AppNavigator.cartRoute);
  }
}