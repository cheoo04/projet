import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../models/app_user.dart';
import '../widgets/safe_network_avatar.dart';
import '../widgets/responsive_scaffold.dart';
import '../providers/app_providers.dart';
import '../widgets/optimized_image.dart';
import '../web_config/navigation_helper.dart';
import '../web_config/responsive_config.dart';

/// Écran Compte unifié
/// - Non connecté : affiche boutons connexion/inscription
/// - Client connecté : affiche profil + commandes
/// - Admin connecté : affiche dashboard admin + switch mode client
class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isAdminMode = true; // Pour admin : switch entre mode admin et client

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _currentUser = AppUser.fromFirestore(doc);
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement utilisateur: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const ResponsiveScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Non connecté ou utilisateur anonyme → écran de connexion simplifié
    if (user == null || user.isAnonymous) {
      return _buildNotLoggedInScreen(context, isDark);
    }
    
    // Admin connecté
    if (_currentUser?.role == 'admin' || _currentUser?.role == 'manager') {
      if (_isAdminMode) {
        return _buildAdminDashboard(context, isDark);
      } else {
        return _buildClientProfile(context, isDark, isAdmin: true);
      }
    }
    
    // Client connecté
    return _buildClientProfile(context, isDark);
  }

  /// Écran pour utilisateur non connecté
  Widget _buildNotLoggedInScreen(BuildContext context, bool isDark) {
    return ResponsiveScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryViolet.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 60,
                  color: AppTheme.primaryViolet,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Mon Compte',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                'Connectez-vous pour accéder à vos commandes, gérer votre profil et plus encore.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              
              // Bouton Connexion
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    AppNavigator.push(context, AppNavigator.authRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Bouton Inscription
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    AppNavigator.push(context, AppNavigator.authRoute);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryViolet),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Continuer sans compte
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Continuer sans compte',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Profil client
  Widget _buildClientProfile(BuildContext context, bool isDark, {bool isAdmin = false}) {
    final user = FirebaseAuth.instance.currentUser;
    
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Mon Compte'),
        actions: [
          if (isAdmin)
            TextButton.icon(
              onPressed: () => setState(() => _isAdminMode = true),
              icon: const Icon(Icons.admin_panel_settings, size: 18),
              label: const Text('Mode Admin'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card Profil
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar
                    SafeNetworkAvatar(
                      imageUrl: user?.photoURL,
                      fallbackText: _currentUser?.fullName ?? user?.displayName ?? 'U',
                      radius: 35,
                    ),
                    const SizedBox(width: 16),
                    
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser?.fullName ?? user?.displayName ?? 'Utilisateur',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          if (_currentUser?.phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _currentUser!.phone!,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Edit button
                    IconButton(
                      onPressed: () => _showEditProfileDialog(context),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Menu options
            _buildMenuSection(context, isDark, 'Mes achats', [
              _buildMenuItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Mes commandes',
                subtitle: 'Voir l\'historique de vos commandes',
                onTap: () => AppNavigator.push(context, AppNavigator.myOrdersRoute),
              ),
              _buildMenuItem(
                icon: Icons.favorite_outline,
                title: 'Mes favoris',
                subtitle: 'Produits que vous avez aimés',
                onTap: () => _showFavorites(context),
              ),
            ]),
            const SizedBox(height: 16),
            
            _buildMenuSection(context, isDark, 'Paramètres', [
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Gérer les notifications',
                onTap: () => AppNavigator.push(context, AppNavigator.notificationsRoute),
              ),
              _buildMenuItem(
                icon: Icons.location_on_outlined,
                title: 'Adresses de livraison',
                subtitle: 'Gérer vos adresses',
                onTap: () => AppNavigator.push(context, AppNavigator.addressesRoute),
              ),
              _buildMenuItem(
                icon: Icons.lock_outline,
                title: 'Sécurité',
                subtitle: 'Mot de passe et connexion',
                onTap: () => AppNavigator.push(context, AppNavigator.securityRoute),
              ),
            ]),
            const SizedBox(height: 16),
            
            _buildMenuSection(context, isDark, 'Support', [
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Aide',
                subtitle: 'FAQ et support',
                onTap: () => AppNavigator.push(context, AppNavigator.helpRoute),
              ),
              _buildMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Confidentialité',
                subtitle: 'Politique et vie privée',
                onTap: () => AppNavigator.push(context, AppNavigator.privacyRoute),
              ),
            ]),
            const SizedBox(height: 24),
            
            // Bouton déconnexion
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Se déconnecter', style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Dashboard Admin
  Widget _buildAdminDashboard(BuildContext context, bool isDark) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isAdminMode = false),
            icon: const Icon(Icons.person_outline, size: 18),
            label: const Text('Mode Client'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bienvenue Admin
          Card(
            color: AppTheme.primaryViolet,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${_currentUser?.firstName ?? 'Admin'}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gérez votre activité Pharrell Phone',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Stats (placeholder)
          Row(
            children: [
              Expanded(child: _buildStatCard('Commandes', '12', Icons.shopping_bag, AppTheme.info)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Produits', '48', Icons.inventory, AppTheme.success)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Clients', '156', Icons.people, AppTheme.warning)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Menu Admin
          Text(
            'Gestion',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildAdminMenuItem(
            icon: Icons.inventory_2_outlined,
            title: 'Produits',
            subtitle: 'Gérer le catalogue',
            color: AppTheme.primaryViolet,
            onTap: () => AppNavigator.push(context, AppNavigator.adminRoute),
          ),
          _buildAdminMenuItem(
            icon: Icons.shopping_cart_outlined,
            title: 'Commandes',
            subtitle: 'Voir et traiter les commandes',
            color: AppTheme.info,
            onTap: () => AppNavigator.push(context, AppNavigator.adminRoute),
          ),
          _buildAdminMenuItem(
            icon: Icons.category_outlined,
            title: 'Catégories',
            subtitle: 'Organiser les produits',
            color: AppTheme.success,
            onTap: () => AppNavigator.push(context, AppNavigator.adminRoute),
          ),
          _buildAdminMenuItem(
            icon: Icons.local_offer_outlined,
            title: 'Promotions',
            subtitle: 'Gérer les offres spéciales',
            color: AppTheme.warning,
            onTap: () => AppNavigator.push(context, AppNavigator.adminRoute),
          ),
          _buildAdminMenuItem(
            icon: Icons.people_outline,
            title: 'Clients',
            subtitle: 'Voir les utilisateurs',
            color: Colors.teal,
            onTap: () => AppNavigator.push(context, AppNavigator.adminRoute),
          ),
          _buildAdminMenuItem(
            icon: Icons.analytics_outlined,
            title: 'Statistiques',
            subtitle: 'Analyser les performances',
            color: Colors.indigo,
            onTap: () => AppNavigator.push(context, AppNavigator.adminRoute),
          ),
          const SizedBox(height: 24),
          
          // Accès complet admin
          OutlinedButton.icon(
            onPressed: () => AppNavigator.push(context, AppNavigator.adminRoute),
            icon: const Icon(Icons.dashboard),
            label: const Text('Ouvrir le tableau de bord complet'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          
          // Déconnexion
          OutlinedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: AppTheme.error),
            label: const Text('Se déconnecter', style: TextStyle(color: AppTheme.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // === Helper Widgets ===
  
  Widget _buildMenuSection(BuildContext context, bool isDark, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ),
        Card(
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryViolet),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _getInitials() {
    if (_currentUser != null) {
      final first = _currentUser!.firstName.isNotEmpty ? _currentUser!.firstName[0] : '';
      final last = _currentUser!.lastName.isNotEmpty ? _currentUser!.lastName[0] : '';
      if (first.isNotEmpty || last.isNotEmpty) {
        return '$first$last'.toUpperCase();
      }
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName![0].toUpperCase();
    }
    if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    }
    return 'U';
  }

  /// Formate un numéro de téléphone international
  String _formatPhoneNumber(String value) {
    // Supprimer tout sauf les chiffres et le +
    String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.isEmpty) return '';
    
    // S'assurer que ça commence par +
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    
    // Garder seulement le premier + et les chiffres
    String digits = cleaned.substring(1).replaceAll('+', '');
    
    // Limiter à 15 chiffres (max international)
    if (digits.length > 15) {
      digits = digits.substring(0, 15);
    }
    
    return '+$digits';
  }

  void _showEditProfileDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Debug: Afficher les valeurs actuelles
    debugPrint('=== Ouverture modification profil ===');
    debugPrint('_currentUser: $_currentUser');
    debugPrint('firstName: ${_currentUser?.firstName}');
    debugPrint('lastName: ${_currentUser?.lastName}');
    debugPrint('phone: ${_currentUser?.phone}');
    
    final firstNameController = TextEditingController(text: _currentUser?.firstName ?? '');
    final lastNameController = TextEditingController(text: _currentUser?.lastName ?? '');
    final phoneController = TextEditingController(text: _currentUser?.phone ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isLoading = false;
          
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Titre
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppTheme.primaryViolet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Modifier le profil',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Photo de profil
                  if (user?.photoURL != null) ...[
                    Center(
                      child: SafeNetworkAvatar(
                        imageUrl: user!.photoURL,
                        fallbackText: _currentUser?.fullName ?? user.displayName ?? 'U',
                        radius: 50,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Photo liée à votre compte Google',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Email (non modifiable)
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: user?.email ?? ''),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'L\'email ne peut pas être modifié',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Prénom
                  TextField(
                    controller: firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      hintText: 'Entrez votre prénom',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nom
                  TextField(
                    controller: lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      hintText: 'Entrez votre nom',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Téléphone avec format international
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 16, // + suivi de 15 chiffres max
                    onChanged: (value) {
                      // Formater automatiquement le numéro
                      String formatted = _formatPhoneNumber(value);
                      if (formatted != value) {
                        phoneController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      hintText: '+22507XXXXXXXX',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      counterText: '', // Masquer le compteur de caractères
                      helperText: 'Format international: +indicatif numéro',
                      helperStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Boutons améliorés
                  Row(
                    children: [
                      // Bouton Annuler
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Bouton Enregistrer
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () async {
                              final firstName = firstNameController.text.trim();
                              final lastName = lastNameController.text.trim();
                              final phone = phoneController.text.trim();
                              
                              // Validation du numéro de téléphone
                              if (phone.isNotEmpty) {
                                // Vérifier le format: + suivi de 8 à 15 chiffres
                                final phoneRegex = RegExp(r'^\+\d{8,15}$');
                                if (!phoneRegex.hasMatch(phone)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: const [
                                          Icon(Icons.warning_amber_rounded, color: Colors.white),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text('Numéro invalide. Format: +XXXXXXXXXXXX (8-15 chiffres)'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.orange.shade700,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                              }
                              
                              setModalState(() => isLoading = true);
                              
                              try {
                                debugPrint('=== Sauvegarde profil ===');
                                debugPrint('firstName: $firstName');
                                debugPrint('lastName: $lastName');
                                debugPrint('phone: $phone');
                                
                                // Toujours envoyer les valeurs, même vides
                                await _authService.updateUserProfile(
                                  firstName: firstName,
                                  lastName: lastName,
                                  phone: phone.isNotEmpty ? phone : null,
                                );
                                
                                // Recharger les données utilisateur AVANT de fermer
                                await _loadUserData();
                                
                                // Fermer le modal
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: const [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text('Profil mis à jour avec succès'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Erreur sauvegarde: $e');
                                if (context.mounted) {
                                  setModalState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryViolet,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Enregistrer',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Déconnexion',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Voulez-vous vraiment vous déconnecter de votre compte ?',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Annuler', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Déconnecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        AppNavigator.go(context, AppNavigator.homeRoute);
      }
    }
  }
  
  /// Afficher message "Bientôt disponible"
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('$feature - Bientôt disponible !')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppTheme.primaryViolet,
      ),
    );
  }
  
  /// Afficher les favoris
  void _showFavorites(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Barre de poignée
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Titre
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'Mes Favoris',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Contenu
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: FavoritesService.getFavorites(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final favoriteIds = snapshot.data ?? [];
                    
                    if (favoriteIds.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun favori pour le moment',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ajoutez des produits à vos favoris\nen appuyant sur le ❤️',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Récupérer les vrais produits depuis le provider
                    final favoriteProducts = productProvider.products
                        .where((p) => favoriteIds.contains(p.id))
                        .toList();
                    
                    if (favoriteProducts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sync_problem,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chargement des favoris...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                productProvider.loadProducts().then((_) {
                                  _showFavorites(context);
                                });
                              },
                              child: const Text('Actualiser'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: favoriteProducts.length,
                      itemBuilder: (context, index) {
                        final product = favoriteProducts[index];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              AppNavigator.toProductDetail(context, product.id);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Image du produit
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: product.imageUrls.isNotEmpty
                                          ? ProductImage(
                                              imageUrl: product.imageUrls.first,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: AppTheme.primaryViolet.withOpacity(0.1),
                                              child: const Icon(
                                                Icons.smartphone,
                                                color: AppTheme.primaryViolet,
                                                size: 32,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Infos produit
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.brand,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${product.price.toStringAsFixed(0)} FCFA',
                                          style: const TextStyle(
                                            color: AppTheme.primaryViolet,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Bouton supprimer des favoris
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red, size: 28),
                                    onPressed: () async {
                                      await FavoritesService.removeFavorite(product.id);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${product.name} retiré des favoris'),
                                          action: SnackBarAction(
                                            label: 'Annuler',
                                            onPressed: () async {
                                              await FavoritesService.addFavorite(product.id);
                                            },
                                          ),
                                        ),
                                      );
                                      _showFavorites(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Ouvrir WhatsApp pour le support
  void _openWhatsAppSupport() async {
    final url = Uri.parse('https://wa.me/2250788711896?text=${Uri.encodeComponent("Bonjour, j'ai besoin d'aide avec l'application Pharrell Phone.")}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
        );
      }
    }
  }
}
