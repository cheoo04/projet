import 'package:flutter/material.dart';
import 'app_toast.dart';

// Re-export pour compatibilité avec le code existant
export 'app_toast.dart' show AppToast, ToastType;

/// Types de notification (compat)
enum SnackBarType { success, error, info, warning }

/// Wrapper de compatibilité — délègue à AppToast (position haut, non-bloquant).
/// Tous les anciens appels CustomSnackBar.show() continuent de fonctionner.
class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToast.show(
      context,
      message,
      type: _convert(type),
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void success(BuildContext context, String message,
      {String? actionLabel, VoidCallback? onAction}) =>
      AppToast.success(context, message, actionLabel: actionLabel, onAction: onAction);

  static void error(BuildContext context, String message) =>
      AppToast.error(context, message);

  static void warning(BuildContext context, String message) =>
      AppToast.warning(context, message);

  static void info(BuildContext context, String message,
      {String? actionLabel, VoidCallback? onAction}) =>
      AppToast.info(context, message, actionLabel: actionLabel, onAction: onAction);

  static void cartAdded(BuildContext context, {
    required int quantity,
    required String productName,
    VoidCallback? onViewCart,
  }) {
    AppToast.success(
      context,
      '$quantity × $productName ajouté au panier',
      actionLabel: onViewCart != null ? 'VOIR' : null,
      onAction: onViewCart,
    );
  }

  static ToastType _convert(SnackBarType t) {
    switch (t) {
      case SnackBarType.success: return ToastType.success;
      case SnackBarType.error:   return ToastType.error;
      case SnackBarType.warning: return ToastType.warning;
      case SnackBarType.info:    return ToastType.info;
    }
  }
}