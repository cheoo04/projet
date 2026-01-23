import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';

/// Widget d'image optimisé avec gestion des erreurs
/// Affiche un placeholder élégant en cas d'erreur de chargement
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  
  const OptimizedImage({
    Key? key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.phone_android,
    this.iconSize = 48,
    this.iconColor,
    this.backgroundColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? Colors.grey.shade800 : AppTheme.grey100);
    final icColor = iconColor ?? (isDark ? Colors.grey.shade600 : AppTheme.grey400);
    
    // Vérifier si l'URL est valide
    final isValidUrl = imageUrl != null &&
      imageUrl!.isNotEmpty &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));
    
    Widget imageWidget;
    
    if (!isValidUrl) {
      // Afficher le placeholder
      imageWidget = _buildPlaceholder(bgColor, icColor);
    } else {
      // Utiliser CachedNetworkImage pour le cache
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingPlaceholder(bgColor, icColor),
        errorWidget: (context, url, error) => _buildPlaceholder(bgColor, icColor),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    }

    // Si des dimensions sont fournies, rendre avec SizedBox, sinon
    // laisser l'image remplir l'espace parent (utile dans les AppBar flexibles)
    Widget finalWidget;
    final hasFixedSize = width != null || height != null;
    if (hasFixedSize) {
      finalWidget = SizedBox(width: width, height: height, child: imageWidget);
    } else {
      finalWidget = ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: imageWidget,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: finalWidget,
      );
    }

    return finalWidget;
  }
  
  Widget _buildPlaceholder(Color bgColor, Color icColor) {
    // Si des dimensions fixes sont fournies, utiliser ces dimensions.
    // Sinon, retourner un conteneur expansible pour remplir l'espace parent.
    final effectiveHeight = height ?? 100;
    final effectiveWidth = width ?? 100;
    final minDimension = (effectiveHeight < effectiveWidth ? effectiveHeight : effectiveWidth);
    final effectiveIconSize = (minDimension * 0.5).clamp(16.0, 48.0);

    final content = Container(
      decoration: BoxDecoration(
        color: bgColor,
        gradient: LinearGradient(
          colors: [
            bgColor,
            bgColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: effectiveIconSize,
          color: icColor,
        ),
      ),
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: content);
    }

    return SizedBox.expand(child: content);
  }
  
  Widget _buildLoadingPlaceholder(Color bgColor, Color icColor) {
    final content = Container(
      color: bgColor,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryViolet.withOpacity(0.5),
          ),
        ),
      ),
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: content);
    }

    return SizedBox.expand(child: content);
  }
}

/// Widget d'image produit avec style spécifique
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  
  const ProductImage({
    Key? key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholderIcon: Icons.phone_android,
      iconSize: width != null && width! < 100 ? 32 : 48,
    );
  }
}

/// Widget d'avatar utilisateur
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? fallbackText;
  
  const UserAvatar({
    Key? key,
    this.imageUrl,
    this.size = 48,
    this.fallbackText,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isValidUrl = imageUrl != null && 
        imageUrl!.isNotEmpty && 
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));
    
    if (isValidUrl) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildFallback(context),
          errorWidget: (context, url, error) => _buildFallback(context),
        ),
      );
    }
    
    return _buildFallback(context);
  }
  
  Widget _buildFallback(BuildContext context) {
    final initial = fallbackText?.isNotEmpty == true 
        ? fallbackText![0].toUpperCase() 
        : '?';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryViolet,
            AppTheme.primaryViolet.withBlue(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
