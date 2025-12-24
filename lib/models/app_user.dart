import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { visitor, client, admin, manager }

class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;
  final Map<String, dynamic> permissions;
  final bool profileCompleted;

  AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
    this.role = UserRole.client,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.profileImageUrl,
    this.permissions = const {},
    this.profileCompleted = false,
  });

  String get fullName => '$firstName $lastName';
  String get name => fullName; // Compatibility

  bool get canAccessAdmin => role == UserRole.admin || role == UserRole.manager;
  bool get canManageUsers => role == UserRole.admin;
  bool get isClient => role == UserRole.client;
  bool get isAdmin => role == UserRole.admin;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
      'role': role.toString().split('.').last,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'profileImageUrl': profileImageUrl,
      'permissions': permissions,
      'profileCompleted': profileCompleted,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
      'role': role.toString().split('.').last,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'profileImageUrl': profileImageUrl,
      'permissions': permissions,
      'profileCompleted': profileCompleted,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phone: map['phone'],
      address: map['address'],
      role: _parseUserRole(map['role']),
      isActive: map['isActive'] ?? true,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDate(map['lastLoginAt']),
      profileImageUrl: map['profileImageUrl'],
      permissions: Map<String, dynamic>.from(map['permissions'] ?? {}),
      profileCompleted: map['profileCompleted'] ?? false,
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'],
      address: data['address'],
      role: _parseUserRole(data['role']),
      isActive: data['isActive'] ?? true,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDate(data['lastLoginAt']),
      profileImageUrl: data['profileImageUrl'],
      permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
      profileCompleted: data['profileCompleted'] ?? false,
    );
  }

  /// Parse une date qui peut être Timestamp, int (milliseconds), String ou null
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool hasPermission(String permission) {
    if (role == UserRole.admin) return true;
    return permissions[permission] == true;
  }

  AppUser copyWith({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    UserRole? role,
    bool? isActive,
    DateTime? lastLoginAt,
    String? profileImageUrl,
    Map<String, dynamic>? permissions,
    bool? profileCompleted,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      permissions: permissions ?? this.permissions,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }

  static UserRole _parseUserRole(String? roleString) {
    switch (roleString?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'client':
        return UserRole.client;
      default:
        return UserRole.visitor;
    }
  }
}
