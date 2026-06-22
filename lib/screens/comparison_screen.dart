import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../services/product_service.dart';
import '../widgets/responsive_scaffold.dart';

/// Écran de comparaison de produits côte à côte. Affiche jusqu'à 3 produits
/// de la même catégorie (sélectionnés via ComparisonProvider), avec prix,
/// marque, et l'union de leurs specs détaillées.
class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({Key? key}) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final ids = context.read<ComparisonProvider>().productIds;
    final products = await _productService.getByIds(ids);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  /// Union des labels de specs présents sur au moins un produit comparé,
  /// dans l'ordre de première apparition.
  List<String> get _allSpecLabels {
    final labels = <String>[];
    for (final product in _products) {
      for (final spec in product.detailedSpecs) {
        if (!labels.contains(spec.label)) labels.add(spec.label);
      }
    }
    return labels;
  }

  String? _specValueFor(Product product, String label) {
    for (final spec in product.detailedSpecs) {
      if (spec.label == label) return spec.value;
    }
    return null;
  }

  void _removeProduct(Product product) {
    context.read<ComparisonProvider>().remove(product.id);
    setState(() {
      _products.removeWhere((p) => p.id == product.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty) {
      return ResponsiveScaffold(
        appBar: AppBar(title: const Text('Comparer')),
        body: const Center(child: Text('Aucun produit à comparer')),
      );
    }

    final specLabels = _allSpecLabels;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Comparer'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ComparisonProvider>().clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Tout effacer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(160),
            border: TableBorder.symmetric(
              inside: BorderSide(color: Colors.grey.shade300),
            ),
            children: [
              // Ligne photo + nom + bouton retirer
              TableRow(
                children: _products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _removeProduct(product),
                        ),
                        if (product.imageUrls.isNotEmpty)
                          Image.network(
                            product.imageUrls.first,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        Text(
                          product.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              // Ligne prix
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: _products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${product.price.toStringAsFixed(0)} FCFA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primaryViolet,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Ligne marque
              TableRow(
                children: _products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(product.brand, textAlign: TextAlign.center),
                  );
                }).toList(),
              ),
              // Lignes specs détaillées (union des labels présents sur au
              // moins un produit ; "—" si absent sur un produit en particulier)
              for (final label in specLabels)
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: _products.map((product) {
                    final value = _specValueFor(product, label);
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            value ?? '—',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}