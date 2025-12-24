/// Script Dart pour générer le sitemap avec les produits depuis Firestore
/// Usage: dart run scripts/generate_sitemap_products.dart
/// 
/// Note: Nécessite les credentials Firebase configurés

import 'dart:io';

void main() async {
  print('🗺️ Génération du sitemap.xml avec produits...');
  
  const siteUrl = 'https://first-pro-cheoo.web.app';
  final buffer = StringBuffer();
  
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
  
  // Pages statiques
  buffer.writeln(_buildUrl(siteUrl, '/', 'daily', '1.0'));
  buffer.writeln(_buildUrl(siteUrl, '/catalog', 'daily', '0.9'));
  buffer.writeln(_buildUrl(siteUrl, '/cart', 'weekly', '0.5'));
  buffer.writeln(_buildUrl(siteUrl, '/account', 'monthly', '0.4'));
  
  // Catégories
  buffer.writeln(_buildUrl(siteUrl, '/catalog?category=Smartphones', 'daily', '0.8'));
  buffer.writeln(_buildUrl(siteUrl, '/catalog?category=Accessoires', 'daily', '0.8'));
  buffer.writeln(_buildUrl(siteUrl, '/catalog?category=Promotions', 'daily', '0.8'));
  
  // TODO: Ajouter les produits depuis Firestore
  // Pour l'instant, on génère des exemples
  final sampleProducts = [
    'iphone-15-pro-max',
    'samsung-galaxy-s24-ultra',
    'google-pixel-8-pro',
    'airpods-pro-2',
    'apple-watch-ultra-2',
  ];
  
  for (final productId in sampleProducts) {
    buffer.writeln(_buildUrl(siteUrl, '/product/$productId', 'weekly', '0.7'));
  }
  
  buffer.writeln('</urlset>');
  
  // Écrire le fichier
  final file = File('web/sitemap.xml');
  await file.writeAsString(buffer.toString());
  
  print('✅ Sitemap généré: web/sitemap.xml');
  print('📊 ${sampleProducts.length + 7} URLs incluses');
}

String _buildUrl(String siteUrl, String path, String changefreq, String priority) {
  return '''  <url>
    <loc>$siteUrl$path</loc>
    <changefreq>$changefreq</changefreq>
    <priority>$priority</priority>
  </url>''';
}
