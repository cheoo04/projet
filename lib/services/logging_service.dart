import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

enum LogLevel { debug, info, warning, error, critical }

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log un message avec niveau spécifique
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? category,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    _instance._logMessage(message, level, category, data, stackTrace);
  }

  /// Logs spécialisés par niveau
  static void debug(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    log(message, level: LogLevel.debug, category: category, data: data);
  }

  static void info(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    log(message, level: LogLevel.info, category: category, data: data);
  }

  static void warning(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    log(message, level: LogLevel.warning, category: category, data: data);
  }

  static void error(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    log(
      message,
      level: LogLevel.error,
      category: category,
      data: data,
      stackTrace: stackTrace,
    );
  }

  static void critical(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    log(
      message,
      level: LogLevel.critical,
      category: category,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Logs spécialisés pour l'authentification
  static void authSuccess(String action, String userId) {
    log(
      'Authentication success: $action',
      level: LogLevel.info,
      category: 'AUTH',
      data: {
        'action': action,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static void authFailure(String action, String error, {String? email}) {
    log(
      'Authentication failure: $action',
      level: LogLevel.warning,
      category: 'AUTH',
      data: {
        'action': action,
        'error': error,
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static void securityAlert(String message, {Map<String, dynamic>? data}) {
    log(
      'SECURITY ALERT: $message',
      level: LogLevel.critical,
      category: 'SECURITY',
      data: data,
    );
  }

  void _logMessage(
    String message,
    LogLevel level,
    String? category,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  ) {
    final timestamp = DateTime.now();
    final logData = {
      'message': message,
      'level': level.name,
      'category': category ?? 'GENERAL',
      'timestamp': timestamp.toIso8601String(),
      'userId': _auth.currentUser?.uid,
      'data': data,
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };

    // Log en console pour debug
    if (kDebugMode) {
      _printToConsole(message, level, category, timestamp);
    }

    // Log vers Firebase en production uniquement pour erreurs critiques
    if (!kDebugMode &&
        (level == LogLevel.error || level == LogLevel.critical)) {
      _logToFirestore(logData);
    }

    // Log vers service externe en production (ex: Crashlytics, Sentry)
    if (!kDebugMode) {
      _logToExternalService(logData);
    }
  }

  void _printToConsole(
    String message,
    LogLevel level,
    String? category,
    DateTime timestamp,
  ) {
    final prefix = _getLevelPrefix(level);
    final categoryStr = category != null ? '[$category] ' : '';
    final timeStr = timestamp.toIso8601String().substring(11, 19);

    if (kDebugMode) {
      print('$timeStr $prefix $categoryStr$message');
    }
  }

  String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 DEBUG';
      case LogLevel.info:
        return '💡 INFO';
      case LogLevel.warning:
        return '⚠️ WARNING';
      case LogLevel.error:
        return '❌ ERROR';
      case LogLevel.critical:
        return '🚨 CRITICAL';
    }
  }

  Future<void> _logToFirestore(Map<String, dynamic> logData) async {
    try {
      await _firestore.collection('app_logs').add(logData);
    } catch (e) {
      // Éviter les boucles infinies de logs
      if (kDebugMode) {
        print('Failed to log to Firestore: $e');
      }
    }
  }

  void _logToExternalService(Map<String, dynamic> logData) {
    // Intégration avec les services de monitoring externes
    try {
      // Firebase Crashlytics (si disponible)
      _logToCrashlytics(logData);

      // Sentry (si configuré)
      _logToSentry(logData);

      // Console en mode debug
      if (kDebugMode) {
        _logToConsole(logData);
      }
    } catch (e) {
      // Éviter les boucles infinies de logs
      if (kDebugMode) {
        print('Failed to log to external service: $e');
      }
    }
  }

  void _logToCrashlytics(Map<String, dynamic> logData) {
    try {
      // Décommentez et configurez si Firebase Crashlytics est ajouté au projet
      FirebaseCrashlytics.instance.log(logData.toString());

      // Pour les erreurs critiques, envoyer comme exception
      if (logData['level'] == 'critical' || logData['level'] == 'error') {
        FirebaseCrashlytics.instance.recordError(
          logData['message'],
          logData['stackTrace'],
          information: [
            DiagnosticsProperty('category', logData['category']),
            DiagnosticsProperty('userId', logData['userId']),
            DiagnosticsProperty('data', logData['data']),
          ],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Crashlytics logging failed: $e');
      }
    }
  }

  void _logToSentry(Map<String, dynamic> logData) {
    try {
      // Décommentez et configurez si Sentry est ajouté au projet
      // import 'package:sentry_flutter/sentry_flutter.dart';

      // if (logData['level'] == 'critical' || logData['level'] == 'error') {
      //   Sentry.captureException(
      //     logData['message'],
      //     stackTrace: logData['stackTrace'],
      //     withScope: (scope) {
      //       scope.setTag('category', logData['category'] ?? 'unknown');
      //       scope.setUser(SentryUser(id: logData['userId']));
      //       scope.setContext('log_data', logData['data'] ?? {});
      //     },
      //   );
      // } else {
      //   Sentry.addBreadcrumb(Breadcrumb(
      //     message: logData['message'],
      //     level: _mapLogLevelToSentry(logData['level']),
      //     category: logData['category'],
      //     data: logData['data'],
      //   ));
      // }
    } catch (e) {
      if (kDebugMode) {
        print('Sentry logging failed: $e');
      }
    }
  }

  void _logToConsole(Map<String, dynamic> logData) {
    final timestamp = DateTime.now().toIso8601String();
    final level = logData['level']?.toString().toUpperCase() ?? 'INFO';
    final category = logData['category'] ?? 'APP';
    final message = logData['message'];
    final userId = logData['userId'] ?? 'anonymous';

    print('[$timestamp] [$level] [$category] [$userId] $message');

    if (logData['data'] != null) {
      debugPrint('  Data: ${logData['data']}');
    }

    if (logData['stackTrace'] != null) {
      debugPrint('  StackTrace: ${logData['stackTrace']}');
    }
  }

  // Helper pour mapper les niveaux de log vers Sentry
  // SentryLevel _mapLogLevelToSentry(String? level) {
  //   switch (level) {
  //     case 'debug':
  //       return SentryLevel.debug;
  //     case 'info':
  //       return SentryLevel.info;
  //     case 'warning':
  //       return SentryLevel.warning;
  //     case 'error':
  //       return SentryLevel.error;
  //     case 'critical':
  //       return SentryLevel.fatal;
  //     default:
  //       return SentryLevel.info;
  //   }
  // }

  /// Nettoie les anciens logs (à appeler périodiquement)
  static Future<void> cleanOldLogs({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final query = FirebaseFirestore.instance
          .collection('app_logs')
          .where('timestamp', isLessThan: cutoffDate.toIso8601String());

      final snapshot = await query.get();
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      LoggingService.info('Cleaned ${snapshot.docs.length} old log entries');
    } catch (e) {
      LoggingService.error(
        'Failed to clean old logs',
        data: {'error': e.toString()},
      );
    }
  }

  // Aliases pour compatibilité avec d'autres services
  static void logError(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    LoggingService.error(
      message,
      data: {'error': error?.toString()},
      stackTrace: stackTrace,
    );
  }

  static void logInfo(String message, [Map<String, dynamic>? extra]) {
    LoggingService.info(message, data: extra);
  }
}
