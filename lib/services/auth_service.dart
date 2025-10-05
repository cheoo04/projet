import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import 'logging_service.dart';
import 'offline_cache_service.dart';
import 'biometric_auth_service.dart';
import '../firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;
  GoogleSignInAccount? _currentGoogleUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutTimes = {};
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeGoogleSignIn();
  }

  Future<void> initializeGoogleSignIn() async {
    if (_isGoogleSignInInitialized) return;

    String? clientId;
    String? serverClientId;

    if (kIsWeb) {
      clientId =
          '862175497641-18f06869ji7mk8dtc0ql04osqmuec6vj.apps.googleusercontent.com';
    } else if (Platform.isAndroid) {
      clientId =
          '862175497641-g1orna9etgt2trddq8ohohdomh6rpre6.apps.googleusercontent.com';
      serverClientId =
          '862175497641-18f06869ji7mk8dtc0ql04osqmuec6vj.apps.googleusercontent.com';
    } else if (Platform.isIOS) {
      clientId =
          '862175497641-rm0a9e645u6cj38vnlq507pnmealpest.apps.googleusercontent.com';
      serverClientId =
          '862175497641-18f06869ji7mk8dtc0ql04osqmuec6vj.apps.googleusercontent.com';
    }

    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    _isGoogleSignInInitialized = true;
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await initializeGoogleSignIn();
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (_isAccountLocked(email)) {
      final lockoutTime = _lockoutTimes[email]!;
      final remaining =
          lockoutDuration - DateTime.now().difference(lockoutTime);
      throw FirebaseAuthException(
        code: 'account-locked',
        message:
            'Compte verrouillé. Réessayez dans ${remaining.inMinutes} min.',
      );
    }
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _failedAttempts.remove(email);
      _lockoutTimes.remove(email);
      return cred;
    } catch (e) {
      _registerFailedAttempt(email);
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName, {
    UserRole role = UserRole.client,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) {
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileCompleted': false,
      });
    }
    return cred;
  }

  Future<AppUser?> signInWithGoogle() async {
    final offline = OfflineCacheService();
    if (!offline.isOnline) {
      throw Exception('Connexion Internet requise');
    }
    await _ensureGoogleSignInInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception('Google Sign-In non supporté');
    }
    final googleUser = await _googleSignIn.authenticate();
    _currentGoogleUser = googleUser;
    final googleAuth = googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw Exception('ID token manquant');
    }
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: null,
    );
    final uc = await _auth.signInWithCredential(credential);
    final fu = uc.user!;
    final existing = await _getUserData(fu.uid);
    if (existing == null) {
      final parts = googleUser.displayName?.split(' ') ?? ['', ''];
      final newUser = AppUser(
        id: fu.uid,
        email: fu.email ?? '',
        firstName: parts.first,
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        role: UserRole.client,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(fu.uid).set(newUser.toMap());
      return newUser;
    } else {
      await _firestore.collection('users').doc(fu.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
        'authProvider': 'google',
      });
      return existing;
    }
  }

  Future<void> signOutGoogle() async {
    await _ensureGoogleSignInInitialized();
    await _googleSignIn.signOut();
    _currentGoogleUser = null;
    await _auth.signOut();
    await clearCachedCredentials();
  }

  Future<String?> getGoogleAccessToken(List<String> scopes) async {
    await _ensureGoogleSignInInitialized();
    final user = _currentGoogleUser;
    if (user == null) {
      return null;
    }
    final authz = await user.authorizationClient.authorizationForScopes(scopes);
    return authz?.accessToken;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    final u = currentUser!;
    final data = <String, dynamic>{};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(u.uid).update(data);
  }

  Future<UserRole> getCurrentUserRole() async {
    final u = currentUser;
    if (u == null) {
      return UserRole.visitor;
    }
    final doc = await _firestore.collection('users').doc(u.uid).get();
    final s = doc.data()?['role'] as String?;
    return _parseRole(s);
  }

  /// Vérifie si l'utilisateur actuel a des droits d'administrateur
  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role.canAccessAdmin;
  }

  /// Vérifie si l'utilisateur actuel est un client
  Future<bool> isClient() async {
    final role = await getCurrentUserRole();
    return role == UserRole.client;
  }

  /// Authentification avec biométrie
  Future<bool> authenticateWithBiometrics({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final biometricAuth = BiometricAuthService();
      await biometricAuth.initialize();

      final result = await biometricAuth.authenticate(
        reason: reason,
        useErrorDialogs: useErrorDialogs,
        stickyAuth: stickyAuth,
      );

      return result.success;
    } catch (e) {
      LoggingService.error('Erreur authentification biométrique: $e');
      return false;
    }
  }

  /// Vérifie si l'authentification biométrique est activée pour l'utilisateur
  Future<bool> isBiometricEnabled() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['biometricEnabled'] as bool? ?? false;
    } catch (e) {
      LoggingService.error('Erreur vérification biométrie: $e');
      return false;
    }
  }

  /// Active ou désactive l'authentification biométrique pour l'utilisateur
  Future<void> setBiometricEnabled(bool enabled) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'biometricEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      LoggingService.info('Biométrie ${enabled ? 'activée' : 'désactivée'}');
    } catch (e) {
      LoggingService.error('Erreur configuration biométrie: $e');
      rethrow;
    }
  }

  Future<AppUser?> getCurrentUserData() async {
    return await _getUserData(currentUser?.uid);
  }

  Future<AppUser?> _getUserData(String? uid) async {
    if (uid == null) {
      return null;
    }
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    final d = doc.data()!;
    return AppUser(
      id: d['uid'],
      email: d['email'],
      firstName: d['firstName'],
      lastName: d['lastName'],
      role: _parseRole(d['role']),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isActive: d['isActive'] ?? true,
    );
  }

  void _registerFailedAttempt(String email) {
    _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
    if (_failedAttempts[email]! >= maxFailedAttempts) {
      _lockoutTimes[email] = DateTime.now();
    }
  }

  bool _isAccountLocked(String email) {
    final t = _lockoutTimes[email];
    if (t == null) {
      return false;
    }
    if (DateTime.now().difference(t) > lockoutDuration) {
      _lockoutTimes.remove(email);
      _failedAttempts.remove(email);
      return false;
    }
    return true;
  }

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'email-already-in-use':
          return 'Email déjà utilisé';
        case 'weak-password':
          return 'Mot de passe trop faible';
        case 'invalid-email':
          return 'Email invalide';
        case 'operation-not-allowed':
          return 'Opération non autorisée';
        case 'too-many-requests':
          return 'Trop de tentatives';
      }
    }
    return 'Erreur inattendue';
  }

  UserRole _parseRole(String? s) {
    switch (s?.toLowerCase()) {
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

  Future<void> clearCachedCredentials() async {
    final oc = OfflineCacheService();
    final u = currentUser;
    if (u?.email != null) {
      await oc.saveSetting('cached_password_${u!.email}', null);
      await oc.saveSetting('cached_user_${u.email}', null);
    }
  }
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.visitor:
        return 'Visiteur';
      case UserRole.client:
        return 'Client';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.manager:
        return 'Manager';
    }
  }

  bool get canAccessAdmin => this == UserRole.admin || this == UserRole.manager;
  bool get canManageUsers => this == UserRole.admin;
  bool get canViewOrders => this != UserRole.visitor;
}
