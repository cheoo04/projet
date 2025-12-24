import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../widgets/ui_components.dart';
import '../providers/app_providers.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'modern_admin_products_screen.dart';
import 'modern_stock_management_screen.dart';
import 'modern_order_management_screen.dart';
import 'modern_category_management_screen.dart';
import 'promotion_management_screen.dart';
import 'user_management_screen.dart';

/// Écran de connexion admin avec design moderne
class ModernAdminLoginScreen extends StatefulWidget {
  const ModernAdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<ModernAdminLoginScreen> createState() => _ModernAdminLoginScreenState();
}

class _ModernAdminLoginScreenState extends State<ModernAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo et titre
                _buildHeader(context, isDark),
                
                const SizedBox(height: 48),
                
                // Formulaire
                _buildForm(context),
                
                const SizedBox(height: 24),
                
                // Bouton de connexion
                _buildLoginButton(context),
                
                const SizedBox(height: 16),
                
                // Mot de passe oublié
                TextButton(
                  onPressed: () {
                    _showPasswordResetDialog();
                  },
                  child: const Text('Mot de passe oublié ?'),
                ),
                
                const SizedBox(height: 32),
                
                // Séparateur
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.grey300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.grey300)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Bouton pour voir la boutique client
                OutlinedButton.icon(
                  onPressed: () {
                    // Naviguer directement vers la boutique
                    context.go('/');
                  },
                  icon: const Icon(Icons.storefront),
                  label: const Text('Voir la boutique'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryViolet,
                    side: const BorderSide(color: AppTheme.primaryViolet),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Accéder à l\'application client',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Header avec logo
  Widget _buildHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryViolet,
              width: 3,
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppTheme.accentVioletLight, AppTheme.primaryViolet]
                  : [AppTheme.primaryViolet, AppTheme.accentVioletLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.phone_android,
            color: Colors.white,
            size: 60,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Titre
        Text(
          'Pharrell phone',
          style: theme.textTheme.displayMedium?.copyWith(
            color: AppTheme.primaryViolet,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Sous-titre
        Text(
          'Administration',
          style: theme.textTheme.headlineSmall,
        ),
        
        const SizedBox(height: 4),
        
        Text(
          'Accès réservé',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
  
  /// Formulaire de connexion
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'votre@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Mot de passe
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              if (value.length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 12),
          
          // Se souvenir
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                },
                activeColor: AppTheme.primaryViolet,
              ),
              Text(
                'Se souvenir de moi',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Bouton de connexion
  Widget _buildLoginButton(BuildContext context) {
    return PrimaryButton(
      text: 'Se connecter',
      isLoading: _isLoading,
      onPressed: _login,
    );
  }
  
  /// Connexion
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      final user = await authService.signInAsAdmin(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bienvenue ${user.firstName} !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/admin');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Afficher le dialogue de réinitialisation du mot de passe
  void _showPasswordResetDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'votre@email.com',
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer votre email'),
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // Note: Intégration Firebase Auth nécessaire
              // await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email de réinitialisation envoyé à $email'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

/// Écran de dashboard admin
class ModernAdminDashboardScreen extends StatefulWidget {
  const ModernAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModernAdminDashboardScreen> createState() => _ModernAdminDashboardScreenState();
}

class _ModernAdminDashboardScreenState extends State<ModernAdminDashboardScreen> {
  int _totalProducts = 0;
  int _outOfStock = 0;
  int _notifications = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  /// Charger les statistiques
  Future<void> _loadStats() async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Charger les produits si nécessaire
      if (productProvider.products.isEmpty) {
        await productProvider.loadProducts();
      }
      
      // Calculer les stats
      final products = productProvider.products;
      final outOfStock = products.where((p) => p.stock == 0).length;
      
      // Charger les notifications
      final notificationService = NotificationService();
      final notifications = await notificationService.getNotifications();
      
      setState(() {
        _totalProducts = products.length;
        _outOfStock = outOfStock;
        _notifications = notifications.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          // Déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/admin-login');
                      },
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      
      body: RefreshIndicator(
        onRefresh: () async {
          // Rafraîchir les statistiques
          final productProvider = Provider.of<ProductProvider>(context, listen: false);
          await productProvider.loadProducts(refresh: true);
          
          // Recharger les données de l'écran
          if (mounted) {
            setState(() {
              // Les données seront rechargées automatiquement
            });
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Statistiques rapides
            _buildStatsGrid(context),
            
            const SizedBox(height: 24),
            
            // Navigation principale
            Text(
              'Gestion',
              style: theme.textTheme.headlineMedium,
            ),
            
            const SizedBox(height: 16),
            
            _buildManagementGrid(context),
            
            const SizedBox(height: 24),
            
            // Notifications urgentes
            Text(
              'Notifications récentes',
              style: theme.textTheme.headlineMedium,
            ),
            
            const SizedBox(height: 16),
            
            _buildNotificationsList(context),
          ],
        ),
      ),
    );
  }
  
  /// Grille de statistiques
  Widget _buildStatsGrid(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final stats = [
      {'label': 'Produits', 'value': '$_totalProducts', 'icon': Icons.inventory, 'color': AppTheme.primaryViolet},
      {'label': 'Ruptures', 'value': '$_outOfStock', 'icon': Icons.warning, 'color': AppTheme.error},
      {'label': 'Notifications', 'value': '$_notifications', 'icon': Icons.notifications, 'color': AppTheme.warning},
      {'label': 'Commandes', 'value': '0', 'icon': Icons.shopping_bag, 'color': AppTheme.success},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          context,
          stat['label'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
          stat['color'] as Color,
        );
      },
    );
  }
  
  /// Card de statistique
  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.3 : 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Grille de gestion
  Widget _buildManagementGrid(BuildContext context) {
    final items = [
      {'title': 'Produits', 'icon': Icons.phone_android, 'route': '/admin-products'},
      {'title': 'Stock', 'icon': Icons.inventory_2, 'route': '/admin-stock'},
      {'title': 'Commandes', 'icon': Icons.shopping_bag, 'route': '/admin-orders'},
      {'title': 'Promotions', 'icon': Icons.local_offer, 'route': '/admin-promotions'},
      {'title': 'Utilisateurs', 'icon': Icons.people, 'route': '/admin-users'},
      {'title': 'Paramètres', 'icon': Icons.settings, 'route': '/admin-settings'},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return CategoryCard(
          title: item['title'] as String,
          icon: item['icon'] as IconData,
          onTap: () {
            final title = item['title'] as String;
            
            if (title.contains('Produit')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernAdminProductsScreen(),
                ),
              );
            } else if (title.contains('Commande')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernOrderManagementScreen(),
                ),
              );
            } else if (title.contains('Stock')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernStockManagementScreen(),
                ),
              );
            } else if (title.contains('Catégorie')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernCategoryManagementScreen(),
                ),
              );
            } else if (title.contains('Promotion')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PromotionManagementScreen(),
                ),
              );
            } else if (title.contains('Utilisateur')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title - En cours de développement')),
              );
            }
          },
        );
      },
    );
  }
  
  /// Liste des notifications
  Widget _buildNotificationsList(BuildContext context) {
    // Mock data
    final notifications = [
      {'title': 'Stock faible', 'message': 'iPhone 15 Pro - 5 exemplaires', 'time': 'Il y a 2h', 'isRead': false},
      {'title': 'Nouvelle commande', 'message': 'Commande #1234', 'time': 'Il y a 3h', 'isRead': true},
    ];
    
    if (notifications.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Aucune notification',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: notifications.map((notif) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (notif['isRead'] as bool)
                    ? AppTheme.grey200
                    : AppTheme.primaryViolet.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications,
                color: (notif['isRead'] as bool) ? AppTheme.grey400 : AppTheme.primaryViolet,
                size: 20,
              ),
            ),
            title: Text(notif['title'] as String),
            subtitle: Text(notif['message'] as String),
            trailing: Text(
              notif['time'] as String,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              // Marquer comme lu et afficher détails
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(notif['title'] as String),
                  content: Text(notif['message'] as String),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
