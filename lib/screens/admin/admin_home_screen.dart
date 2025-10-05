import 'package:flutter/material.dart';
import '../admin_navigation_screen.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser != null
              ? 'Admin - ${_currentUser!.firstName}'
              : 'Administration',
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.admin_panel_settings),
            onSelected: (value) async {
              switch (value) {
                case 'admin_panel':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNavigationScreen(),
                    ),
                  );
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
                value: 'admin_panel',
                child: Row(
                  children: [
                    Icon(Icons.dashboard),
                    SizedBox(width: 8),
                    Text('Panneau complet'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentUser != null
                              ? 'Bienvenue ${_currentUser!.firstName}'
                              : 'Panneau d\'administration',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tableau de bord administrateur - ${_currentUser?.role.toString().split('.').last ?? 'admin'}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistiques rapides
            Text(
              'Aperçu rapide',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Commandes',
                    '142',
                    '+12%',
                    Icons.shopping_cart,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Produits',
                    '89',
                    '+5%',
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Clients',
                    '256',
                    '+18%',
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Revenus',
                    '12,5k€',
                    '+24%',
                    Icons.euro,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Actions rapides
            Text(
              'Actions rapides',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionCard(
                  'Gestion des produits',
                  Icons.inventory_2,
                  Colors.blue,
                  () => _navigateToAdminPanel(),
                ),
                _buildQuickActionCard(
                  'Commandes en cours',
                  Icons.pending_actions,
                  Colors.orange,
                  () => _navigateToAdminPanel(),
                ),
                _buildQuickActionCard(
                  'Nouveaux clients',
                  Icons.person_add,
                  Colors.green,
                  () => _navigateToAdminPanel(),
                ),
                _buildQuickActionCard(
                  'Rapports détaillés',
                  Icons.analytics,
                  Colors.purple,
                  () => _navigateToAdminPanel(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Activité récente
            Text(
              'Activité récente',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildActivityItem(
                  [
                    'Nouvelle commande #2024${index + 100}',
                    'Client ${['Marie', 'Pierre', 'Sophie', 'Jean', 'Lucas'][index]} inscrit',
                    'Produit iPhone ${15 + index} mis à jour',
                    'Promotion créée: -20% sur accessoires',
                    'Livraison confirmée #2024${index + 95}',
                  ][index],
                  [
                    'Il y a ${index + 1} min',
                    'Il y a ${(index + 1) * 5} min',
                    'Il y a ${(index + 1) * 10} min',
                    'Il y a ${(index + 1) * 15} min',
                    'Il y a ${(index + 1) * 20} min',
                  ][index],
                  [
                    Icons.shopping_cart,
                    Icons.person_add,
                    Icons.edit,
                    Icons.local_offer,
                    Icons.local_shipping,
                  ][index],
                  [
                    Colors.green,
                    Colors.blue,
                    Colors.orange,
                    Colors.red,
                    Colors.purple,
                  ][index],
                );
              },
            ),
            const SizedBox(height: 24),

            // Bouton panneau complet
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAdminPanel,
                icon: const Icon(Icons.dashboard),
                label: const Text('Accéder au panneau complet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                change,
                style: TextStyle(
                  color: change.startsWith('+') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminNavigationScreen()),
    );
  }
}
