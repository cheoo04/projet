import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'optimized_image.dart';

/// Composants UI réutilisables pour l'application Pharrell Phone
/// Respecte la charte graphique et supporte les thèmes clair/sombre

// ============================================
// BOUTONS
// ============================================

/// Bouton primaire avec gradient violet
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  
  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppTheme.accentVioletLight, AppTheme.primaryViolet]
            : [AppTheme.primaryViolet, AppTheme.accentVioletLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.accentVioletLight : AppTheme.primaryViolet).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppTheme.textPrimary : Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: isDark ? AppTheme.textPrimary : Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark ? AppTheme.textPrimary : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Bouton secondaire (outlined)
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;
  
  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.height = 56,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
        label: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

// ============================================
// CARDS
// ============================================

// NOTE: Pour les cartes produits, utilisez :
// - OptimizedProductCard : Pour les grilles de catalogue (signaux de confiance complets)
// - CompactProductCard : Pour les listes horizontales
// - EnhancedProductCard : Pour les détails/listes verticales
// Voir: lib/widgets/optimized_product_card.dart et lib/widgets/enhanced_product_card.dart

/// Card catégorie pour l'écran d'accueil
class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  
  const CategoryCard({
    Key? key,
    required this.title,
    required this.icon,
    this.onTap,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = color ?? AppTheme.primaryViolet;
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône avec fond coloré
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(isDark ? 0.3 : 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: categoryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              
              // Titre
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// BADGES
// ============================================

/// Badge de stock (en stock, stock limité, rupture)
class StockBadge extends StatelessWidget {
  final int stock;
  final bool isInStock;
  final int lowStockThreshold;
  
  const StockBadge({
    Key? key,
    required this.stock,
    required this.isInStock,
    this.lowStockThreshold = 5,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    if (!isInStock || stock <= 0) {
      color = Colors.grey;
      icon = Icons.cancel;
      text = 'Rupture';
    } else if (stock <= lowStockThreshold) {
      color = const Color(0xFFF59E0B);
      icon = Icons.warning_amber;
      text = 'Reste $stock';
    } else {
      color = const Color(0xFF16A34A);
      icon = Icons.check_circle;
      text = 'En stock';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de compteur (pour le panier)
class CounterBadge extends StatelessWidget {
  final int count;
  
  const CounterBadge({Key? key, required this.count}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================
// ÉTATS VIDES
// ============================================

/// Widget pour afficher un état vide
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final String? actionLabel;  // Alias pour buttonText
  final VoidCallback? onButtonPressed;
  final VoidCallback? onAction;  // Alias pour onButtonPressed
  
  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.actionLabel,
    this.onButtonPressed,
    this.onAction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppTheme.primaryViolet,
              ),
            ),
            const SizedBox(height: 24),
            
            // Titre
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Bouton optionnel (supporte buttonText/actionLabel et onButtonPressed/onAction)
            if ((buttonText != null || actionLabel != null) && 
                (onButtonPressed != null || onAction != null)) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: buttonText ?? actionLabel!,
                onPressed: onButtonPressed ?? onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================
// INPUTS
// ============================================

/// Search bar avec style Pharrell Phone
class SearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  
  const SearchBar({
    Key? key,
    this.controller,
    this.hintText = 'Rechercher...',
    this.onChanged,
    this.onClear,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }
}

// ============================================
// AUTRES
// ============================================

/// Switch pour le mode sombre/clair
class ThemeSwitcher extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;
  
  const ThemeSwitcher({
    Key? key,
    required this.isDarkMode,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.wb_sunny,
          color: !isDarkMode ? AppTheme.primaryViolet : AppTheme.grey400,
        ),
        const SizedBox(width: 8),
        Switch(
          value: isDarkMode,
          onChanged: onChanged,
          activeColor: AppTheme.accentVioletLight,
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.nights_stay,
          color: isDarkMode ? AppTheme.accentVioletLight : AppTheme.grey400,
        ),
      ],
    );
  }
}

/// Séparateur avec texte
class SectionDivider extends StatelessWidget {
  final String text;
  
  const SectionDivider({Key? key, required this.text}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  
  const LoadingOverlay({Key? key, this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
