import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/product_service.dart';

/// Provider optimisé pour la gestion des produits
class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  StreamSubscription<List<Product>>? _productsSub;
  final bool _realtimeEnabled = true; // enable real-time updates from Firestore

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  static const int _pageSize = 20;

  // Getters
  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  ProductProvider() {
    if (_realtimeEnabled) {
      _subscribeRealtime();
    }
  }

  /// Notifie les listeners en dehors de la phase de build pour éviter
  /// l'exception "setState() called during build".
  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  /// Charger les produits initiaux
  Future<void> loadProducts({bool refresh = false}) async {
    // If realtime listener is enabled, skip manual loading to avoid duplication
    if (_productsSub != null) return;
    if (_isLoading) return;

    if (refresh) {
      _products.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newProducts = snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        _products.addAll(newProducts);
        _hasMore = snapshot.docs.length == _pageSize;
        _applyFilters();
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = 'Erreur lors du chargement: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  /// Démarrer l'écoute temps réel des produits (Firestore snapshots)
  void _subscribeRealtime() {
    // Déjà abonné ? annuler
    _productsSub?.cancel();
    _productsSub = _productService.getAll().listen((list) {
      _products = list;
      // When using realtime stream we don't use pagination
      _lastDocument = null;
      _hasMore = false;
      _applyFilters();
    }, onError: (err) {
      debugPrint('Erreur realtime produits: $err');
    });
  }

  /// Charger plus de produits (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;
    await loadProducts();
  }

  /// Rechercher des produits
  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  /// Filtrer par catégorie
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// Appliquer les filtres de recherche et catégorie
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Filtre catégorie
      final matchesCategory =
          _selectedCategory == 'all' || product.category == _selectedCategory;

      // Filtre recherche
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery) ||
          product.brand.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();

    _notifySafely();
  }

  /// Ajouter un produit
  Future<void> addProduct(Product product) async {
    try {
      await _productService.add(product);
      _products.insert(0, product);
      _applyFilters();
    } catch (e) {
      _error = 'Erreur ajout produit: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  /// Mettre à jour un produit
  Future<void> updateProduct(Product product) async {
    try {
      await _productService.update(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        _applyFilters();
      }
    } catch (e) {
      _error = 'Erreur mise à jour produit: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  /// Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      await _productService.delete(productId);
      _products.removeWhere((p) => p.id == productId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Erreur suppression produit: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  /// Mettre à jour le stock
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _productService.updateStock(productId, newStock);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updatedProduct = _products[index].copyWith(
          stock: newStock,
          isInStock: newStock > 0,
        );
        _products[index] = updatedProduct;
        _applyFilters();
      }
    } catch (e) {
      _error = 'Erreur mise à jour stock: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  /// Réinitialiser les filtres
  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'all';
    _applyFilters();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    super.dispose();
  }

  /// Effacer l'erreur
  void clearError() {
    _error = null;
    _notifySafely();
  }
}

/// Provider pour le panier
class CartProvider extends ChangeNotifier {
  final Map<String, int> _items = {}; // productId -> quantity
  final Map<String, Product> _products = {}; // productId -> Product

  Map<String, int> get items => Map.unmodifiable(_items);
  Map<String, Product> get products => Map.unmodifiable(_products);
  int get itemCount => _items.values.fold(0, (sum, qty) => sum + qty);
  bool get isEmpty => _items.isEmpty;

  double get totalAmount {
    return _items.entries.fold(0.0, (sum, entry) {
      final product = _products[entry.key];
      if (product != null) {
        return sum + (product.price * entry.value);
      }
      return sum;
    });
  }

  /// Ajouter au panier
  void addItem(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id] = _items[product.id]! + quantity;
    } else {
      _items[product.id] = quantity;
      _products[product.id] = product;
    }
    notifyListeners();
    debugPrint('✅ Ajouté au panier: ${product.name} x$quantity');
  }

  /// Retirer du panier
  void removeItem(String productId) {
    _items.remove(productId);
    _products.remove(productId);
    notifyListeners();
  }

  /// Modifier la quantité
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
    } else {
      _items[productId] = quantity;
      notifyListeners();
    }
  }

  /// Incrémenter la quantité
  void incrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId] = _items[productId]! + 1;
      notifyListeners();
    }
  }

  /// Décrémenter la quantité
  void decrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]! > 1) {
        _items[productId] = _items[productId]! - 1;
      } else {
        removeItem(productId);
      }
      notifyListeners();
    }
  }

  /// Vider le panier
  void clear() {
    _items.clear();
    _products.clear();
    notifyListeners();
    debugPrint('🗑️ Panier vidé');
  }

  /// Alias pour clear (utilisé dans certains écrans)
  void clearCart() => clear();

  /// Obtenir un produit du panier
  Product? getProduct(String productId) => _products[productId];

  /// Obtenir la quantité d'un produit
  int getQuantity(String productId) => _items[productId] ?? 0;
}

enum ComparisonAddResult { added, alreadyFull, categoryMismatch }

/// Provider pour la comparaison de produits. En mémoire uniquement (comme
/// CartProvider) : se vide à la fermeture de l'app, pas de persistance.
class ComparisonProvider extends ChangeNotifier {
  static const int maxProducts = 3;

  final List<String> _productIds = [];
  String? _category;

  List<String> get productIds => List.unmodifiable(_productIds);
  String? get category => _category;
  bool get isFull => _productIds.length >= maxProducts;
  bool get isEmpty => _productIds.isEmpty;

  bool contains(String productId) => _productIds.contains(productId);

  /// Ajoute un produit à la comparaison. Refuse si la liste est pleine, ou
  /// si la catégorie ne correspond pas à celle déjà en cours (sauf si la
  /// liste est vide, auquel cas la catégorie est fixée par ce premier ajout).
  ComparisonAddResult add(String productId, String category) {
    if (_productIds.contains(productId)) {
      return ComparisonAddResult.added; // déjà présent, no-op
    }
    if (isFull) {
      return ComparisonAddResult.alreadyFull;
    }
    if (_category != null && _category != category) {
      return ComparisonAddResult.categoryMismatch;
    }

    _productIds.add(productId);
    _category = category;
    notifyListeners();
    return ComparisonAddResult.added;
  }

  void remove(String productId) {
    _productIds.remove(productId);
    if (_productIds.isEmpty) {
      _category = null;
    }
    notifyListeners();
  }

  void clear() {
    _productIds.clear();
    _category = null;
    notifyListeners();
  }
}