import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/order.dart' as order_model;
import '../services/order_service.dart' as order_service;
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['pending', 'confirmed', 'processing'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Aucune commande en attente',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final order = order_model.Order.fromMap(data, docs[i].id);
            return _OrderCard(order: order);
          },
        );
      },
    );
  }

  Widget _buildCompletedOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['delivered', 'cancelled'])
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Aucune commande complétée',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final order = order_model.Order.fromMap(data, docs[i].id);
            return _OrderCard(order: order, showActions: false);
          },
        );
      },
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

/// Card d'une commande dans la liste admin
class _OrderCard extends StatelessWidget {
  final order_model.Order order;
  final bool showActions;

  const _OrderCard({required this.order, this.showActions = true});

  Color get _statusColor {
    switch (order.status) {
      case order_model.order_model.OrderStatus.pending: return Colors.orange;
      case order_model.order_model.OrderStatus.confirmed: return Colors.blue;
      case order_model.order_model.OrderStatus.shipped: return Colors.purple;
      case order_model.order_model.OrderStatus.shipped: return Colors.teal;
      case order_model.order_model.OrderStatus.delivered: return Colors.green;
      case order_model.order_model.OrderStatus.cancelled: return Colors.red;
      default: return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case order_model.order_model.OrderStatus.pending: return 'En attente';
      case order_model.order_model.OrderStatus.confirmed: return 'Confirmée';
      case order_model.order_model.OrderStatus.shipped: return 'En traitement';
      case order_model.order_model.OrderStatus.shipped: return 'Expédiée';
      case order_model.order_model.OrderStatus.delivered: return 'Livrée';
      case order_model.order_model.OrderStatus.cancelled: return 'Annulée';
      default: return 'Inconnue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final date = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${fmt.format(order.totalAmount)} FCFA · $date',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // Infos client
                _infoRow(Icons.phone, order.customerPhone),
                if (order.deliveryAddress.isNotEmpty)
                  _infoRow(Icons.location_on, order.deliveryAddress),
                if (order.notes != null && order.notes!.isNotEmpty)
                  _infoRow(Icons.note, order.notes!),
                const SizedBox(height: 8),
                // Produits
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}× ${item.productName}',
                              style: const TextStyle(fontSize: 13)),
                          Text('${fmt.format(item.totalPrice)} FCFA',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${fmt.format(order.totalAmount)} FCFA',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryViolet)),
                  ],
                ),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(context, order_model.OrderStatus.cancelled),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Annuler'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(context, order_model.OrderStatus.confirmed),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirmer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
                child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  Future<void> _updateStatus(BuildContext context, OrderStatus status) async {
    try {
      await order_service.OrderService().updateStatus(order.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == order_model.OrderStatus.confirmed
                ? 'Commande confirmée ✅'
                : 'Commande annulée'),
            backgroundColor:
                status == order_model.OrderStatus.confirmed ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}