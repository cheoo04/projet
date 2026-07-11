import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_theme.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../web_config/navigation_helper.dart';

/// Écran de liste des notifications reçues par l'utilisateur
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Connectez-vous pour voir vos notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            onPressed: () => NotificationService().markAllAsRead(user.uid),
            icon: const Icon(Icons.done_all, color: Colors.white),
            label: const Text('Tout lire', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            // 'broadcast' = notifications envoyées à tous/à un groupe depuis
            // le dashboard admin (voir NotificationService.sendPushNotification) ;
            // sans ça, seules les notifications individuelles (commande,
            // stock...) remonteraient dans cet historique.
            .where('userId', whereIn: [user.uid, 'broadcast'])
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
                  Icon(Icons.notifications_none,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Aucune notification',
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('Vos notifications apparaîtront ici',
                      style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final notif =
                  AppNotification.fromMap(docs[i].data() as Map<String, dynamic>);
              return _NotifCard(notif: notif, docId: docs[i].id);
            },
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final String docId;

  const _NotifCard({required this.notif, required this.docId});

  IconData get _icon {
    switch (notif.type) {
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.stock:
        return Icons.inventory;
      case NotificationType.review:
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotificationType.order:
        return Colors.green;
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.stock:
        return Colors.red;
      case NotificationType.review:
        return Colors.amber;
      default:
        return AppTheme.primaryViolet;
    }
  }

  void _onTap(BuildContext context) {
    // Marquer comme lu
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});

    // Naviguer selon le type
    if (notif.entityId != null && notif.type == NotificationType.order) {
      AppNavigator.go(context, '/my-orders');
    } else if (notif.entityId != null) {
      // Tenter d'aller vers le produit si un entityId est présent
      AppNavigator.toProductDetail(context, notif.entityId!);
    } else {
      // Afficher les détails dans un dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notif.title),
          content: Text(notif.message),
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

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTime(notif.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: notif.isRead
          ? null
          : AppTheme.primaryViolet.withOpacity(0.04),
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}