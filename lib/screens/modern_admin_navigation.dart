import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import '../services/notification_service.dart';
import '../web_config/responsive_config.dart';
import 'modern_admin_products_screen.dart';
import 'modern_stock_management_screen.dart';
import 'modern_notification_management_screen.dart';
import 'modern_category_management_screen.dart';
import 'modern_order_management_screen.dart';
import 'promotion_management_screen.dart';
import 'supplier_management_screen.dart';
import 'user_management_screen.dart';
import 'image_management_screen.dart';
import 'review_management_screen.dart';
import 'advanced_analytics_screen.dart';

/// Navigation principale pour l'administration avec design moderne
/// Bottom navigation + Drawer pour accès rapide à toutes les fonctionnalités
class ModernAdminNavigation extends StatefulWidget {
  const ModernAdminNavigation({Key? key}) : super(key: key);

  @override
  State<ModernAdminNavigation> createState() => _ModernAdminNavigationState();
}

class _ModernAdminNavigationState extends State<ModernAdminNavigation> {
  int _currentIndex = 0;
  int _totalProducts = 0;
  int _outOfStock = 0;
  int _notifications = 0;
  bool _isLoadingStats = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Différer le chargement pour éviter d'appeler notifyListeners pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats(forceRefresh: true);
    });
  }

  /// Charger les statistiques pour le dashboard
  Future<void> _loadStats({bool forceRefresh = false}) async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Toujours recharger si forceRefresh ou si liste vide
      if (forceRefresh || productProvider.products.isEmpty) {
        await productProvider.loadProducts(refresh: true);
      }
      
      final products = productProvider.products;
      final outOfStock = products.where((p) => p.stock == 0).length;
      
      final notificationService = NotificationService();
      final notifications = await notificationService.getNotifications();
      
      if (mounted) {
        setState(() {
          _totalProducts = products.length;
          _outOfStock = outOfStock;
          _notifications = notifications.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  /// Appelé quand on change d'onglet
  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    // Rafraîchir les stats quand on revient au tableau de bord
    if (index == 0) {
      _loadStats(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Sur desktop, utiliser une NavigationRail permanente
    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar permanente sur desktop
            _buildDesktopSidebar(isDark),
            
            // Contenu principal
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(_getTitle()),
                  automaticallyImplyLeading: false,
                  actions: [
                    // Notifications
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_outlined),
                          if (_notifications > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _notifications > 9 ? '9+' : '$_notifications',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ModernNotificationManagementScreen(),
                          ),
                        );
                      },
                    ),
                    
                    // Déconnexion
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _confirmLogout,
                    ),
                  ],
                ),
                body: _buildBody(),
              ),
            ),
          ],
        ),
      );
    }

    // Layout mobile/tablette avec bottom navigation
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_notifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _notifications > 9 ? '9+' : '$_notifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernNotificationManagementScreen(),
                ),
              );
            },
          ),
          
          // Déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      
      drawer: _buildDrawer(context, isDark),
      
      body: _buildBody(),
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  /// Sidebar permanente pour desktop
  Widget _buildDesktopSidebar(bool isDark) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pharrell Phone',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Administration',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Navigation items
          _buildSidebarItem(0, Icons.dashboard, 'Tableau de bord'),
          _buildSidebarItem(1, Icons.inventory_2, 'Produits'),
          _buildSidebarItem(2, Icons.shopping_bag, 'Commandes'),
          _buildSidebarItem(3, Icons.analytics, 'Analytics'),
          
          const Divider(height: 32),
          
          // Extra items
          _buildSidebarExtraItem(Icons.category, 'Catégories', () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ModernCategoryManagementScreen(),
            ));
          }),
          _buildSidebarExtraItem(Icons.local_offer, 'Promotions', () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const PromotionManagementScreen(),
            ));
          }),
          _buildSidebarExtraItem(Icons.inventory, 'Stock', () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ModernStockManagementScreen(),
            ));
          }),
          _buildSidebarExtraItem(Icons.star, 'Avis', () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ReviewManagementScreen(),
            ));
          }),
          _buildSidebarExtraItem(Icons.people, 'Utilisateurs', () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const UserManagementScreen(),
            ));
          }),
          
          const Spacer(),
          
          // Retour boutique
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/');
              },
              icon: const Icon(Icons.store),
              label: const Text('Voir la boutique'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryViolet : (isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryViolet : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryViolet.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => _onTabChanged(index),
    );
  }

  Widget _buildSidebarExtraItem(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Gestion Produits';
      case 2:
        return 'Commandes';
      case 3:
        return 'Analytics';
      default:
        return 'Administration';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const ModernAdminProductsScreen();
      case 2:
        return const ModernOrderManagementScreen();
      case 3:
        return _buildAnalyticsPlaceholder();
      default:
        return _buildDashboard();
    }
  }

  /// Dashboard avec statistiques et actions rapides
  Widget _buildDashboard() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = ResponsiveBreakpoints.horizontalPadding(context);
    
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1400 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                _buildDashboardHeader(),
                
                const SizedBox(height: 24),
                
                // Grille de statistiques
                _buildStatsGrid(),
                
                const SizedBox(height: 24),
                
                // Actions rapides
                _buildQuickActions(),
                
                const SizedBox(height: 24),
                
                // Produits en rupture
                _buildLowStockSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenue Admin',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Gérez votre boutique Pharrell Phone',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final stats = [
      {
        'label': 'Produits',
        'value': '$_totalProducts',
        'icon': Icons.inventory,
        'color': AppTheme.primaryViolet,
        'onTap': () => setState(() => _currentIndex = 1),
      },
      {
        'label': 'Ruptures',
        'value': '$_outOfStock',
        'icon': Icons.warning,
        'color': AppTheme.error,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernStockManagementScreen(),
            ),
          );
        },
      },
      {
        'label': 'Notifications',
        'value': '$_notifications',
        'icon': Icons.notifications,
        'color': AppTheme.warning,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernNotificationManagementScreen(),
            ),
          );
        },
      },
      {
        'label': 'Commandes',
        'value': '0',
        'icon': Icons.shopping_bag,
        'color': AppTheme.success,
        'onTap': () => setState(() => _currentIndex = 2),
      },
    ];

    // Responsive grid
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 4 : 2);
    final childAspectRatio = isDesktop ? 1.8 : (isTablet ? 1.5 : 1.3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          stat['label'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
          stat['color'] as Color,
          stat['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickActionChip(
              'Ajouter produit',
              Icons.add_box,
              AppTheme.primaryViolet,
              () {
                // Naviguer vers l'onglet Produits
                setState(() => _currentIndex = 1);
              },
            ),
            _buildQuickActionChip(
              'Gérer stock',
              Icons.inventory_2,
              AppTheme.success,
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernStockManagementScreen(),
                  ),
                );
                _loadStats(forceRefresh: true);
              },
            ),
            _buildQuickActionChip(
              'Catégories',
              Icons.category,
              AppTheme.warning,
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernCategoryManagementScreen(),
                  ),
                );
                _loadStats(forceRefresh: true);
              },
            ),
            _buildQuickActionChip(
              'Promotions',
              Icons.local_offer,
              AppTheme.error,
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PromotionManagementScreen(),
                  ),
                );
                _loadStats(forceRefresh: true);
              },
            ),
            _buildQuickActionChip(
              'Données test',
              Icons.science,
              Colors.teal,
              () async {
                await Navigator.pushNamed(context, '/demo-data');
                // Rafraîchir les données après retour
                _loadStats(forceRefresh: true);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alertes stock',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernStockManagementScreen(),
                  ),
                );
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_outOfStock > 0)
          Card(
            color: AppTheme.error.withOpacity(0.1),
            child: ListTile(
              leading: const Icon(Icons.warning, color: AppTheme.error),
              title: Text(
                '$_outOfStock produit${_outOfStock > 1 ? 's' : ''} en rupture',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Action requise'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernStockManagementScreen(),
                  ),
                );
              },
            ),
          )
        else
          Card(
            color: AppTheme.success.withOpacity(0.1),
            child: const ListTile(
              leading: Icon(Icons.check_circle, color: AppTheme.success),
              title: Text(
                'Tous les produits sont en stock',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Situation normale'),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyticsPlaceholder() {
    // Naviguer vers l'écran d'analytics avancées
    if (!_isNavigating) {
      _isNavigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdvancedAnalyticsScreen(),
          ),
        );
        // Quand on revient, réinitialiser et aller au dashboard
        if (mounted) {
          setState(() {
            _isNavigating = false;
            _currentIndex = 0;
          });
        }
      });
    }
    
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Drawer avec menu complet
  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppTheme.accentVioletLight, AppTheme.primaryViolet]
                    : [AppTheme.primaryViolet, AppTheme.accentVioletLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppTheme.primaryViolet,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Administration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Pharrell Phone',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          _buildDrawerSection('Gestion des produits', [
            _DrawerItem(
              icon: Icons.inventory_2,
              title: 'Produits',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            _DrawerItem(
              icon: Icons.inventory,
              title: 'Stocks',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernStockManagementScreen(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.category,
              title: 'Catégories',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernCategoryManagementScreen(),
                  ),
                );
              },
            ),
          ]),
          
          const Divider(),
          
          _buildDrawerSection('Gestion commerciale', [
            _DrawerItem(
              icon: Icons.shopping_bag,
              title: 'Commandes',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
            _DrawerItem(
              icon: Icons.local_offer,
              title: 'Promotions',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PromotionManagementScreen(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.local_shipping,
              title: 'Fournisseurs',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupplierManagementScreen(),
                  ),
                );
              },
            ),
          ]),
          
          const Divider(),
          
          _buildDrawerSection('Administration', [
            _DrawerItem(
              icon: Icons.people,
              title: 'Utilisateurs',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernNotificationManagementScreen(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.analytics,
              title: 'Analytics',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),
            _DrawerItem(
              icon: Icons.image,
              title: 'Images',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImageManagementScreen(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.rate_review,
              title: 'Modération Avis',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReviewManagementScreen(),
                  ),
                );
              },
            ),
          ]),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Déconnexion'),
            onTap: () {
              Navigator.pop(context);
              _confirmLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<_DrawerItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        ...items.map((item) => ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              onTap: item.onTap,
            )),
      ],
    );
  }

  void _confirmLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Déconnexion',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Voulez-vous vraiment vous déconnecter de l\'espace administrateur ?',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Annuler', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/admin-login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Déconnecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
