import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/promotion_provider.dart';
import '../widgets/optimized_product_card.dart';
import '../widgets/ui_components.dart';
import '../widgets/desktop_header.dart';
import '../web_config/navigation_helper.dart';
import '../web_config/responsive_config.dart';

/// Écran d'accueil moderne de Pharrell Phone
/// Design inspiré de l'image fournie avec support thème clair/sombre
class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({Key? key}) : super(key: key);

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
  // Contrôleur pour le carrousel d'images
  late PageController _heroPageController;
  Timer? _heroTimer;
  int _currentHeroIndex = 0;
  
  // Liste des produits à afficher dans le carrousel
  final List<Map<String, dynamic>> _heroProducts = [
    {
      'image': 'assets/images/iphone_hero.webp',
      'icon': Icons.phone_iphone,
      'title': 'Nouveautés\nde la Saison.',
      'subtitle': 'Qualité garantie.',
    },
    {
      'image': 'assets/images/samsung_hero.webp',
      'icon': Icons.smartphone,
      'title': 'Samsung\nGalaxy Series',
      'subtitle': 'Performance maximale.',
    },
    {
      'image': 'assets/images/airpods_hero.webp',
      'icon': Icons.headphones,
      'title': 'Accessoires\nPremium',
      'subtitle': 'Complétez votre setup.',
    },
    {
      'image': 'assets/images/watch_hero.webp',
      'icon': Icons.watch,
      'title': 'Montres\nConnectées',
      'subtitle': 'Style et technologie.',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialiser au milieu pour permettre le défilement infini dans les deux sens
    _heroPageController = PageController(initialPage: 1000);
    _currentHeroIndex = 0;
    _startHeroAutoScroll();
    
    // Charger les produits et promotions si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (productProvider.products.isEmpty) {
        productProvider.loadProducts();
      }
      
      // Charger les promotions
      final promotionProvider = Provider.of<PromotionProvider>(context, listen: false);
      promotionProvider.loadPromotions();
    });
  }
  
  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }
  
  void _startHeroAutoScroll() {
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_heroPageController.hasClients) {
        // Aller simplement à la page suivante (défilement infini)
        _heroPageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final maxWidth = ResponsiveBreakpoints.maxContentWidth(context);
    
    // Sur desktop, utiliser une structure avec DesktopHeader
    if (isDesktop) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: Column(
          children: [
            // Header desktop fixe
            const DesktopHeader(),
            
            // Contenu scrollable
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Section
                        _buildHeroSection(context, isDark),
                        const SizedBox(height: 32),
                        
                        // Catégories
                        Text('Catégories', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 16),
                        _buildCategoriesGrid(context),
                        const SizedBox(height: 32),
                        
                        // Meilleures Ventes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Meilleures Ventes', style: theme.textTheme.headlineMedium),
                            TextButton(
                              onPressed: () => AppNavigator.push(context, AppNavigator.catalogRoute),
                              child: const Text('Voir tout'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFeaturedProducts(context),
                        const SizedBox(height: 32),
                        
                        // WhatsApp
                        _buildWhatsAppCard(context, isDark),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Sur mobile/tablette, garder le layout avec SliverAppBar et bottom nav
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: CustomScrollView(
              slivers: [
                // App Bar avec logo
                SliverAppBar(
                  floating: true,
                  backgroundColor: isDark ? AppTheme.secondaryVioletDark : Colors.white,
                  elevation: 0,
                  title: Row(
                    children: [
                      // Logo Pharrell Phone
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryViolet,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.phone_android,
                          color: AppTheme.primaryViolet,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pharrell phone',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryViolet,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Qualité supérieur',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Icône recherche
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        AppNavigator.toCatalog(context, focusSearch: true);
                      },
                    ),
                    
                    // Icône panier avec badge
                    Consumer<CartProvider>(
                      builder: (context, cart, child) => Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined),
                            onPressed: () {
                              AppNavigator.push(context, AppNavigator.cartRoute);
                            },
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CounterBadge(count: cart.itemCount),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Contenu
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Hero Section - Bannière promotionnelle
                      _buildHeroSection(context, isDark),
                      const SizedBox(height: 24),
                      
                      // Titre Catégories
                      Text(
                        'Catégories',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      // Grille de catégories
                      _buildCategoriesGrid(context),
                      const SizedBox(height: 32),
                      
                      // Titre Meilleures Ventes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Meilleures Ventes',
                            style: theme.textTheme.headlineMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              AppNavigator.push(context, AppNavigator.catalogRoute);
                            },
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Produits vedettes (horizontal scroll sur mobile)
                      _buildFeaturedProducts(context),
                      const SizedBox(height: 32),
                      
                      // Contact WhatsApp
                      _buildWhatsAppCard(context, isDark),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Bottom Navigation Bar (sur mobile/tablette uniquement)
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }
  
  /// Hero Section avec carrousel automatique d'images
  Widget _buildHeroSection(BuildContext context, bool isDark) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final heroHeight = isDesktop ? 300.0 : 220.0;
    
    return Container(
      height: heroHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1B4E), const Color(0xFF7C3BAE)]
              : [const Color(0xFF8B5FB8), const Color(0xFF6B4A98)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Carrousel de contenu (défilement infini)
            PageView.builder(
              controller: _heroPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentHeroIndex = index % _heroProducts.length;
                });
              },
              // itemCount null = défilement infini
              itemBuilder: (context, index) {
                final productIndex = index % _heroProducts.length;
                final product = _heroProducts[productIndex];
                return _buildHeroSlide(context, product, isDark);
              },
            ),
            
            // Indicateurs de page (dots)
            Positioned(
              bottom: 12,
              left: 24,
              child: Row(
                children: List.generate(
                  _heroProducts.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: _currentHeroIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentHeroIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
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
  
  /// Slide individuel du carrousel Hero
  Widget _buildHeroSlide(BuildContext context, Map<String, dynamic> product, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    // Tailles responsives
    final titleSize = isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0);
    final subtitleSize = isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0);
    final buttonFontSize = isDesktop ? 14.0 : 13.0;
    final textWidth = isDesktop ? 0.45 : (isTablet ? 0.50 : 0.55);
    final imageSize = isDesktop ? 220.0 : (isTablet ? 180.0 : 140.0);
    final leftPadding = isDesktop ? 40.0 : (isTablet ? 28.0 : 20.0);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: leftPadding, vertical: 20),
      child: Row(
        children: [
          // Contenu texte à gauche
          Expanded(
            flex: isDesktop ? 5 : 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product['title'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                    fontSize: titleSize,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  product['subtitle'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: subtitleSize,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    AppNavigator.push(context, AppNavigator.catalogRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryViolet,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 18, 
                      vertical: isDesktop ? 14 : 10,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Voir le catalogue',
                    style: TextStyle(
                      fontSize: buttonFontSize, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Image produit à droite
          Expanded(
            flex: isDesktop ? 5 : 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildProductImage(product, imageSize),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Widget image produit avec effet 3D - taille responsive
  Widget _buildProductImage(Map<String, dynamic> product, double size) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(-0.12)
        ..rotateZ(0.02),
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: size,
          maxHeight: size + 20,
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(8, 8),
            ),
          ],
        ),
        child: Image.asset(
          product['image'] as String,
          width: size,
          height: size + 20,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildProductPlaceholder(product['icon'] as IconData);
          },
        ),
      ),
    );
  }
  
  /// Placeholder pour les images non disponibles
  Widget _buildProductPlaceholder(IconData icon) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(-0.12),
      alignment: Alignment.center,
      child: Container(
        width: 90,
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(8, 8),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 50,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
  
  /// Grille de catégories - Style compact horizontal
  Widget _buildCategoriesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    final categories = [
      {'title': 'Smartphones', 'icon': Icons.smartphone, 'color': AppTheme.primaryViolet, 'filter': 'Smartphones'},
      {'title': 'Accessoires', 'icon': Icons.headset, 'color': AppTheme.info, 'filter': 'Accessoires'},
      {'title': 'Promos', 'icon': Icons.local_offer, 'color': AppTheme.warning, 'filter': 'Promotions'},
      {'title': 'Nouveaux', 'icon': Icons.fiber_new, 'color': AppTheme.success, 'filter': 'Nouveautés'},
    ];
    
    // Mode ultra-compact: liste horizontale scrollable
    if (screenWidth <= 380) {
      return SizedBox(
        height: 50,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final category = categories[index];
            final color = category['color'] as Color;
            
            return _buildCategoryChip(context, category, color, isDark);
          },
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: isDesktop ? 16 : 10,
        mainAxisSpacing: isDesktop ? 16 : 10,
        childAspectRatio: isDesktop ? 3.5 : 2.8, // Plus large sur desktop
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = category['color'] as Color;
        
        return Material(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: isDark ? 0 : 1,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: () {
              AppNavigator.toCatalog(context, category: category['filter'] as String?);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Icône compacte
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Texte compact
                  Expanded(
                    child: Text(
                      category['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Chip de catégorie pour le mode horizontal
  Widget _buildCategoryChip(BuildContext context, Map<String, dynamic> category, Color color, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () {
          AppNavigator.toCatalog(context, category: category['filter'] as String?);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                category['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Produits vedettes en scroll horizontal
  Widget _buildFeaturedProducts(BuildContext context) {
    return Consumer2<ProductProvider, CartProvider>(
      builder: (context, productProvider, cart, child) {
        // Afficher un loader pendant le chargement
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Afficher un message si aucun produit
        if (productProvider.products.isEmpty) {
          return const SizedBox(
            height: 280,
            child: Center(
              child: Text('Aucun produit disponible'),
            ),
          );
        }
        
        // Prendre les premiers produits (plus sur desktop)
        final isDesktop = ResponsiveBreakpoints.isDesktop(context);
        final isTablet = ResponsiveBreakpoints.isTablet(context);
        final featuredProducts = productProvider.products.take(isDesktop ? 8 : (isTablet ? 6 : 5)).toList();
        
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Mode ultra-compact (< 450px): toujours horizontal pour éviter overflow
        // Également utilisé sur mobile normal
        if (screenWidth <= 450 || (!isDesktop && !isTablet)) {
          return SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: featuredProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                return CompactProductCard(
                  product: product,
                  width: 165,
                  onTap: () {
                    AppNavigator.toProductDetail(context, product.id);
                  },
                );
              },
            ),
          );
        }
        
        // Sur desktop/tablet large: grille
        final padding = ResponsiveBreakpoints.horizontalPadding(context);
        final availableWidth = screenWidth - (padding * 2);
        
        // Calcul dynamique du nombre de colonnes
        final minCardWidth = isDesktop ? 220.0 : 180.0;
        int crossAxisCount = (availableWidth / minCardWidth).floor();
        crossAxisCount = crossAxisCount.clamp(2, 5);
        
        // Calcul du ratio adapté - hauteur augmentée pour laisser place au contenu
        final spacing = 16.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final cardWidth = (availableWidth - totalSpacing) / crossAxisCount;
        // Ratio 3:5 (largeur:hauteur) = carte plus haute pour le contenu
        final cardHeight = cardWidth * 1.6;
        final childAspectRatio = cardWidth / cardHeight;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: featuredProducts.length,
          itemBuilder: (context, index) {
            final product = featuredProducts[index];
            return CompactProductCard(
              product: product,
              onTap: () {
                AppNavigator.toProductDetail(context, product.id);
              },
            );
          },
        );
      },
    );
  }
  
  /// Card de contact WhatsApp
  Widget _buildWhatsAppCard(BuildContext context, bool isDark) {
    return Card(
      child: InkWell(
        onTap: () => _openWhatsAppContact(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.chat,
                  color: Color(0xFF25D366),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Besoin d\'aide ?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contactez-nous sur WhatsApp',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+225 07 88 71 18 96',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryViolet,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Bottom Navigation Bar
  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Recherche',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Panier',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Compte',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Déjà sur l'accueil
            break;
          case 1:
            AppNavigator.push(context, AppNavigator.catalogRoute);
            break;
          case 2:
            AppNavigator.push(context, AppNavigator.cartRoute);
            break;
          case 3:
            AppNavigator.push(context, AppNavigator.accountRoute);
            break;
        }
      },
    );
  }

  /// Ouvrir WhatsApp pour contacter le support
  void _openWhatsAppContact(BuildContext context) async {
    const String phoneNumber = '2250788711896';
    const String message = 'Bonjour, j\'ai besoin d\'aide concernant Pharrell Phone.';
    
    final String encodedMessage = Uri.encodeComponent(message);
    final String whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
    
    try {
      final Uri uri = Uri.parse(whatsappUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ouverture de WhatsApp...'),
            backgroundColor: Color(0xFF25D366),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur ouverture WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir WhatsApp'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
