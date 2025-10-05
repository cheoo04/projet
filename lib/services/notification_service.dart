import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Créer une notification
  Future<void> create({
    required String title,
    required String message,
    required NotificationType type,
    required String userId,
    String? entityId,
    String? entityType,
    Map<String, dynamic> data = const {},
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      userId: userId,
      entityId: entityId,
      entityType: entityType,
      createdAt: DateTime.now(),
      data: data,
      priority: priority,
    );

    await _firestore
        .collection(_collection)
        .doc(notification.id)
        .set(notification.toMap());
  }

  // Créer une notification pour tous les admins
  Future<void> createForAllAdmins({
    required String title,
    required String message,
    required NotificationType type,
    String? entityId,
    String? entityType,
    Map<String, dynamic> data = const {},
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    // Obtenir tous les utilisateurs admin
    final adminUsers = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'UserRole.admin')
        .get();

    final batch = _firestore.batch();
    for (final adminDoc in adminUsers.docs) {
      final notification = AppNotification(
        id: '${DateTime.now().millisecondsSinceEpoch}_${adminDoc.id}',
        title: title,
        message: message,
        type: type,
        userId: adminDoc.id,
        entityId: entityId,
        entityType: entityType,
        createdAt: DateTime.now(),
        data: data,
        priority: priority,
      );

      batch.set(
        _firestore.collection(_collection).doc(notification.id),
        notification.toMap(),
      );
    }

    await batch.commit();
  }

  // Obtenir les notifications d'un utilisateur
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data()))
              .toList(),
        );
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'isRead': true,
    });
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Supprimer une notification
  Future<void> delete(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).delete();
  }

  // Obtenir le nombre de notifications non lues
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Nettoyer les anciennes notifications
  Future<void> cleanOldNotifications(String userId, int daysToKeep) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('createdAt', isLessThan: cutoffDate.millisecondsSinceEpoch)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Notifications spécifiques métier
  Future<void> notifyLowStock(
    String productId,
    String productName,
    int currentStock,
  ) async {
    await createForAllAdmins(
      title: 'Stock faible',
      message:
          'Le produit "$productName" a un stock faible ($currentStock unités)',
      type: NotificationType.stock,
      entityId: productId,
      entityType: 'product',
      priority: NotificationPriority.high,
      data: {'currentStock': currentStock, 'productName': productName},
    );
  }

  Future<void> notifyNewOrder(
    String orderId,
    String customerName,
    double amount,
  ) async {
    await createForAllAdmins(
      title: 'Nouvelle commande',
      message:
          'Nouvelle commande de $customerName pour ${amount.toStringAsFixed(0)} FCFA',
      type: NotificationType.order,
      entityId: orderId,
      entityType: 'order',
      priority: NotificationPriority.normal,
      data: {'customerName': customerName, 'amount': amount},
    );
  }

  Future<void> notifyNewReview(
    String productId,
    String productName,
    int rating,
  ) async {
    await createForAllAdmins(
      title: 'Nouvel avis',
      message: 'Nouvel avis ($rating⭐) sur "$productName"',
      type: NotificationType.review,
      entityId: productId,
      entityType: 'product',
      priority: NotificationPriority.normal,
      data: {'productName': productName, 'rating': rating},
    );
  }
}
