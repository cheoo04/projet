import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Service de gestion centralisée des crashes et erreurs
class CrashHandler {
  static bool _isInitialized = false;

  /// Initialise le gestionnaire de crashes
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Crashlytics n'est pas supporté sur le web
      if (kIsWeb) {
        print('ℹ️ CrashHandler: Crashlytics non disponible sur web - utilisation des logs console');
        _setupWebErrorHandling();
        _isInitialized = true;
        return;
      }
      
      // Configuration selon l'environnement
      if (kDebugMode) {
        // En debug, désactiver la collecte automatique
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
        print('🔧 CrashHandler: Mode debug - Crashlytics désactivé');
      } else {
        // En production, activer la collecte
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        print('🚀 CrashHandler: Mode production - Crashlytics activé');
      }

      // Capturer les erreurs Flutter
      FlutterError.onError = (FlutterErrorDetails details) {
        if (kDebugMode) {
          // En debug, garder le comportement par défaut + log
          FlutterError.presentError(details);
          print('🐛 Flutter Error: ${details.exception}');
        } else {
          // En production, envoyer à Crashlytics
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };

      // Capturer les erreurs async non gérées
      PlatformDispatcher.instance.onError = (error, stack) {
        if (kDebugMode) {
          print('🔥 Async Error: $error');
          print('Stack: $stack');
        } else {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return true;
      };

      _isInitialized = true;
      print('✅ CrashHandler initialisé avec succès');
    } catch (e) {
      print('❌ Erreur initialisation CrashHandler: $e');
    }
  }

  /// Configuration du gestionnaire d'erreurs pour le web
  static void _setupWebErrorHandling() {
    // Capturer les erreurs Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('🐛 [Web] Flutter Error: ${details.exception}');
    };

    // Capturer les erreurs async non gérées
    PlatformDispatcher.instance.onError = (error, stack) {
      print('🔥 [Web] Async Error: $error');
      print('Stack: $stack');
      return true;
    };
  }

  /// Enregistre une erreur avec contexte
  static void recordError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    try {
      // Sur le web, juste logger
      if (kIsWeb) {
        print('🔥 [Web] Error: $error');
        if (context != null) print('   Context: $context');
        return;
      }
      
      // Ajouter des informations contextuelles
      if (context != null) {
        FirebaseCrashlytics.instance.setCustomKey('error_context', context);
      }
      
      // Enregistrer l'erreur
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        information: context != null ? [context] : [],
      );
      
      // Log local en debug
      if (kDebugMode) {
        print('🔥 CrashHandler: $error');
        if (context != null) print('   Context: $context');
      }
    } catch (e) {
      // Fallback si Crashlytics échoue
      if (kDebugMode) {
        print('❌ Échec enregistrement crash: $e');
        print('   Erreur originale: $error');
      }
    }
  }

  /// Enregistre un log personnalisé
  static void log(String message) {
    try {
      if (kIsWeb) {
        print('📝 [Web] Log: $message');
        return;
      }
      FirebaseCrashlytics.instance.log(message);
      if (kDebugMode) {
        print('📝 CrashHandler Log: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Échec log: $e');
      }
    }
  }

  /// Définit une clé personnalisée
  static void setCustomKey(String key, dynamic value) {
    try {
      if (kIsWeb) {
        print('🔑 [Web] Key: $key = $value');
        return;
      }
      FirebaseCrashlytics.instance.setCustomKey(key, value);
      if (kDebugMode) {
        print('🔑 CrashHandler Key: $key = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Échec setCustomKey: $e');
      }
    }
  }

  /// Définit l'identifiant utilisateur
  static void setUserIdentifier(String identifier) {
    try {
      if (kIsWeb) {
        print('👤 [Web] User: $identifier');
        return;
      }
      FirebaseCrashlytics.instance.setUserIdentifier(identifier);
      if (kDebugMode) {
        print('👤 CrashHandler User: $identifier');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Échec setUserIdentifier: $e');
      }
    }
  }

  /// Teste le crash handler (debug uniquement)
  static void testCrash() {
    if (kDebugMode) {
      print('🧪 Test crash handler...');
      throw Exception('Test crash intentionnel');
    }
  }

  /// Vérifie si le service est initialisé
  static bool get isInitialized => _isInitialized;
}