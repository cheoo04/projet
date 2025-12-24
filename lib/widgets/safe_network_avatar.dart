import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Avatar avec gestion d'erreur pour les images réseau
/// Affiche les initiales en fallback si l'image ne charge pas
class SafeNetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const SafeNetworkAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.primaryViolet.withOpacity(0.1);
    final fgColor = textColor ?? AppTheme.primaryViolet;
    final textSize = fontSize ?? (radius * 0.6);

    // Si pas d'URL, afficher directement le fallback
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          _getInitials(fallbackText),
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
      );
    }

    // Avec URL, utiliser Image.network avec errorBuilder
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // En cas d'erreur (429, 404, etc.), afficher les initiales
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: bgColor,
              child: Center(
                child: Text(
                  _getInitials(fallbackText),
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: bgColor,
              child: Center(
                child: SizedBox(
                  width: radius * 0.8,
                  height: radius * 0.8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Extrait les initiales d'un nom
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
