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
import 'fcm_service.dart';
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
    } else if (!kIsWeb && Platform.isAndroid) {
      clientId =
          '862175497641-g1orna9etgt2trddq8ohohdomh6rpre6.apps.googleusercontent.com';
      serverClientId =
          '862175497641-18f06869ji7mk8dtc0ql04osqmuec6vj.apps.googleusercontent.com';
    } else if (!kIsWeb && Platform.isIOS) {
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
      // Rafraîchir le token FCM après connexion réussie
      await FCMService().refreshToken();
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
      // Rafraîchir le token FCM pour le nouvel utilisateur
      await FCMService().refreshToken();
    }
    return cred;
  }

  Future<AppUser?> signInWithGoogle() async {
    debugPrint('🔐 signInWithGoogle() appelé - kIsWeb: $kIsWeb');
    
    final offline = OfflineCacheService();
    if (!offline.isOnline) {
      throw Exception('Connexion Internet requise');
    }
    
    try {
      UserCredential userCredential;
      String? googleDisplayName;
      String? googleEmail;
      
      if (kIsWeb) {
        debugPrint('🌐 Web détecté - utilisation de signInWithPopup');
        // Sur le web, utiliser signInWithPopup directement
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        userCredential = await _auth.signInWithPopup(googleProvider);
        debugPrint('✅ signInWithPopup réussi');
        // Sur le web, on récupère les infos depuis le userCredential
        googleDisplayName = userCredential.user?.displayName;
        googleEmail = userCredential.user?.email;
      } else {
        // Sur mobile, utiliser Google Sign-In natif
        await _ensureGoogleSignInInitialized();
        if (!_googleSignIn.supportsAuthenticate()) {
          throw Exception('Google Sign-In non supporté sur cet appareil');
        }
        
        // Authentification Google
        final googleUser = await _googleSignIn.authenticate();
        _currentGoogleUser = googleUser;
        googleDisplayName = googleUser.displayName;
        googleEmail = googleUser.email;
        
        // Récupérer le token d'authentification
        final googleAuth = googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Token d\'authentification manquant');
        }
        
        // Créer les credentials Firebase
        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: null,
        );
        
        userCredential = await _auth.signInWithCredential(credential);
      }
      
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception('Échec de la connexion');
      }
      
      // Récupérer ou créer le profil utilisateur dans Firestore
      final existingUser = await _getUserData(firebaseUser.uid);
      
      if (existingUser != null) {
        // Utilisateur existant - mettre à jour la dernière connexion
        await _firestore.collection('users').doc(firebaseUser.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        });
        // Rafraîchir le token FCM
        await FCMService().refreshToken();
        return existingUser;
      } else {
        // Nouvel utilisateur - créer le profil
        final String displayName = googleDisplayName ?? firebaseUser.displayName ?? '';
        final String email = firebaseUser.email ?? googleEmail ?? '';
        
        final List<String> nameParts = displayName.isNotEmpty 
            ? displayName.split(' ') 
            : <String>[];
        final String firstName = nameParts.isNotEmpty 
            ? nameParts.first 
            : (email.isNotEmpty ? email.split('@').first : 'Utilisateur');
        final String lastName = nameParts.length > 1 
            ? nameParts.sublist(1).join(' ') 
            : '';
        
        final newUser = AppUser(
          id: firebaseUser.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: UserRole.client,
          createdAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toFirestore());
        // Rafraîchir le token FCM pour le nouvel utilisateur
        await FCMService().refreshToken();
        return newUser;
      }
    } catch (e) {
      // Si l'erreur contient "null" et "String", c'est probablement un problème de token
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('null') && errorStr.contains('string')) {
        // Vérifier si l'utilisateur est quand même connecté à Firebase
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final userData = await _getUserData(currentUser.uid);
          if (userData != null) {
            return userData;
          }
        }
      }
      rethrow;
    }
  }

  Future<void> signOutGoogle() async {
    await _ensureGoogleSignInInitialized();
    // Supprimer le token FCM avant la déconnexion
    await FCMService().removeToken();
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
    // Supprimer le token FCM avant la déconnexion
    await FCMService().removeToken();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        // Redirige vers pharrellphone.com après reset
        url: 'https://pharrellphone.com',
        handleCodeInApp: false,
        androidPackageName: 'com.example.pharrell_phone',
        androidInstallApp: true,
        androidMinimumVersion: '23',
        iOSBundleId: 'com.example.pharrellPhone',
      ),
    );
  }

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    final u = currentUser;
    if (u == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Toujours mettre à jour firstName et lastName s'ils sont fournis (même vides)
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    
    debugPrint('=== updateUserProfile ===');
    debugPrint('uid: ${u.uid}');
    debugPrint('data: $data');
    
    await _firestore.collection('users').doc(u.uid).update(data);
    
    debugPrint('Mise à jour réussie');
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
      id: d['uid'] ?? uid,
      email: d['email'] ?? '',
      firstName: d['firstName'] ?? '',
      lastName: d['lastName'] ?? '',
      role: _parseRole(d['role']),
      createdAt: _parseDateTime(d['createdAt']) ?? DateTime.now(),
      isActive: d['isActive'] ?? true,
    );
  }

  /// Parse une date qui peut être Timestamp, int, String ou null
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
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
          return 'Aucun utilisateur trouvé avec cet email';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'invalid-credential':
          return 'Email ou mot de passe incorrect';
        case 'invalid-email':
          return 'Email invalide';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé';
        case 'weak-password':
          return 'Mot de passe trop faible (min. 6 caractères)';
        case 'operation-not-allowed':
          return 'Opération non autorisée';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard.';
        case 'user-disabled':
          return 'Ce compte a été désactivé';
        case 'network-request-failed':
          return 'Erreur réseau. Vérifiez votre connexion.';
        default:
          debugPrint('⚠️ Firebase Auth Error: ${e.code} - ${e.message}');
          return 'Email ou mot de passe incorrect';
      }
    }
    // Gérer les exceptions standard
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
      return 'Email ou mot de passe incorrect';
    }
    if (errorStr.contains('user-not-found')) {
      return 'Aucun compte avec cet email';
    }
    if (errorStr.contains('network')) {
      return 'Erreur réseau. Vérifiez votre connexion.';
    }
    debugPrint('⚠️ Auth error: $e');
    return 'Email ou mot de passe incorrect';
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

  // ============================================
  // AUTHENTIFICATION PAR TÉLÉPHONE (SMS)
  // ============================================

  /// Envoyer un code SMS au numéro de téléphone
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String errorMessage) onVerificationFailed,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-vérification sur Android
          onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(_handleAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      debugPrint('Erreur verification téléphone: $e');
      rethrow;
    }
  }

  /// Vérifier le code SMS et se connecter
  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Créer le profil utilisateur si nouveau
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfileFromPhone(
          uid: userCredential.user!.uid,
          phone: userCredential.user!.phoneNumber,
          firstName: firstName,
          lastName: lastName,
        );
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Se connecter avec les credentials téléphone (auto-verification Android)
  Future<UserCredential> signInWithPhoneCredential({
    required PhoneAuthCredential credential,
  }) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Créer le profil utilisateur depuis l'auth téléphone
  Future<void> _createUserProfileFromPhone({
    required String uid,
    String? phone,
    String? firstName,
    String? lastName,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'phone': phone ?? '',
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'role': 'client',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============================================
  // AUTHENTIFICATION ANONYME
  // ============================================

  /// Connexion anonyme
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();

      // Créer un profil minimal
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'role': 'visitor',
          'isAnonymous': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Convertir un compte anonyme en compte permanent avec email
  Future<UserCredential> linkAnonymousWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final result = await currentUser!.linkWithCredential(credential);
      
      // Mettre à jour le profil
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'email': email,
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'role': 'client',
        'isAnonymous': false,
      });

      return result;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Convertir un compte anonyme avec Google
  Future<UserCredential?> linkAnonymousWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      
      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('Google Sign-In non supporté');
      }
      
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        throw Exception('ID token manquant');
      }
      
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: null,
      );

      final result = await currentUser!.linkWithCredential(credential);
      
      // Mettre à jour le profil
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'email': googleUser.email,
        'firstName': googleUser.displayName?.split(' ').first ?? '',
        'lastName': googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        'photoUrl': googleUser.photoUrl,
        'role': 'client',
        'isAnonymous': false,
      });

      return result;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Convertir un compte anonyme avec téléphone
  Future<UserCredential> linkAnonymousWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final result = await currentUser!.linkWithCredential(credential);
      
      // Mettre à jour le profil
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'phone': currentUser!.phoneNumber,
        'role': 'client',
        'isAnonymous': false,
      });

      return result;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============================================
  // RÉINITIALISATION MOT DE PASSE
  // ============================================

  /// Envoyer un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Envoyer un lien de connexion par email (passwordless)
  Future<void> sendSignInLinkToEmail({
    required String email,
    required String redirectUrl,
  }) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: redirectUrl,
        handleCodeInApp: true,
        androidPackageName: 'com.example.pharrell_phone',
        androidInstallApp: true,
        androidMinimumVersion: '23',
        iOSBundleId: 'com.example.pharrellPhone',
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Connexion admin avec vérification du rôle
  /// Retourne l'AppUser si c'est un admin/manager, sinon lance une exception
  Future<AppUser> signInAsAdmin(String email, String password) async {
    try {
      // 1. Connexion Firebase Auth
      final cred = await signInWithEmailAndPassword(email, password);
      if (cred?.user == null) {
        throw Exception('Échec de la connexion');
      }

      // 2. Récupérer les données utilisateur depuis Firestore
      final doc = await _firestore.collection('users').doc(cred!.user!.uid).get();
      
      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('Compte utilisateur non trouvé');
      }

      final userData = doc.data()!;
      final roleStr = userData['role'] as String? ?? 'client';
      final role = _parseRole(roleStr);

      // 3. Vérifier si c'est un admin ou manager
      if (!role.canAccessAdmin) {
        await _auth.signOut();
        throw Exception('Accès refusé. Vous n\'êtes pas administrateur.');
      }

      // 4. Mettre à jour la dernière connexion
      await _firestore.collection('users').doc(cred.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // 5. Retourner l'AppUser
      return AppUser.fromFirestore(doc);
    } catch (e) {
      if (e is Exception) rethrow;
      throw _handleAuthException(e);
    }
  }

  /// Créer un compte admin (à utiliser une seule fois pour setup initial)
  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
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
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'profileCompleted': true,
          'permissions': {
            'manageProducts': true,
            'manageOrders': true,
            'manageUsers': true,
            'manageStock': true,
            'viewAnalytics': true,
          },
        });
      }
    } catch (e) {
      throw _handleAuthException(e);
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