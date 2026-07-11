import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String body; // Alias pour message
  final NotificationType type;
  final String? entityId;
  final String? entityType;
  final DateTime createdAt;
  final DateTime date; // Alias pour createdAt
  final bool isRead;
  final String userId;
  final Map<String, dynamic> data;
  final NotificationPriority priority;

  AppNotification({
    required this.id,
    required this.title,
    String? message,
    String? body,
    required this.type,
    this.entityId,
    this.entityType,
    DateTime? createdAt,
    DateTime? date,
    this.isRead = false,
    required this.userId,
    this.data = const {},
    this.priority = NotificationPriority.normal,
  }) : message = message ?? body ?? '',
       body = body ?? message ?? '',
       createdAt = createdAt ?? date ?? DateTime.now(),
       date = date ?? createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      // Requis par la Cloud Function `sendPushNotification` (interface
      // NotificationData côté functions/src/index.ts) : sans ce champ,
      // la notification push part avec un corps de message vide.
      'body': message,
      // 'order' et non 'NotificationType.order' — la Cloud Function
      // compare cette valeur à des chaînes comme "order"/"product" pour
      // construire le lien de redirection de la notification.
      'type': type.name,
      'entityId': entityId,
      'entityType': entityType,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'userId': userId,
      // Sans ces deux champs, la Cloud Function considère la notification
      // comme destinée à "all" (tous les utilisateurs) au lieu du seul
      // destinataire visé par `userId` — c'était la cause d'un envoi en
      // masse à tous les clients à chaque notification admin.
      'targetType': 'specific',
      'targetUserIds': [userId],
      'data': data,
      'priority': priority.toString(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    // Gérer createdAt qui peut être un Timestamp Firestore ou un int
    DateTime parsedDate;
    final createdAtValue = map['createdAt'];
    if (createdAtValue is Timestamp) {
      parsedDate = createdAtValue.toDate();
    } else if (createdAtValue is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
    } else {
      parsedDate = DateTime.now();
    }

    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'] || e.name == map['type'],
        orElse: () => NotificationType.info,
      ),
      entityId: map['entityId'],
      entityType: map['entityType'],
      createdAt: parsedDate,
      isRead: map['isRead'] ?? false,
      userId: map['userId'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
    );
  }
}

enum NotificationType {
  order,
  stock,
  review,
  promotion,
  system,
  user,
  info,
  success, // Ajouté pour compatibilité avec les écrans admin
  warning,
  error,
}

enum NotificationPriority { low, normal, high, urgent }