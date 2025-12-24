import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Configuration optimisée de Firestore pour performances maximales
class FirestoreConfig {
  static bool _isConfigured = false;

  /// Configure Firestore avec les paramètres optimaux
  static Future<void> configure() async {
    if (_isConfigured) {
      debugPrint('ℹ️ Firestore déjà configuré, skip');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // Sur web, on ne peut pas reconfigurer les settings après le premier accès
      // On essaie de configurer mais on capture l'erreur si déjà configuré
      if (!kIsWeb) {
        // 1. Activer le cache persistant (offline-first) - mobile uniquement
        final settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Cache illimité
        );
        firestore.settings = settings;
      }

      // 2. En mode debug : utiliser l'émulateur si disponible (optionnel)
      if (kDebugMode) {
        try {
          // Décommenter si vous utilisez l'émulateur Firestore local
          // firestore.useFirestoreEmulator('localhost', 8080);
          debugPrint('🔧 Firestore: Mode debug');
        } catch (e) {
          debugPrint('Émulateur Firestore non disponible: $e');
        }
      }

      _isConfigured = true;
      debugPrint('✅ Firestore configuré avec cache persistant illimité');
    } catch (e) {
      // Sur web, l'erreur "already called" est normale si on accède à Firestore avant configure()
      if (e.toString().contains('already been called') || e.toString().contains('failed-precondition')) {
        _isConfigured = true;
        debugPrint('ℹ️ Firestore était déjà configuré (normal sur web)');
      } else {
        debugPrint('❌ Erreur configuration Firestore: $e');
        rethrow;
      }
    }
  }

  /// Efface le cache Firestore (utile pour déconnexion ou debugging)
  static Future<void> clearCache() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
      debugPrint('🗑️ Cache Firestore effacé');
    } catch (e) {
      debugPrint('Erreur effacement cache: $e');
    }
  }

  /// Désactiver le réseau (mode offline forcé)
  static Future<void> disableNetwork() async {
    await FirebaseFirestore.instance.disableNetwork();
    debugPrint('📵 Firestore: Mode offline');
  }

  /// Réactiver le réseau
  static Future<void> enableNetwork() async {
    await FirebaseFirestore.instance.enableNetwork();
    debugPrint('📶 Firestore: Mode online');
  }
}
