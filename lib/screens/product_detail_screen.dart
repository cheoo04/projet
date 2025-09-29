import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  // Exemple de produit fictif
  final product = const {
    'id': '1',
    'name': 'iPhone 14',
    'category': 'phone',
    'brand': 'Apple',
    'price': 636400,
    'description': 'Nouveau smartphone Apple',
    'imageUrls': [
      'https://jeven.ci/cdn/shop/files/14-JVCI-MOB.jpg?v=1705107970&width=493',
    ],
    'isInStock': true,
  };

  void openWhatsApp(BuildContext context) async {
    String phone = "+2250788711896"; // Numéro de téléphone du vendeur
    String message =
        "Bonjour, je suis intéressé par ce produit : ${product['name']} (Réf: ${product['id']}). Pouvez-vous m'aider ?";
    String url = "https://wa.me/$phone?text=${Uri.encodeFull(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['name'] as String)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product['description'] as String),
            const SizedBox(height: 16),
            Text(
              'Prix: ${product['price']} FCFA',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openWhatsApp(context),
              child: const Text('Commander sur WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}
