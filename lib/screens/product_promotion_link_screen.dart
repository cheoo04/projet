import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../models/promotion.dart';
import '../providers/app_providers.dart';
import '../providers/promotion_provider.dart';

/// Écran pour lier des produits à une promotion
class ProductPromotionLinkScreen extends StatefulWidget {
  final Promotion promotion;

  const ProductPromotionLinkScreen({
    super.key,
    required this.promotion,
  });

  @override
  State<ProductPromotionLinkScreen> createState() => _ProductPromotionLinkScreenState();
}

class _ProductPromotionLinkScreenState extends State<ProductPromotionLinkScreen> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedProductIds = {};
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les produits déjà liés
    _selectedProductIds = Set.from(widget.promotion.productIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final promotionProvider = Provider.of<PromotionProvider>(context, listen: false);
      
      // Mettre à jour la promotion avec les nouveaux produits
      widget.promotion.productIds.clear();
      widget.promotion.productIds.addAll(_selectedProductIds);
      
      await promotionProvider.updatePromotion(widget.promotion);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedProductIds.length} produits liés à la promotion'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lier des produits'),
            Text(
              widget.promotion.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryViolet,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              'Enregistrer (${_selectedProductIds.length})',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Résumé de la promotion
          _buildPromotionSummary(isDark),
          
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
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
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          
          // Actions rapides
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.select_all),
                  label: const Text('Tout sélectionner'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.deselect),
                  label: const Text('Tout désélectionner'),
                ),
              ],
            ),
          ),
          
          // Liste des produits
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                var products = productProvider.products;
                
                // Filtrer par recherche
                if (_searchQuery.isNotEmpty) {
                  products = products.where((p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    p.brand.toLowerCase().contains(_searchQuery) ||
                    p.category.toLowerCase().contains(_searchQuery)
                  ).toList();
                }
                
                if (products.isEmpty) {
                  return const Center(
                    child: Text('Aucun produit trouvé'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = _selectedProductIds.contains(product.id);
                    
                    return _buildProductTile(product, isSelected, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionSummary(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryViolet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.promotion.discountText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.promotion.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valide du ${_formatDate(widget.promotion.startDate)} au ${_formatDate(widget.promotion.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.promotion.isCurrentlyActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.promotion.isCurrentlyActive ? 'Active' : 'Inactive',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(Product product, bool isSelected, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: AppTheme.primaryViolet, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrls.isNotEmpty
              ? Image.network(
                  product.imageUrls.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${product.brand} • ${product.category}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatPrice(product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryViolet,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatPrice(widget.promotion.calculateDiscountedPrice(product.price)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedProductIds.add(product.id);
              } else {
                _selectedProductIds.remove(product.id);
              }
            });
          },
          activeColor: AppTheme.primaryViolet,
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedProductIds.remove(product.id);
            } else {
              _selectedProductIds.add(product.id);
            }
          });
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.phone_android, color: Colors.grey),
    );
  }

  void _selectAll() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      _selectedProductIds = Set.from(productProvider.products.map((p) => p.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
