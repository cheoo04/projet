import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour gérer le mode clair/sombre de l'application
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Change le mode du thème
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    saveTheme(); // Sauvegarder automatiquement
  }
  
  /// Toggle entre clair et sombre
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
    saveTheme(); // Sauvegarder automatiquement
  }
  
  /// Charge le thème depuis les préférences
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs et utiliser le thème par défaut
      debugPrint('Erreur chargement thème: $e');
    }
  }
  
  /// Sauvegarde le thème dans les préférences
  Future<void> saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode);
    } catch (e) {
      debugPrint('Erreur sauvegarde thème: $e');
    }
  }
}
