import 'package:cloud_firestore/cloud_firestore.dart'
    hide Order; // hide Firestore internal Order type to use our model
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'orders';

  // Récupérer toutes les commandes
  Future<List<Order>> fetchAll() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commandes: $e');
    }
  }

  // Récupérer les commandes par statut
  Future<List<Order>> fetchByStatus(OrderStatus status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des commandes par statut: $e',
      );
    }
  }

  // Récupérer les commandes par période
  Future<List<Order>> fetchByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des commandes par période: $e',
      );
    }
  }

  // Ajouter une nouvelle commande
  Future<void> add(Order order) async {
    try {
      final data = order.toMap();
      // Ensure timestamps stored as Timestamp
      data['createdAt'] = Timestamp.fromDate(order.createdAt);
      if (order.updatedAt != null) {
        data['updatedAt'] = Timestamp.fromDate(order.updatedAt!);
      }
      // Idem pour les timestamps imbriqués de l'historique des statuts
      data['statusHistory'] = order.statusHistory
          .map(
            (entry) => {
              'status': entry.status.name,
              'timestamp': Timestamp.fromDate(entry.timestamp),
            },
          )
          .toList();
      await _firestore.collection(_collection).doc(order.id).set(data);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la commande: $e');
    }
  }

  // Mettre à jour une commande
  Future<void> update(Order order) async {
    try {
      final updatedOrder = order.copyWith(updatedAt: DateTime.now());
      final data = updatedOrder.toMap();
      data['createdAt'] = Timestamp.fromDate(updatedOrder.createdAt);
      data['updatedAt'] = Timestamp.fromDate(updatedOrder.updatedAt!);
      await _firestore.collection(_collection).doc(order.id).update(data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la commande: $e');
    }
  }

  // Mettre à jour le statut d'une commande (et l'ajouter à l'historique)
  Future<void> updateStatus(String orderId, OrderStatus newStatus) async {
    try {
      final now = Timestamp.now();
      await _firestore.collection(_collection).doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': now,
        'statusHistory': FieldValue.arrayUnion([
          {'status': newStatus.name, 'timestamp': now},
        ]),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Supprimer une commande
  Future<void> delete(String orderId) async {
    try {
      await _firestore.collection(_collection).doc(orderId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la commande: $e');
    }
  }

  // Obtenir les statistiques des commandes
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final orders = await fetchAll();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final thisMonthOrders = orders
          .where((order) => order.createdAt.isAfter(startOfMonth))
          .toList();

      final totalRevenue = orders.fold<double>(
        0,
        (somme, order) => somme + order.totalAmount,
      );

      final thisMonthRevenue = thisMonthOrders.fold<double>(
        0,
        (somme, order) => somme + order.totalAmount,
      );

      final statusCounts = <OrderStatus, int>{};
      for (final status in OrderStatus.values) {
        statusCounts[status] = orders.where((o) => o.status == status).length;
      }

      return {
        'totalOrders': orders.length,
        'thisMonthOrders': thisMonthOrders.length,
        'totalRevenue': totalRevenue,
        'thisMonthRevenue': thisMonthRevenue,
        'statusCounts': statusCounts,
        'averageOrderValue': orders.isNotEmpty
            ? totalRevenue / orders.length
            : 0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Stream pour écouter les changements en temps réel
  Stream<List<Order>> streamOrders() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream des commandes d'un client précis (pour "Mes Commandes" côté client).
  // Tri côté client (pas de orderBy) pour éviter d'exiger un index composite
  // Firestore sur (userId, createdAt).
  Stream<List<Order>> streamOrdersForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Order.fromMap(doc.data(), doc.id))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // Méthode getAll() pour compatibilité avec le dashboard
  Stream<List<Order>> getAll() {
    return streamOrders();
  }
}