import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Helper pour gérer les polices avec fallback vers polices locales
TextStyle _safeGoogleFont({
  required String fontFamily,
  TextStyle? textStyle,
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
}) {
  try {
    // Utiliser la police locale Poppins comme fallback principal
    if (fontFamily.toLowerCase() == 'poppins') {
      return TextStyle(
        fontFamily: 'Poppins', // Police locale définie dans pubspec.yaml
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    return GoogleFonts.getFont(
      fontFamily,
      textStyle: textStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  } catch (e) {
    // Fallback vers police locale Poppins si Google Fonts échoue
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

/// Système de thème complet pour Pharrell Phone
/// Support mode clair et sombre avec palette de couleurs du logo

class AppTheme {
  // ============================================
  // PALETTE DE COULEURS (EXTRAITE DU LOGO)
  // ============================================
  
  // Couleurs principales
  static const Color primaryViolet = Color(0xFF9B6DB8);
  static const Color secondaryVioletDark = Color(0xFF2D1B4E);
  static const Color accentVioletLight = Color(0xFFC084FC);
  
  // Couleurs de fond
  static const Color backgroundLight = Color(0xFFF8F7FC);
  static const Color backgroundDark = Color(0xFF1A0F2E);
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Couleurs d'état
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Couleurs neutres
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  
  // ============================================
  // THÈME CLAIR
  // ============================================
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Palette de couleurs
    colorScheme: ColorScheme.light(
      primary: primaryViolet,
      secondary: accentVioletLight,
      tertiary: secondaryVioletDark,
      surface: Colors.white,
      background: backgroundLight,
      error: error,
      onPrimary: Colors.white,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onError: Colors.white,
      outline: grey300,
      shadow: Colors.black.withOpacity(0.08),
    ),
    
    // Scaffold
    scaffoldBackgroundColor: backgroundLight,
    
    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: grey200, width: 1),
      ),
      shadowColor: Colors.black.withOpacity(0.04),
      margin: const EdgeInsets.all(0),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryViolet,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: _safeGoogleFont(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryViolet,
        side: const BorderSide(color: primaryViolet, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: _safeGoogleFont(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryViolet,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: _safeGoogleFont(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: grey50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: textSecondary,
      ),
      hintStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: grey400,
      ),
      errorStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: error,
      ),
    ),
    
    // Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryViolet,
      unselectedItemColor: grey400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: grey100,
      selectedColor: primaryViolet,
      disabledColor: grey200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14),
      secondaryLabelStyle: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: grey200,
      thickness: 1,
      space: 1,
    ),
    
    // Icon
    iconTheme: const IconThemeData(
      color: textSecondary,
      size: 24,
    ),
    
    // Typography
    textTheme: TextTheme(
      // Display (très grands titres)
      displayLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
      displayMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
      displaySmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
      
      // Headline (titres)
      headlineLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      headlineMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      headlineSmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      
      // Title (sous-titres)
      titleLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      titleSmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
      
      // Body (corps de texte)
      bodyLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
      bodyMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
      bodySmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
      
      // Label (labels)
      labelLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
      labelMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
      labelSmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w500, color: textSecondary),
    ),
  );
  
  // ============================================
  // THÈME SOMBRE
  // ============================================
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Palette de couleurs
    colorScheme: ColorScheme.dark(
      primary: accentVioletLight,
      secondary: primaryViolet,
      tertiary: secondaryVioletDark,
      surface: const Color(0xFF2D1B4E),
      background: backgroundDark,
      error: error,
      onPrimary: textPrimary,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
      outline: grey700,
      shadow: Colors.black.withOpacity(0.3),
    ),
    
    // Scaffold
    scaffoldBackgroundColor: backgroundDark,
    
    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF2D1B4E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: const Color(0xFF2D1B4E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: grey700.withOpacity(0.3), width: 1),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.all(0),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentVioletLight,
        foregroundColor: textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: _safeGoogleFont(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentVioletLight,
        side: const BorderSide(color: accentVioletLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: _safeGoogleFont(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentVioletLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: _safeGoogleFont(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: secondaryVioletDark.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: grey700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: grey700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentVioletLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: grey400,
      ),
      hintStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: grey500,
      ),
      errorStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: error,
      ),
    ),
    
    // Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF2D1B4E),
      selectedItemColor: accentVioletLight,
      unselectedItemColor: grey500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _safeGoogleFont(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: grey800,
      selectedColor: accentVioletLight,
      disabledColor: grey700,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, color: Colors.white),
      secondaryLabelStyle: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: grey700,
      thickness: 1,
      space: 1,
    ),
    
    // Icon
    iconTheme: const IconThemeData(
      color: grey400,
      size: 24,
    ),
    
    // Typography
    textTheme: TextTheme(
      // Display (très grands titres)
      displayLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      displaySmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      
      // Headline (titres)
      headlineLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
      headlineMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      headlineSmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      
      // Title (sous-titres)
      titleLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      titleSmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      
      // Body (corps de texte)
      bodyLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
      bodyMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
      bodySmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w400, color: grey400),
      
      // Label (labels)
      labelLarge: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      labelMedium: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: grey400),
      labelSmall: _safeGoogleFont(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w500, color: grey500),
    ),
  );
  
  // ============================================
  // HELPER FUNCTIONS
  // ============================================
  
  /// Récupère la couleur du badge de stock selon la quantité
  static Color getStockColor(int stock) {
    if (stock == 0) return error;
    if (stock < 10) return warning;
    return success;
  }
  
  /// Récupère le texte du badge de stock
  static String getStockText(int stock) {
    if (stock == 0) return 'Rupture';
    if (stock < 10) return 'Stock limité';
    return 'En stock';
  }
  
  /// Récupère l'icône du badge de stock
  static IconData getStockIcon(int stock) {
    if (stock == 0) return Icons.cancel;
    if (stock < 10) return Icons.warning_amber_rounded;
    return Icons.check_circle;
  }
}
