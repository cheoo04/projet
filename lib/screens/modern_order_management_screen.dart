import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/ui_components.dart';

/// Écran moderne de gestion des commandes
/// Affiche les commandes WhatsApp et statistiques
class ModernOrderManagementScreen extends StatefulWidget {
  const ModernOrderManagementScreen({Key? key}) : super(key: key);

  @override
  State<ModernOrderManagementScreen> createState() =>
      _ModernOrderManagementScreenState();
}

class _ModernOrderManagementScreenState
    extends State<ModernOrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TabBar seulement (le titre est dans l'AppBar de la navigation)
        Container(
          color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.pending), text: 'En attente'),
              Tab(icon: Icon(Icons.check_circle), text: 'Complétées'),
              Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
            ],
          ),
        ),
        // Contenu
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingOrders(),
              _buildCompletedOrders(),
              _buildStatistics(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingOrders() {
    return _buildOrdersPlaceholder(
      icon: Icons.shopping_bag_outlined,
      title: 'Commandes en attente',
      message:
          'Les commandes passées via WhatsApp apparaîtront ici.\n\n'
          'Actuellement, les commandes sont gérées directement sur WhatsApp.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openWhatsAppApp(context),
          icon: const Icon(Icons.chat),
          label: const Text('Ouvrir WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedOrders() {
    return _buildOrdersPlaceholder(
      icon: Icons.check_circle_outline,
      title: 'Commandes complétées',
      message:
          'L\'historique des commandes apparaîtra ici.\n\n'
          'Cette fonctionnalité sera disponible dans une prochaine version.',
      color: AppTheme.success,
    );
  }

  Widget _buildStatistics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Card(
            color: AppTheme.primaryViolet.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      size: 40,
                      color: AppTheme.primaryViolet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistiques des ventes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vue d\'ensemble de l\'activité',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Statistiques du jour
          Text(
            'Aujourd\'hui',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Commandes',
                '0',
                Icons.shopping_bag,
                AppTheme.primaryViolet,
              ),
              _buildStatCard(
                'Revenu',
                '0 FCFA',
                Icons.attach_money,
                AppTheme.success,
              ),
              _buildStatCard(
                'Clients',
                '0',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Panier moyen',
                '0 FCFA',
                Icons.shopping_cart,
                Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Statistiques du mois
          Text(
            'Ce mois',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow(
                    'Total des ventes',
                    '0 FCFA',
                    Icons.trending_up,
                    AppTheme.success,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    'Nombre de commandes',
                    '0',
                    Icons.receipt,
                    AppTheme.primaryViolet,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    'Nouveaux clients',
                    '0',
                    Icons.person_add,
                    Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    'Taux de conversion',
                    '0%',
                    Icons.percent,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Message informatif
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Les statistiques seront automatiquement calculées '
                      'lorsque le système de commandes sera activé.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersPlaceholder({
    required IconData icon,
    required String title,
    required String message,
    Color? color,
    List<Widget>? actions,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: color ?? AppTheme.grey400,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }

  /// Ouvrir l'application WhatsApp
  void _openWhatsAppApp(BuildContext context) async {
    try {
      // Ouvrir WhatsApp avec un numéro par défaut
      const String phoneNumber = '2250788711896'; // Remplacez par votre numéro
      final uri = Uri.parse('https://wa.me/$phoneNumber');
      
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
