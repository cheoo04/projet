import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../widgets/ui_components.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../providers/app_providers.dart';
import '../services/category_service.dart';
import '../web_config/responsive_config.dart';
import 'product_enrichment_screen.dart';

/// Écran moderne de gestion des produits admin
/// Design cohérent avec le reste de l'application
class ModernAdminProductsScreen extends StatefulWidget {
  const ModernAdminProductsScreen({Key? key}) : super(key: key);

  @override
  State<ModernAdminProductsScreen> createState() => _ModernAdminProductsScreenState();
}

class _ModernAdminProductsScreenState extends State<ModernAdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  String _stockFilter = 'Tous';
  List<models.Category> _categories = [];
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService().getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (provider.products.isEmpty) {
      await provider.loadProducts();
    }
  }

  /// Vérifie si un produit a été enrichi avec des signaux de confiance
  bool _isProductEnriched(Product product) {
    // Un produit est considéré comme "enrichi" s'il a au moins un de ces champs configurés
    return product.originalPrice != null ||
        product.shortDescription != null ||
        product.highlights.isNotEmpty ||
        product.badges.isNotEmpty ||
        product.authenticity.verified ||
        product.isFeatured ||
        product.shipping.isFree;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(),
          
          // Liste des produits
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
      
      // Bouton flottant pour ajouter un produit
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewProduct,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: AppTheme.primaryViolet,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filtres
          Row(
            children: [
              // Filtre catégorie
              Expanded(
                child: _buildFilterDropdown(
                  value: _selectedCategory,
                  items: ['Tous', ..._categories.map((c) => c.name)],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value ?? 'Tous');
                  },
                  icon: Icons.category,
                ),
              ),
              const SizedBox(width: 8),
              
              // Filtre stock
              Expanded(
                child: _buildFilterDropdown(
                  value: _stockFilter,
                  items: ['Tous', 'En stock', 'Stock faible', 'Rupture'],
                  onChanged: (value) {
                    setState(() => _stockFilter = value ?? 'Tous');
                  },
                  icon: Icons.inventory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.grey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.products.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2,
            title: 'Aucun produit',
            message: 'Ajoutez votre premier produit',
            actionLabel: 'Ajouter un produit',
            onAction: _addNewProduct,
          );
        }

        // Filtrer les produits
        final filteredProducts = provider.products.where((product) {
          // Filtre recherche
          if (_searchQuery.isNotEmpty) {
            final matchName = product.name.toLowerCase().contains(_searchQuery);
            final matchBrand = product.brand.toLowerCase().contains(_searchQuery);
            if (!matchName && !matchBrand) return false;
          }

          // Filtre catégorie (comparer avec le nom de catégorie)
          if (_selectedCategory != 'Tous' && product.category != _selectedCategory) {
            return false;
          }

          // Filtre stock
          if (_stockFilter == 'En stock' && product.stock <= 0) return false;
          if (_stockFilter == 'Stock faible' && (product.stock <= 0 || product.stock > 10)) return false;
          if (_stockFilter == 'Rupture' && product.stock > 0) return false;

          return true;
        }).toList();

        if (filteredProducts.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: 'Aucun résultat',
            message: 'Aucun produit ne correspond à vos critères',
            actionLabel: 'Réinitialiser les filtres',
            onAction: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedCategory = 'Tous';
                _stockFilter = 'Tous';
              });
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadProducts(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = ResponsiveBreakpoints.isDesktop(context);
              final padding = ResponsiveBreakpoints.horizontalPadding(context);
              
              // Sur desktop, utiliser une grille
              if (isDesktop) {
                return GridView.builder(
                  padding: EdgeInsets.all(padding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(filteredProducts[index]);
                  },
                );
              }
              
              // Sur mobile/tablette, utiliser une liste
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(filteredProducts[index]);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image du produit
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrls.isNotEmpty
                      ? product.imageUrls.first
                      : 'https://via.placeholder.com/80',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.grey200,
                    child: const Icon(Icons.phone_android, color: AppTheme.grey400),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Informations produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et badge stock
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Badge enrichi
                        if (_isProductEnriched(product))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 12, color: Colors.teal),
                                SizedBox(width: 2),
                                Text(
                                  'Enrichi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 4),
                        StockBadge(
                          stock: product.stock,
                          isInStock: product.stock > 0,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Marque et catégorie
                    Text(
                      '${product.brand} • ${product.category}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Prix et actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${product.price.toStringAsFixed(0)} FCFA',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryViolet,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bouton voir sur la boutique
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(Icons.storefront, size: 16),
                                onPressed: () => _viewProductDetails(product),
                                tooltip: 'Voir sur la boutique',
                                color: Colors.blue,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            
                            // Bouton enrichir
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(Icons.auto_awesome, size: 16),
                                onPressed: () => _enrichProduct(product),
                                tooltip: 'Enrichir',
                                color: Colors.teal,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            
                            // Bouton modifier
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () => _editProduct(product),
                                tooltip: 'Modifier',
                                color: AppTheme.primaryViolet,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            
                            // Bouton supprimer
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(Icons.delete, size: 16),
                                onPressed: () => _deleteProduct(product),
                                tooltip: 'Supprimer',
                                color: AppTheme.error,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewProductDetails(Product product) {
    context.go('/product/${product.id}');
  }

  void _addNewProduct() {
    context.push('/product-form');
  }

  void _editProduct(Product product) {
    context.push('/product-form', extra: product);
  }

  void _enrichProduct(Product product) async {
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEnrichmentScreen(product: product),
      ),
    );
    
    // Si le produit a été modifié, recharger la liste
    if (result != null && mounted) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.loadProducts();
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${product.name}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Sauvegarder les références avant de fermer le dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final provider = Provider.of<ProductProvider>(context, listen: false);
              Navigator.pop(context);
              
              try {
                await provider.deleteProduct(product.id);
                
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${product.name} supprimé avec succès'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}