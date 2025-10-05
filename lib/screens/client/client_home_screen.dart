import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0;
  AppUser? _currentUser;
  final AuthService _authService = AuthService();

  final List<Widget> _pages = [
    const ClientCatalogTab(),
    const ClientOrdersTab(),
    const ClientProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser != null
              ? 'Bonjour ${_currentUser!.firstName}'
              : 'Pharrell Phone',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  setState(() {
                    _selectedIndex = 2;
                  });
                  break;
                case 'logout':
                  await _authService.signOut();
                  if (mounted && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Se déconnecter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Mes commandes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class ClientCatalogTab extends StatefulWidget {
  const ClientCatalogTab({super.key});

  @override
  State<ClientCatalogTab> createState() => _ClientCatalogTabState();
}

class _ClientCatalogTabState extends State<ClientCatalogTab> {
  String _selectedCategory = 'Tous';
  String _searchQuery = '';

  final List<String> _categories = [
    'Tous',
    'Smartphones',
    'Accessoires',
    'Coques',
    'Écouteurs',
  ];

  // Données simulées des produits (en production, cela viendrait de Firestore)
  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': '1',
      'name': 'iPhone 15 Pro',
      'price': 1299,
      'oldPrice': 1399,
      'category': 'Smartphones',
      'description':
          'Le dernier iPhone avec processeur A17 Pro et appareil photo 48MP',
      'hasPromotion': true,
      'stock': 15,
      'brand': 'Apple',
    },
    {
      'id': '2',
      'name': 'Samsung Galaxy S24',
      'price': 899,
      'oldPrice': null,
      'category': 'Smartphones',
      'description': 'Smartphone Android haut de gamme avec IA intégrée',
      'hasPromotion': false,
      'stock': 23,
      'brand': 'Samsung',
    },
    {
      'id': '3',
      'name': 'Coque iPhone 15 Pro',
      'price': 49,
      'oldPrice': 59,
      'category': 'Coques',
      'description': 'Protection premium en silicone avec MagSafe',
      'hasPromotion': true,
      'stock': 45,
      'brand': 'Apple',
    },
    {
      'id': '4',
      'name': 'AirPods Pro 3',
      'price': 279,
      'oldPrice': null,
      'category': 'Écouteurs',
      'description': 'Écouteurs sans fil avec réduction de bruit active',
      'hasPromotion': false,
      'stock': 12,
      'brand': 'Apple',
    },
    {
      'id': '5',
      'name': 'Chargeur sans fil',
      'price': 89,
      'oldPrice': 99,
      'category': 'Accessoires',
      'description': 'Chargeur rapide 15W compatible MagSafe',
      'hasPromotion': true,
      'stock': 32,
      'brand': 'Belkin',
    },
    {
      'id': '6',
      'name': 'Xiaomi Redmi Note 13',
      'price': 299,
      'oldPrice': null,
      'category': 'Smartphones',
      'description': 'Smartphone Android avec excellent rapport qualité-prix',
      'hasPromotion': false,
      'stock': 18,
      'brand': 'Xiaomi',
    },
    {
      'id': '7',
      'name': 'Samsung Galaxy Buds',
      'price': 149,
      'oldPrice': 179,
      'category': 'Écouteurs',
      'description': 'Écouteurs Bluetooth avec son premium',
      'hasPromotion': true,
      'stock': 27,
      'brand': 'Samsung',
    },
    {
      'id': '8',
      'name': 'Support téléphone',
      'price': 25,
      'oldPrice': null,
      'category': 'Accessoires',
      'description': 'Support ajustable pour bureau et voiture',
      'hasPromotion': false,
      'stock': 56,
      'brand': 'Generic',
    },
  ];

  // Filtrer les produits selon la recherche et la catégorie
  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((product) {
      // Filtrage par catégorie
      bool matchesCategory =
          _selectedCategory == 'Tous' ||
          product['category'] == _selectedCategory;

      // Filtrage par recherche (nom, description, marque)
      bool matchesSearch =
          _searchQuery.isEmpty ||
          product['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          product['description'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          product['brand'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche et filtres
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Filtres par catégorie
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Liste des produits avec message si aucun résultat
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildEmptyState()
              : _buildProductGrid(),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(
          product['name'],
          '${product['price']}€',
          product['oldPrice'] != null ? '${product['oldPrice']}€' : null,
          product['description'],
          product['hasPromotion'] ?? false,
          product,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun produit trouvé'
                : 'Aucun produit dans cette catégorie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés'
                : 'Sélectionnez une autre catégorie',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Effacer la recherche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    String name,
    String price,
    String? oldPrice,
    String description,
    bool hasPromotion,
    Map<String, dynamic> product,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showProductDetails(product);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du produit avec badge promo et stock
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getProductIcon(product['category']),
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                    if (hasPromotion)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PROMO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Badge de stock faible
                    if (product['stock'] <= 5)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Stock: ${product['stock']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Nom du produit avec marque
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                product['brand'],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),

              // Prix
              Row(
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (oldPrice != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      oldPrice,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: product['stock'] > 0
                      ? () {
                          _addToCart(product);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: product['stock'] > 0
                        ? Colors.green
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    product['stock'] > 0 ? 'Ajouter' : 'Rupture',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Icône selon la catégorie
  IconData _getProductIcon(String category) {
    switch (category) {
      case 'Smartphones':
        return Icons.phone_android;
      case 'Écouteurs':
        return Icons.headphones;
      case 'Coques':
        return Icons.phone_iphone;
      case 'Accessoires':
        return Icons.cable;
      default:
        return Icons.shopping_bag;
    }
  }

  // Afficher les détails du produit
  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle de drag
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Image et info de base
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getProductIcon(product['category']),
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product['brand'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${product['price']}€',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (product['oldPrice'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${product['oldPrice']}€',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description complète
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              product['description'],
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Informations stock et catégorie
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Stock'),
                        Text(
                          '${product['stock']} unités',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Catégorie'),
                        Text(
                          product['category'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: product['stock'] > 0
                        ? () {
                            Navigator.pop(context);
                            _addToCart(product);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      product['stock'] > 0
                          ? 'Ajouter au panier'
                          : 'Rupture de stock',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Ajouter au panier
  void _addToCart(Map<String, dynamic> product) {
    // Simulation d'ajout au panier - en production, utiliser un service de panier
    // CartService().addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ajouté au panier'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Voir panier',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }
}

class ClientOrdersTab extends StatefulWidget {
  const ClientOrdersTab({super.key});

  @override
  State<ClientOrdersTab> createState() => _ClientOrdersTabState();
}

class _ClientOrdersTabState extends State<ClientOrdersTab> {
  String _selectedFilter = 'Toutes';

  @override
  Widget build(BuildContext context) {
    // Données simulées des commandes avec filtrage
    final List<Map<String, dynamic>> allOrders = [
      {
        'id': 'CMD-2024001',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'product': 'iPhone 15 Pro',
        'total': 1299.0,
        'status': 'En transit'
      },
      {
        'id': 'CMD-2024002',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'product': 'AirPods Pro 3',
        'total': 279.0,
        'status': 'Livrée'
      },
      {
        'id': 'CMD-2024003',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'product': 'Coque iPhone 15',
        'total': 49.0,
        'status': 'Livrée'
      },
      {
        'id': 'CMD-2024004',
        'date': DateTime.now().subtract(const Duration(days: 10)),
        'product': 'Chargeur sans fil',
        'total': 89.0,
        'status': 'Préparée'
      },
      {
        'id': 'CMD-2024005',
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'product': 'Samsung Galaxy S24',
        'total': 899.0,
        'status': 'Livrée'
      },
    ];

    final filteredOrders = _selectedFilter == 'Toutes'
        ? allOrders
        : allOrders.where((order) {
            switch (_selectedFilter) {
              case 'En cours':
                return order['status'] == 'En transit' || order['status'] == 'Préparée';
              case 'Livrées':
                return order['status'] == 'Livrée';
              default:
                return true;
            }
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes commandes',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Filtres rapides
          Row(
            children: [
              _buildOrderFilterChip('Toutes', _selectedFilter == 'Toutes'),
              const SizedBox(width: 8),
              _buildOrderFilterChip('En cours', _selectedFilter == 'En cours'),
              const SizedBox(width: 8),
              _buildOrderFilterChip('Livrées', _selectedFilter == 'Livrées'),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des commandes
          filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune commande',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      Text(
                        _selectedFilter == 'Toutes' 
                            ? 'Vous n\'avez pas encore passé de commande'
                            : 'Aucune commande dans cette catégorie',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildOrderCard(
                      order['id'],
                      order['date'],
                      order['product'],
                      order['total'],
                      order['status'],
                      order,
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildOrderFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
    );
  }

  Widget _buildOrderCard(
    String orderNumber,
    DateTime date,
    String mainProduct,
    double total,
    String status,
    Map<String, dynamic> order,
  ) {
    Color statusColor;
    switch (status) {
      case 'Livrée':
        statusColor = Colors.green;
        break;
      case 'En transit':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Commandé le ${date.day}/${date.month}/${date.year}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(mainProduct, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${total.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showOrderDetails(order);
                  },
                  child: const Text('Voir détails'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de ${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produit: ${order['product']}'),
            const SizedBox(height: 8),
            Text('Date: ${order['date'].day}/${order['date'].month}/${order['date'].year}'),
            const SizedBox(height: 8),
            Text('Statut: ${order['status']}'),
            const SizedBox(height: 8),
            Text('Total: ${order['total'].toStringAsFixed(2)}€'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class ClientProfileTab extends StatefulWidget {
  const ClientProfileTab({super.key});

  @override
  State<ClientProfileTab> createState() => _ClientProfileTabState();
}

class _ClientProfileTabState extends State<ClientProfileTab> {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header profil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    _currentUser!.firstName.isNotEmpty
                        ? _currentUser!.firstName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentUser!.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _currentUser!.email,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Options du profil
          _buildProfileOption(
            Icons.edit,
            'Modifier le profil',
            'Mettre à jour vos informations personnelles',
            () {
              Navigator.pushNamed(context, '/profile/edit');
            },
          ),
          _buildProfileOption(
            Icons.location_on,
            'Adresses',
            'Gérer vos adresses de livraison',
            () {
              Navigator.pushNamed(context, '/profile/addresses');
            },
          ),
          _buildProfileOption(
            Icons.payment,
            'Moyens de paiement',
            'Cartes bancaires et méthodes de paiement',
            () {
              Navigator.pushNamed(context, '/profile/payments');
            },
          ),
          _buildProfileOption(
            Icons.notifications,
            'Notifications',
            'Préférences de notification',
            () {
              Navigator.pushNamed(context, '/profile/notifications');
            },
          ),
          _buildProfileOption(
            Icons.help,
            'Aide et support',
            'FAQ, contact et assistance',
            () {
              Navigator.pushNamed(context, '/help');
            },
          ),
          _buildProfileOption(
            Icons.privacy_tip,
            'Confidentialité',
            'Paramètres de confidentialité et données',
            () {
              Navigator.pushNamed(context, '/profile/privacy');
            },
          ),
          const SizedBox(height: 24),

          // Bouton de déconnexion
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _authService.signOut();
                if (mounted && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
