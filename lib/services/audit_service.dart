import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'audit_logs';

  // Enregistrer une action
  Future<void> log({
    required String userId,
    required String userName,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic> oldValues = const {},
    Map<String, dynamic> newValues = const {},
    String ipAddress = '',
    String userAgent = '',
  }) async {
    final auditLog = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      oldValues: oldValues,
      newValues: newValues,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    await _firestore
        .collection(_collection)
        .doc(auditLog.id)
        .set(auditLog.toMap());
  }

  // Obtenir les logs d'audit avec pagination
  Stream<List<AuditLog>> getLogs({
    int limit = 50,
    String? userId,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection(_collection);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType);
    }

    if (startDate != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
      );
    }

    if (endDate != null) {
      query = query.where(
        'timestamp',
        isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
      );
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // Obtenir les statistiques d'audit
  Future<Map<String, int>> getStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();
    final logs = snapshot.docs
        .map((doc) => AuditLog.fromMap(doc.data()))
        .toList();

    final stats = <String, int>{};
    for (final log in logs) {
      stats[log.action] = (stats[log.action] ?? 0) + 1;
    }

    return stats;
  }

  // Nettoyer les anciens logs (garder seulement les N derniers jours)
  Future<void> cleanOldLogs(int daysToKeep) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final snapshot = await _firestore
        .collection(_collection)
        .where('timestamp', isLessThan: cutoffDate.millisecondsSinceEpoch)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
