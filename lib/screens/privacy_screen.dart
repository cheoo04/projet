import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Écran de politique de confidentialité
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
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
                    Icons.privacy_tip,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Votre vie privée est importante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dernière mise à jour : Décembre 2025',
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
          
          _buildSection(
            context,
            icon: Icons.info_outline,
            title: 'Introduction',
            content: '''Pharrell Phone ("nous", "notre", "nos") s'engage à protéger la vie privée de ses utilisateurs. Cette politique de confidentialité explique comment nous collectons, utilisons et protégeons vos informations personnelles lorsque vous utilisez notre application.''',
          ),
          
          _buildSection(
            context,
            icon: Icons.data_usage,
            title: 'Données collectées',
            content: '''Nous collectons les informations suivantes :

• Informations de compte : nom, email, numéro de téléphone
• Adresses de livraison
• Historique des commandes
• Préférences et favoris
• Données de connexion (Google, téléphone)

Ces données sont nécessaires pour :
- Gérer votre compte
- Traiter vos commandes
- Vous contacter si nécessaire
- Améliorer nos services''',
          ),
          
          _buildSection(
            context,
            icon: Icons.storage,
            title: 'Stockage des données',
            content: '''Vos données sont stockées de manière sécurisée sur les serveurs Firebase de Google, situés dans des centres de données certifiés.

Nous conservons vos données :
• Données de compte : tant que votre compte est actif
• Historique des commandes : 5 ans (obligations légales)
• Données de navigation : 12 mois maximum''',
          ),
          
          _buildSection(
            context,
            icon: Icons.share_outlined,
            title: 'Partage des données',
            content: '''Nous ne vendons jamais vos données personnelles.

Vos données peuvent être partagées avec :
• Nos partenaires de livraison (pour livrer vos commandes)
• Les prestataires de paiement (pour traiter les transactions)
• Les autorités légales (si requis par la loi)

Tous nos partenaires sont tenus de respecter la confidentialité de vos données.''',
          ),
          
          _buildSection(
            context,
            icon: Icons.security,
            title: 'Sécurité',
            content: '''Nous mettons en œuvre des mesures de sécurité appropriées :

• Chiffrement des données en transit (HTTPS/SSL)
• Authentification sécurisée (Firebase Auth)
• Accès restreint aux données personnelles
• Surveillance continue des systèmes

En cas de violation de données, nous vous informerons dans les meilleurs délais.''',
          ),
          
          _buildSection(
            context,
            icon: Icons.person_outline,
            title: 'Vos droits',
            content: '''Conformément à la réglementation, vous avez le droit de :

• Accéder à vos données personnelles
• Rectifier vos informations
• Supprimer votre compte et vos données
• Retirer votre consentement
• Exporter vos données

Pour exercer ces droits, contactez-nous via l'application ou par email.''',
          ),
          
          _buildSection(
            context,
            icon: Icons.phone_android,
            title: 'Permissions de l\'application',
            content: '''Notre application peut demander les permissions suivantes :

• Appareil photo : pour scanner des QR codes ou prendre des photos
• Stockage : pour sauvegarder des images
• Notifications : pour vous informer de vos commandes
• Localisation : pour améliorer les suggestions de livraison

Vous pouvez gérer ces permissions dans les paramètres de votre téléphone.''',
          ),
          
          _buildSection(
            context,
            icon: Icons.cookie_outlined,
            title: 'Cookies et suivi',
            content: '''Notre application utilise des technologies de suivi pour :

• Mémoriser vos préférences
• Analyser l'utilisation de l'application
• Améliorer nos services

Nous utilisons Firebase Analytics pour comprendre comment notre application est utilisée, sans collecter d'informations personnellement identifiables.''',
          ),
          
          _buildSection(
            context,
            icon: Icons.child_care,
            title: 'Protection des mineurs',
            content: '''Notre application n'est pas destinée aux enfants de moins de 16 ans. Nous ne collectons pas sciemment d'informations auprès de mineurs.

Si vous êtes parent et découvrez que votre enfant nous a fourni des informations, contactez-nous pour que nous puissions supprimer ces données.''',
          ),
          
          _buildSection(
            context,
            icon: Icons.update,
            title: 'Modifications',
            content: '''Nous pouvons mettre à jour cette politique de confidentialité périodiquement. Les modifications significatives vous seront notifiées via l'application.

Nous vous encourageons à consulter régulièrement cette page pour rester informé de nos pratiques.''',
          ),
          
          const SizedBox(height: 24),
          
          // Contact
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.contact_mail,
                      color: AppTheme.primaryViolet,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Nous contacter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pour toute question concernant cette politique de confidentialité ou vos données personnelles, contactez-nous :',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildContactInfo(Icons.email, 'farelgoumo@gmail.com'),
                const SizedBox(height: 8),
                _buildContactInfo(Icons.phone, '+225 07 88 71 18 96'),
                const SizedBox(height: 8),
                _buildContactInfo(Icons.location_on, 'Abidjan, Côte d\'Ivoire'),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Footer
          Center(
            child: Text(
              '© 2025 Pharrell Phone. Tous droits réservés.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryViolet, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              content,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryViolet),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
