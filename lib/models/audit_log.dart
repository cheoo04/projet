class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String entityType; // 'product', 'order', 'user', etc.
  final String entityId;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldValues = const {},
    this.newValues = const {},
    required this.timestamp,
    this.ipAddress = '',
    this.userAgent = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'oldValues': oldValues,
      'newValues': newValues,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      entityType: map['entityType'] ?? '',
      entityId: map['entityId'] ?? '',
      oldValues: Map<String, dynamic>.from(map['oldValues'] ?? {}),
      newValues: Map<String, dynamic>.from(map['newValues'] ?? {}),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      ipAddress: map['ipAddress'] ?? '',
      userAgent: map['userAgent'] ?? '',
    );
  }
}
