import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/ui_components.dart';
import '../models/notification.dart' as model;
import '../services/notification_service.dart';

/// Écran moderne de gestion des notifications
/// Permet d'envoyer des notifications et de voir l'historique
class ModernNotificationManagementScreen extends StatefulWidget {
  const ModernNotificationManagementScreen({Key? key}) : super(key: key);

  @override
  State<ModernNotificationManagementScreen> createState() =>
      _ModernNotificationManagementScreenState();
}

class _ModernNotificationManagementScreenState
    extends State<ModernNotificationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  model.NotificationType _selectedType = model.NotificationType.info;
  bool _isSending = false;
  
  List<model.AppNotification> _notifications = [];
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoadingNotifications = true);
    try {
      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() => _isLoadingNotifications = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Envoyer'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  /// Onglet d'envoi de notification
  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Card(
              color: AppTheme.primaryViolet.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign,
                        color: AppTheme.primaryViolet,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Envoyer une notification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Informez vos utilisateurs en temps réel',
                            style: TextStyle(
                              fontSize: 13,
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
            
            // Type de notification
            Text(
              'Type de notification',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: model.NotificationType.values.map((type) {
                final isSelected = _selectedType == type;
                final color = _getTypeColor(type);
                final icon = _getTypeIcon(type);
                final label = _getTypeLabel(type);
                
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: isSelected ? Colors.white : color),
                      const SizedBox(width: 6),
                      Text(label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                  selectedColor: color,
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color.withOpacity(0.3)),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Titre
            Text(
              'Titre',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Entrez le titre de la notification',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(_getTypeIcon(_selectedType)),
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le titre est requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Message
            Text(
              'Message',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _bodyController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Entrez le contenu de la notification',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le message est requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Aperçu
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Aperçu',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getTypeColor(_selectedType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getTypeColor(_selectedType).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getTypeIcon(_selectedType),
                            color: _getTypeColor(_selectedType),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleController.text.isEmpty
                                      ? 'Titre de la notification'
                                      : _titleController.text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _bodyController.text.isEmpty
                                      ? 'Message de la notification'
                                      : _bodyController.text,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
            
            // Bouton d'envoi
            PrimaryButton(
              text: 'Envoyer la notification',
              icon: Icons.send,
              isLoading: _isSending,
              onPressed: _sendNotification,
            ),
          ],
        ),
      ),
    );
  }

  /// Onglet de l'historique
  Widget _buildHistoryTab() {
    if (_isLoadingNotifications) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none,
        title: 'Aucune notification',
        message: 'Les notifications envoyées apparaîtront ici',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(model.AppNotification notification) {
    final theme = Theme.of(context);
    final color = _getTypeColor(notification.type);
    final icon = _getTypeIcon(notification.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et date
            Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeLabel(notification.type),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(notification.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Lu',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Non lu',
                      style: TextStyle(
                        color: AppTheme.primaryViolet,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Titre
            Text(
              notification.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Corps
            Text(
              notification.body,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.info:
        return AppTheme.primaryViolet;
      case model.NotificationType.success:
        return AppTheme.success;
      case model.NotificationType.warning:
        return AppTheme.warning;
      case model.NotificationType.error:
        return AppTheme.error;
      case model.NotificationType.promotion:
        return Colors.pink;
      case model.NotificationType.stock:
        return Colors.orange;
      case model.NotificationType.order:
        return Colors.blue;
      case model.NotificationType.review:
        return Colors.purple;
      case model.NotificationType.system:
        return Colors.grey;
      case model.NotificationType.user:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.info:
        return Icons.info;
      case model.NotificationType.success:
        return Icons.check_circle;
      case model.NotificationType.warning:
        return Icons.warning;
      case model.NotificationType.error:
        return Icons.error;
      case model.NotificationType.promotion:
        return Icons.local_offer;
      case model.NotificationType.stock:
        return Icons.inventory;
      case model.NotificationType.order:
        return Icons.shopping_cart;
      case model.NotificationType.review:
        return Icons.star;
      case model.NotificationType.system:
        return Icons.settings;
      case model.NotificationType.user:
        return Icons.person;
    }
  }

  String _getTypeLabel(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.info:
        return 'Information';
      case model.NotificationType.success:
        return 'Succès';
      case model.NotificationType.warning:
        return 'Attention';
      case model.NotificationType.error:
        return 'Erreur';
      case model.NotificationType.promotion:
        return 'Promotion';
      case model.NotificationType.stock:
        return 'Stock';
      case model.NotificationType.order:
        return 'Commande';
      case model.NotificationType.review:
        return 'Avis';
      case model.NotificationType.system:
        return 'Système';
      case model.NotificationType.user:
        return 'Utilisateur';
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSending = true);

    try {
      // Envoyer la notification
      // Note: Pour implémenter la sélection d'utilisateurs cibles,
      // ajouter un sélecteur d'utilisateurs dans le formulaire
      // et passer la liste des userId sélectionnés
      await _notificationService.sendNotification(
        title: _titleController.text,
        body: _bodyController.text,
        type: _selectedType,
        userId: 'admin', // TODO: Remplacer par la liste d'utilisateurs sélectionnés
      );

      if (mounted) {
        // Réinitialiser le formulaire
        _titleController.clear();
        _bodyController.clear();
        setState(() => _selectedType = model.NotificationType.info);

        // Recharger les notifications
        await _loadNotifications();

        // Basculer vers l'onglet historique
        _tabController.animateTo(1);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Notification envoyée avec succès'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}
