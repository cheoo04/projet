import 'package:flutter/material.dart';

/// Configuration responsive pour le support web/desktop
/// Définit les breakpoints et helpers pour adapter l'UI
class ResponsiveBreakpoints {
  // Breakpoints standards
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1800;

  // Constructeur privé
  ResponsiveBreakpoints._();

  /// Vérifie si l'écran est de taille mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Vérifie si l'écran est de taille tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// Vérifie si l'écran est de taille desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Vérifie si l'écran est de taille large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktop;
  }

  /// Retourne le type d'écran actuel
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return ScreenType.mobile;
    if (width < tablet) return ScreenType.tablet;
    if (width < desktop) return ScreenType.desktop;
    return ScreenType.largeDesktop;
  }

  /// Retourne une valeur adaptée au type d'écran
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Retourne le nombre de colonnes pour une grille
  static int gridColumns(BuildContext context) {
    return value(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
      largeDesktop: 5,
    );
  }

  /// Retourne le padding horizontal adapté
  static double horizontalPadding(BuildContext context) {
    return value(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 48.0,
      largeDesktop: 80.0,
    );
  }

  /// Retourne la largeur maximale du contenu
  static double maxContentWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
      largeDesktop: 1400.0,
    );
  }
}

/// Types d'écran supportés
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Widget helper qui rebuild automatiquement lors des changements de taille
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, ResponsiveBreakpoints.getScreenType(context));
      },
    );
  }
}

/// Widget qui affiche différents enfants selon le type d'écran
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType) {
        switch (screenType) {
          case ScreenType.mobile:
            return mobile;
          case ScreenType.tablet:
            return tablet ?? mobile;
          case ScreenType.desktop:
          case ScreenType.largeDesktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Wrapper qui centre le contenu avec une largeur maximale (pour desktop)
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveBreakpoints.maxContentWidth(context);
    final effectivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: ResponsiveBreakpoints.horizontalPadding(context),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}
