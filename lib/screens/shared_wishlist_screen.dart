import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/wishlist_share_service.dart';
import '../web_config/navigation_helper.dart';
import '../widgets/responsive_scaffold.dart';

/// Écran public de consultation d'une liste de favoris partagée.
/// Accessible sans connexion via /wishlist/{shareId}. Consultation
/// uniquement : chaque produit renvoie vers sa fiche, pas d'achat direct
/// pour un tiers depuis cet écran.
class SharedWishlistScreen extends StatefulWidget {
  final String shareId;

  const SharedWishlistScreen({Key? key, required this.shareId})
      : super(key: key);

  @override
  State<SharedWishlistScreen> createState() => _SharedWishlistScreenState();
}

class _SharedWishlistScreenState extends State<SharedWishlistScreen> {
  final WishlistShareService _wishlistShareService = WishlistShareService();
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final productIds =
        await _wishlistShareService.getSharedWishlist(widget.shareId);

    if (productIds.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _notFound = true;
        });
      }
      return;
    }

    final products = await _productService.getByIds(productIds);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _products.isEmpty) {
      return ResponsiveScaffold(
        appBar: AppBar(title: const Text('Liste de favoris')),
        body: const Center(
          child: Text('Cette liste est introuvable ou a expiré.'),
        ),
      );
    }

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Liste de favoris partagée')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrls.isNotEmpty)
                    Expanded(
                      child: Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.contain,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${product.price.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      color: AppTheme.primaryViolet,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => AppNavigator.toProductDetail(
                        context,
                        product.id,
                      ),
                      child: const Text('Voir'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}