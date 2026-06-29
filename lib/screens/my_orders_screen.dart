import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_theme.dart';
import '../models/order.dart';
import '../services/order_service.dart';

/// Étapes linéaires de progression d'une commande. "cancelled" est un état
/// à part, affiché différemment (pas dans la timeline linéaire).
const List<OrderStatus> _linearStages = [
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.shipped,
  OrderStatus.delivered,
];

/// Écran Mes Commandes
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: user == null
          ? _buildNotLoggedIn(context)
          : _buildOrdersList(context, user.uid),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Connectez-vous pour voir vos commandes'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/auth'),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, String userId) {
    return StreamBuilder<List<Order>>(
      stream: _orderService.streamOrdersForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Impossible de charger les commandes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _buildEmptyOrders(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) =>
              _buildOrderCard(context, orders[index]),
        );
      },
    );
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune commande',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos commandes apparaîtront ici',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/catalog'),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Parcourir le catalogue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Couleur + icône associées à un statut — seule source de vérité,
  /// utilisée à la fois pour le badge de la liste et pour la timeline.
  /// Le switch est exhaustif sur l'enum : si un statut est ajouté un jour,
  /// l'analyseur Dart signale immédiatement qu'il manque un cas ici.
  ({Color color, IconData icon}) _statusVisual(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (color: AppTheme.warning, icon: Icons.hourglass_empty);
      case OrderStatus.confirmed:
        return (color: AppTheme.info, icon: Icons.check_circle_outline);
      case OrderStatus.preparing:
        return (
          color: AppTheme.accentVioletLight,
          icon: Icons.inventory_2_outlined,
        );
      case OrderStatus.shipped:
        return (color: AppTheme.primaryViolet, icon: Icons.local_shipping);
      case OrderStatus.delivered:
        return (color: AppTheme.success, icon: Icons.done_all);
      case OrderStatus.cancelled:
        return (color: AppTheme.error, icon: Icons.cancel_outlined);
    }
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final visual = _statusVisual(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showOrderDetails(context, order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commande #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: visual.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(visual.icon, size: 16, color: visual.color),
                        const SizedBox(width: 4),
                        Text(
                          order.status.displayName,
                          style: TextStyle(
                            color: visual.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date
              Text(
                _formatDate(order.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 8),

              // Items count
              Text(
                '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const Divider(height: 24),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total'),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryViolet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }

  /// Timeline de progression — version simple : statut actuel mis en
  /// évidence, et une date par étape déjà franchie (lue depuis
  /// `statusHistory`). Les commandes annulées affichent un encart à part.
  Widget _buildStatusTimeline(Order order) {
    if (order.status == OrderStatus.cancelled) {
      final visual = _statusVisual(OrderStatus.cancelled);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: visual.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(visual.icon, color: visual.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cette commande a été annulée.',
                style: TextStyle(
                  color: visual.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _linearStages.indexOf(order.status);
    final safeIndex = currentIndex == -1 ? 0 : currentIndex;

    final historyDates = <OrderStatus, DateTime>{};
    for (final entry in order.statusHistory) {
      historyDates[entry.status] = entry.timestamp;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _linearStages.length; i++)
          _buildTimelineStep(
            stage: _linearStages[i],
            isReached: i <= safeIndex,
            isCurrent: i == safeIndex,
            lineColored: i < safeIndex,
            isLast: i == _linearStages.length - 1,
            date: historyDates[_linearStages[i]],
          ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required OrderStatus stage,
    required bool isReached,
    required bool isCurrent,
    required bool lineColored,
    required bool isLast,
    DateTime? date,
  }) {
    final visual = _statusVisual(stage);
    final borderColor = isReached ? visual.color : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isReached
                    ? visual.color.withOpacity(0.15)
                    : Colors.grey.shade100,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Icon(
                visual.icon,
                size: 16,
                color: isReached ? visual.color : Colors.grey.shade400,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: lineColored ? visual.color : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.displayName,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isReached ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  )
                else if (isCurrent)
                  Text(
                    'En cours',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: AppTheme.primaryViolet,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Commande #${order.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Timeline de progression
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildStatusTimeline(order),
              ),

              const Divider(),

              // Items
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: order.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == order.items.length) {
                      // Total row
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${order.totalAmount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryViolet,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final item = order.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.smartphone,
                            color: AppTheme.primaryViolet,
                          ),
                        ),
                        title: Text(item.productName),
                        subtitle: Text('Quantité: ${item.quantity}'),
                        trailing: Text(
                          '${item.totalPrice.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}