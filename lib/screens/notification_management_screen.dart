import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import 'package:intl/intl.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  NotificationType _selectedType = NotificationType.info;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des notifications'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulaire d'envoi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Envoyer une notification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<NotificationType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: NotificationType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _canSendNotification()
                            ? _sendNotification
                            : null,
                        icon: const Icon(Icons.send),
                        label: const Text('Envoyer à tous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notifications rapides
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications rapides',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    _buildQuickNotificationTile(
                      '🎉 Nouvelle promotion !',
                      'Découvrez nos offres exceptionnelles',
                      NotificationType.promotion,
                      Colors.orange,
                      Icons.local_offer,
                    ),

                    _buildQuickNotificationTile(
                      '📦 Nouveaux produits',
                      'De nouveaux produits sont disponibles',
                      NotificationType.stock,
                      Colors.blue,
                      Icons.inventory,
                    ),

                    _buildQuickNotificationTile(
                      '🔧 Maintenance programmée',
                      'L\'application sera en maintenance',
                      NotificationType.system,
                      Colors.red,
                      Icons.build,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Historique des notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications récentes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('notifications')
                          .orderBy('createdAt', descending: true)
                          .limit(10)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Erreur: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final notifications = snapshot.data!.docs;

                        if (notifications.isEmpty) {
                          return const Text('Aucune notification envoyée');
                        }

                        return Column(
                          children: notifications.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final notification = AppNotification.fromMap(data);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTypeColor(
                                  notification.type,
                                ),
                                child: Icon(
                                  _getTypeIcon(notification.type),
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              title: Text(notification.title),
                              subtitle: Text(
                                notification.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                DateFormat(
                                  'dd/MM HH:mm',
                                ).format(notification.createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNotificationTile(
    String title,
    String message,
    NotificationType type,
    Color color,
    IconData icon,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title),
      subtitle: Text(message),
      trailing: const Icon(Icons.send),
      onTap: () => _sendQuickNotification(title, message, type),
    );
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return 'Commande';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.stock:
        return 'Stock';
      case NotificationType.info:
        return 'Général';
      case NotificationType.system:
        return 'Système';
      case NotificationType.review:
        return 'Avis';
      case NotificationType.user:
        return 'Utilisateur';
      case NotificationType.warning:
        return 'Alerte';
      case NotificationType.error:
        return 'Erreur';
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Colors.blue;
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.stock:
        return Colors.green;
      case NotificationType.info:
        return Colors.purple;
      case NotificationType.system:
        return Colors.red;
      case NotificationType.review:
        return Colors.teal;
      case NotificationType.user:
        return Colors.indigo;
      case NotificationType.warning:
        return Colors.amber;
      case NotificationType.error:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_cart;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.stock:
        return Icons.inventory;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.user:
        return Icons.person;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
    }
  }

  bool _canSendNotification() {
    return _titleController.text.isNotEmpty && _bodyController.text.isNotEmpty;
  }

  void _sendNotification() async {
    if (!_canSendNotification()) return;

    try {
      final notification = AppNotification(
        id: '',
        userId: 'all',
        title: _titleController.text,
        message: _bodyController.text,
        type: _selectedType,
        data: {},
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toMap());

      _titleController.clear();
      _bodyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendQuickNotification(
    String title,
    String message,
    NotificationType type,
  ) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: 'all',
        title: title,
        message: message,
        type: type,
        data: {},
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification envoyée !'),
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
}
