import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/crash_handler.dart';

/// Mixin pour simplifier la gestion d'erreurs dans les widgets
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  
  /// Exécute une action avec gestion d'erreur automatique
  Future<void> safeExecute(
    Future<void> Function() action, {
    String? context,
    Function(Object error)? onError,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      // Report automatique
      CrashHandler.recordError(
        error,
        stackTrace,
        context: context ?? runtimeType.toString(),
      );
      
      // Callback personnalisé
      onError?.call(error);
      
      // Afficher un message à l'utilisateur si contexte disponible
      if (mounted) {
        _showErrorSnackBar(error.toString());
      }
    }
  }

  /// Exécute une action synchrone avec gestion d'erreur
  R? safeExecuteSync<R>(
    R Function() action, {
    String? context,
    R? defaultValue,
    Function(Object error)? onError,
  }) {
    try {
      return action();
    } catch (error, stackTrace) {
      // Report automatique
      CrashHandler.recordError(
        error,
        stackTrace,
        context: context ?? runtimeType.toString(),
      );
      
      // Callback personnalisé
      onError?.call(error);
      
      return defaultValue;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ${message.length > 100 ? '${message.substring(0, 100)}...' : message}'),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}

/// Extension pour Future avec gestion d'erreur simplifiée
extension SafeFuture<T> on Future<T> {
  Future<T?> catchAndReport({
    String? context,
    T? defaultValue,
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      CrashHandler.recordError(
        error,
        stackTrace,
        context: context ?? 'Future execution',
      );
      return defaultValue;
    }
  }
}

/// Wrapper pour les opérations réseau
class NetworkErrorHandler {
  static Future<T?> handleNetworkCall<T>(
    Future<T> Function() networkCall, {
    String? operation,
    T? defaultValue,
    bool showUserMessage = true,
  }) async {
    try {
      return await networkCall();
    } catch (error, stackTrace) {
      final context = 'Network: ${operation ?? 'Unknown operation'}';
      
      // Ajouter des métadonnées réseau
      FirebaseCrashlytics.instance.setCustomKey('network_operation', operation ?? 'unknown');
      FirebaseCrashlytics.instance.setCustomKey('error_type', 'network');
      
      CrashHandler.recordError(error, stackTrace, context: context);
      
      return defaultValue;
    }
  }
}

/// Builder pour créer des widgets avec gestion d'erreur intégrée
class SafeWidgetBuilder extends StatelessWidget {
  final Widget Function() builder;
  final String? context;
  final Widget? errorWidget;

  const SafeWidgetBuilder({
    super.key,
    required this.builder,
    this.context,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return builder();
    } catch (error, stackTrace) {
      CrashHandler.recordError(
        error,
        stackTrace,
        context: this.context ?? 'Widget Builder',
      );
      
      return errorWidget ?? ErrorDisplayWidget(
        error: error,
        context: this.context,
      );
    }
  }
}

/// Widget affiché en cas d'erreur
class ErrorDisplayWidget extends StatelessWidget {
  final Object error;
  final String? context;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Une erreur s\'est produite',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (this.context != null) ...[
            const SizedBox(height: 4),
            Text(
              'Contexte: ${this.context}',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'L\'erreur a été signalée automatiquement.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}