import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/audit_service.dart';
import '../services/invoice_service.dart';
import '../services/auth_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderService _orderService = OrderService();
  final AuditService _auditService = AuditService();
  final InvoiceService _invoiceService = InvoiceService();
  final AuthService _authService = AuthService();

  OrderStatus? _selectedStatusFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des commandes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres et recherche
          _buildFiltersSection(),

          // Liste des commandes
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: _orderService.getAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];
                final filteredOrders = _filterOrders(orders);

                if (filteredOrders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune commande trouvée',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(filteredOrders[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email ou ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: 12),

          // Filtre par statut
          Row(
            children: [
              const Text(
                'Statut: ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilter(null, 'Tous'),
                      ...OrderStatus.values.map(
                        (status) =>
                            _buildStatusFilter(status, status.displayName),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(OrderStatus? status, String label) {
    final isSelected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatusFilter = selected ? status : null;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    return orders.where((order) {
      // Filtre par statut
      if (_selectedStatusFilter != null &&
          order.status != _selectedStatusFilter) {
        return false;
      }

      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return order.customerName.toLowerCase().contains(query) ||
            order.customerEmail.toLowerCase().contains(query) ||
            order.id.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status),
          child: Text(order.status.emoji, style: const TextStyle(fontSize: 16)),
        ),
        title: Text(
          'Commande #${order.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.customerName),
            Text(
              '${order.totalAmount.toStringAsFixed(0)} FCFA • ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: _buildStatusChip(order.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations client
                _buildInfoSection('Informations client', [
                  'Nom: ${order.customerName}',
                  'Email: ${order.customerEmail}',
                  'Téléphone: ${order.customerPhone}',
                  'Adresse: ${order.deliveryAddress}',
                ]),

                const SizedBox(height: 16),

                // Articles commandés
                _buildInfoSection('Articles commandés', [
                  ...order.items.map(
                    (item) =>
                        '${item.quantity}x ${item.productName} - ${item.totalPrice.toStringAsFixed(0)} FCFA',
                  ),
                ]),

                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showStatusChangeDialog(order),
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier statut'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _generateInvoice(order),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Facture PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                if (order.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Notes', [order.notes!]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.shipped:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  void _showStatusChangeDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) {
            return ListTile(
              leading: Text(status.emoji),
              title: Text(status.displayName),
              selected: order.status == status,
              onTap: () {
                Navigator.pop(context);
                _updateOrderStatus(order, status);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      await _orderService.updateStatus(order.id, newStatus);

      // Audit log
      final currentUser = await _authService.getCurrentUserData();
      await _auditService.log(
        userId: currentUser?.id ?? 'unknown',
        userName: currentUser?.firstName ?? 'Admin',
        action: 'update_order_status',
        entityType: 'order',
        entityId: order.id,
        oldValues: {'status': order.status.displayName},
        newValues: {'status': newStatus.displayName},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour vers "${newStatus.displayName}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _generateInvoice(Order order) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Génération de la facture...'),
            ],
          ),
        ),
      );

      // Générer et afficher la facture
      await _invoiceService.showInvoicePreview(order);

      if (mounted) Navigator.pop(context); // Fermer le dialog de loading

      // Audit log
      final currentUser = await _authService.getCurrentUserData();
      await _auditService.log(
        userId: currentUser?.id ?? 'unknown',
        userName: currentUser?.firstName ?? 'Admin',
        action: 'generate_invoice',
        entityType: 'order',
        entityId: order.id,
        newValues: {'action': 'Facture générée'},
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
