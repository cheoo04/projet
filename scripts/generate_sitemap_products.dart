/// Génère web/sitemap.xml : pages statiques + une URL par produit Firestore.
///
/// Usage : dart run scripts/generate_sitemap_products.dart
/// Exécuté automatiquement en CI avant le build web (voir
/// .github/workflows/deploy-web.yml). Lecture Firestore publique (règles :
/// `allow read: if true` sur la collection products), aucune auth requise.
///
/// En cas d'erreur réseau ou de réponse inattendue, le script ne touche PAS
/// à web/sitemap.xml : le fichier existant reste en place et le script sort
/// sans erreur (le déploiement ne doit jamais être bloqué par le sitemap).

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String siteUrl = 'https://pharrellphone.com';
const String _projectId = 'first-pro-cheoo';
const String _outputPath = 'web/sitemap.xml';

void main() async {
  print('🗺️  Génération du sitemap.xml...');

  final staticUrls = buildStaticUrls();

  List<UrlEntry> productUrls;
  try {
    productUrls = await fetchProductUrls(_projectId);
    print('✅ ${productUrls.length} produit(s) récupéré(s) depuis Firestore');
  } catch (error) {
    print('⚠️  Impossible de récupérer les produits depuis Firestore : $error');
    print('ℹ️  web/sitemap.xml conservé tel quel (pages statiques uniquement).');
    return;
  }

  final allUrls = [...staticUrls, ...productUrls];
  final xml = buildSitemapXml(allUrls, siteUrl);

  await File(_outputPath).writeAsString(xml);
  print('✅ Sitemap généré : $_outputPath (${allUrls.length} URLs au total)');
}

/// Pages statiques toujours incluses dans le sitemap.
List<UrlEntry> buildStaticUrls() {
  return [
    UrlEntry(path: '/', changefreq: 'daily', priority: '1.0'),
    UrlEntry(path: '/catalog', changefreq: 'daily', priority: '0.9'),
    UrlEntry(path: '/cart', changefreq: 'weekly', priority: '0.5'),
    UrlEntry(path: '/account', changefreq: 'monthly', priority: '0.4'),
    UrlEntry(
      path: '/catalog?category=Smartphones',
      changefreq: 'daily',
      priority: '0.8',
    ),
    UrlEntry(
      path: '/catalog?category=Accessoires',
      changefreq: 'daily',
      priority: '0.8',
    ),
    UrlEntry(
      path: '/catalog?category=Promotions',
      changefreq: 'daily',
      priority: '0.8',
    ),
  ];
}

/// Récupère les produits depuis l'API REST Firestore (lecture publique).
Future<List<UrlEntry>> fetchProductUrls(String projectId) async {
  final uri = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/products?pageSize=300',
  );

  final response = await http.get(uri).timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode} : ${response.body}');
  }

  final data = json.decode(response.body) as Map<String, dynamic>;
  final documents = data['documents'] as List<dynamic>? ?? [];

  return documents.map((doc) {
    final docMap = doc as Map<String, dynamic>;
    return UrlEntry(
      path: '/product/${extractProductId(docMap['name'] as String)}',
      changefreq: 'weekly',
      priority: '0.7',
      lastmod: extractLastmod(docMap['updateTime'] as String?),
    );
  }).toList();
}

/// Extrait l'ID du document depuis le nom complet retourné par l'API REST
/// Firestore, ex: "projects/x/databases/(default)/documents/products/ABC123"
/// -> "ABC123".
String extractProductId(String firestoreName) {
  return firestoreName.split('/').last;
}

/// Convertit un timestamp ISO 8601 Firestore en date simple "YYYY-MM-DD"
/// pour la balise <lastmod>. Retourne null si le timestamp est absent/vide.
String? extractLastmod(String? updateTime) {
  if (updateTime == null || updateTime.isEmpty) return null;
  return updateTime.split('T').first;
}

/// Génère le contenu XML complet du sitemap à partir d'une liste d'URLs.
String buildSitemapXml(List<UrlEntry> urls, String baseUrl) {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln(
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
  );

  for (final url in urls) {
    buffer.writeln('  <url>');
    buffer.writeln('    <loc>$baseUrl${url.path}</loc>');
    if (url.lastmod != null) {
      buffer.writeln('    <lastmod>${url.lastmod}</lastmod>');
    }
    buffer.writeln('    <changefreq>${url.changefreq}</changefreq>');
    buffer.writeln('    <priority>${url.priority}</priority>');
    buffer.writeln('  </url>');
  }

  buffer.writeln('</urlset>');
  return buffer.toString();
}

/// Une entrée d'URL du sitemap.
class UrlEntry {
  final String path;
  final String changefreq;
  final String priority;
  final String? lastmod;

  UrlEntry({
    required this.path,
    required this.changefreq,
    required this.priority,
    this.lastmod,
  });
}
