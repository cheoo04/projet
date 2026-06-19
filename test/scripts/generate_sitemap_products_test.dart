import 'package:flutter_test/flutter_test.dart';

import '../../scripts/generate_sitemap_products.dart' hide main;

void main() {
  group('extractProductId', () {
    test('extrait le dernier segment du nom Firestore', () {
      const name =
          'projects/first-pro-cheoo/databases/(default)/documents/products/ABC123';
      expect(extractProductId(name), 'ABC123');
    });
  });

  group('extractLastmod', () {
    test('convertit un timestamp ISO en date YYYY-MM-DD', () {
      expect(extractLastmod('2026-06-17T10:55:07.123456Z'), '2026-06-17');
    });

    test('retourne null si le timestamp est absent', () {
      expect(extractLastmod(null), isNull);
    });

    test('retourne null si le timestamp est vide', () {
      expect(extractLastmod(''), isNull);
    });
  });

  group('buildSitemapXml', () {
    test('génère une balise <url> par entrée avec lastmod optionnel', () {
      final urls = [
        UrlEntry(path: '/', changefreq: 'daily', priority: '1.0'),
        UrlEntry(
          path: '/product/ABC123',
          changefreq: 'weekly',
          priority: '0.7',
          lastmod: '2026-06-17',
        ),
      ];

      final xml = buildSitemapXml(urls, 'https://pharrellphone.com');

      expect(xml, contains('<loc>https://pharrellphone.com/</loc>'));
      expect(
        xml,
        contains('<loc>https://pharrellphone.com/product/ABC123</loc>'),
      );
      expect(xml, contains('<lastmod>2026-06-17</lastmod>'));
      expect(xml, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
    });

    test("n'ajoute pas de balise <lastmod> si absente", () {
      final urls = [
        UrlEntry(path: '/cart', changefreq: 'weekly', priority: '0.5'),
      ];
      final xml = buildSitemapXml(urls, 'https://pharrellphone.com');
      expect(xml, isNot(contains('<lastmod>')));
    });
  });

  group('buildStaticUrls', () {
    test('contient les 7 pages statiques attendues', () {
      final urls = buildStaticUrls();
      expect(urls.length, 7);
      expect(urls.map((u) => u.path), contains('/catalog'));
    });
  });
}
