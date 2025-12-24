import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';

/// Écran d'aide et FAQ
class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryViolet,
                  AppTheme.accentVioletLight,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comment pouvons-nous vous aider ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trouvez des réponses à vos questions ou contactez-nous',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick contact
          Row(
            children: [
              Expanded(
                child: _buildContactCard(
                  context,
                  icon: Icons.chat,
                  title: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _openWhatsApp(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactCard(
                  context,
                  icon: Icons.phone,
                  title: 'Appeler',
                  color: AppTheme.info,
                  onTap: () => _makeCall(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactCard(
                  context,
                  icon: Icons.email,
                  title: 'Email',
                  color: AppTheme.warning,
                  onTap: () => _sendEmail(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // FAQ Section
          Text(
            'Questions fréquentes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildFaqItem(
            context,
            question: 'Comment passer une commande ?',
            answer: 'Parcourez notre catalogue, ajoutez les produits souhaités au panier, puis validez votre commande. Vous pouvez également commander directement via WhatsApp.',
          ),
          _buildFaqItem(
            context,
            question: 'Quels sont les délais de livraison ?',
            answer: 'Nous livrons généralement sous 24 à 48h à Abidjan. Pour les autres villes, comptez 3 à 5 jours ouvrables.',
          ),
          _buildFaqItem(
            context,
            question: 'Comment suivre ma commande ?',
            answer: 'Rendez-vous dans "Mes commandes" depuis votre compte. Vous y trouverez le statut de toutes vos commandes.',
          ),
          _buildFaqItem(
            context,
            question: 'Quels modes de paiement acceptez-vous ?',
            answer: 'Nous acceptons le paiement à la livraison (cash), Mobile Money (Orange Money, MTN, Moov) et les virements bancaires.',
          ),
          _buildFaqItem(
            context,
            question: 'Puis-je retourner un produit ?',
            answer: 'Oui, vous disposez de 7 jours après réception pour retourner un produit dans son état d\'origine. Contactez-nous pour organiser le retour.',
          ),
          _buildFaqItem(
            context,
            question: 'Les produits sont-ils garantis ?',
            answer: 'Tous nos produits neufs sont garantis 12 mois. Les produits reconditionnés bénéficient d\'une garantie de 6 mois.',
          ),
          
          const SizedBox(height: 24),
          
          // Contact info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nous contacter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactInfo(Icons.phone, '+225 07 88 71 18 96'),
                const SizedBox(height: 12),
                _buildContactInfo(Icons.email, 'farelgoumo@gmail.com'),
                const SizedBox(height: 12),
                _buildContactInfo(Icons.location_on, 'Abidjan, Côte d\'Ivoire'),
                const SizedBox(height: 12),
                _buildContactInfo(Icons.access_time, 'Disponible 24h/24 - 7j/7'),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryViolet),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
  
  void _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/2250788711896?text=${Uri.encodeComponent("Bonjour, j'ai besoin d'aide.")}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening WhatsApp: $e');
    }
  }
  
  void _makeCall() async {
    final url = Uri.parse('tel:+2250788711896');
    try {
      await launchUrl(url);
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }
  
  void _sendEmail() async {
    final url = Uri.parse('mailto:farelgoumo@gmail.com?subject=Demande d\'aide - Pharrell Phone');
    try {
      await launchUrl(url);
    } catch (e) {
      debugPrint('Error sending email: $e');
    }
  }
}
