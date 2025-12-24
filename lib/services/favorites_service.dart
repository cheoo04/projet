import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les produits favoris
class FavoritesService {
  static const String _favoritesKey = 'favorite_products';
  
  /// Récupérer la liste des IDs de produits favoris
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    
    if (favoritesJson == null || favoritesJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  /// Vérifier si un produit est en favoris
  static Future<bool> isFavorite(String productId) async {
    final favorites = await getFavorites();
    return favorites.contains(productId);
  }
  
  /// Ajouter un produit aux favoris
  static Future<bool> addFavorite(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      if (!favorites.contains(productId)) {
        favorites.add(productId);
        await prefs.setString(_favoritesKey, jsonEncode(favorites));
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Retirer un produit des favoris
  static Future<bool> removeFavorite(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      favorites.remove(productId);
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Basculer l'état favori d'un produit
  static Future<bool> toggleFavorite(String productId) async {
    final isFav = await isFavorite(productId);
    
    if (isFav) {
      await removeFavorite(productId);
      return false; // N'est plus favori
    } else {
      await addFavorite(productId);
      return true; // Est maintenant favori
    }
  }
  
  /// Effacer tous les favoris
  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
  
  /// Nombre de favoris
  static Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}
