// Configuration des polices pour Flutter Web
// Résout les problèmes de chargement de Google Fonts

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontConfig {
  // Configuration pour désactiver Google Fonts si nécessaire
  static const bool useGoogleFonts =
      true; // Mettre à false si problèmes persistent

  // Thème principal avec gestion des erreurs de polices
  static ThemeData getAppTheme() {
    try {
      if (useGoogleFonts) {
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          textTheme: GoogleFonts.robotoTextTheme(),
          fontFamily: GoogleFonts.roboto().fontFamily,
        );
      }
    } catch (e) {
      // En cas d'erreur avec Google Fonts, utiliser les polices système
      debugPrint('Erreur Google Fonts détectée: $e');
      debugPrint('Utilisation des polices système de fallback');
    }

    // Thème de fallback avec polices système
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      fontFamily: _getSystemFont(),
    );
  }

  // Obtenir la police système appropriée selon la plateforme
  static String _getSystemFont() {
    // Pour Flutter Web, utiliser les polices web standards
    return 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
  }

  // TextTheme de fallback sans Google Fonts
  static TextTheme getFallbackTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  // Obtenir un TextStyle safe qui ne crash pas
  static TextStyle getSafeTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    try {
      if (useGoogleFonts) {
        return GoogleFonts.roboto(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      }
    } catch (e) {
      // Fallback en cas d'erreur
    }

    return TextStyle(
      fontFamily: _getSystemFont(),
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Vérifier si Google Fonts est disponible
  static Future<bool> isGoogleFontsAvailable() async {
    try {
      // Tenter de charger une police Google Fonts
      await GoogleFonts.pendingFonts([GoogleFonts.roboto()]);
      return true;
    } catch (e) {
      debugPrint('Google Fonts non disponible: $e');
      return false;
    }
  }
}
