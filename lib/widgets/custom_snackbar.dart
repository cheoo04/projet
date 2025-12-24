import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Types de notification
enum SnackBarType { success, error, info, warning }

/// Helper pour afficher des SnackBars modernes et stylés
class CustomSnackBar {
  /// Affiche un SnackBar moderne avec une durée courte
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Fermer le SnackBar précédent s'il existe
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Couleurs selon le type
    Color backgroundColor;
    Color iconColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF2E7D32);
        iconColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = const Color(0xFFC62828);
        iconColor = Colors.white;
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFFEF6C00);
        iconColor = Colors.white;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = AppTheme.primaryViolet;
        iconColor = Colors.white;
        icon = Icons.info_rounded;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }
  
  /// Raccourci pour afficher un message de succès
  static void success(BuildContext context, String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: const Duration(seconds: 2),
    );
  }
  
  /// Raccourci pour afficher une erreur
  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      duration: const Duration(seconds: 4),
    );
  }
  
  /// Raccourci pour afficher un avertissement
  static void warning(BuildContext context, String message) {
    show(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Raccourci pour afficher une info
  static void info(BuildContext context, String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Affiche une notification de produit ajouté au panier
  static void cartAdded(BuildContext context, {
    required int quantity,
    required String productName,
    VoidCallback? onViewCart,
  }) {
    // Fermer le SnackBar précédent
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ajouté au panier !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$quantity × $productName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
        action: onViewCart != null
            ? SnackBarAction(
                label: 'VOIR',
                textColor: Colors.white,
                onPressed: onViewCart,
              )
            : null,
      ),
    );
  }
}
