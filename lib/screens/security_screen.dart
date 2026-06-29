import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';

/// Écran de sécurité - Mot de passe et connexion
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Déterminer les méthodes de connexion
    final providers = user?.providerData.map((p) => p.providerId).toList() ?? [];
    final hasPassword = providers.contains('password');
    final hasGoogle = providers.contains('google.com');
    final hasPhone = providers.contains('phone');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité'),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sécurité du compte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez vos options de connexion',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Section Méthodes de connexion
          Text(
            'Méthodes de connexion',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Email/Password
          _buildProviderCard(
            context,
            icon: Icons.email_outlined,
            title: 'Email et mot de passe',
            subtitle: hasPassword 
                ? user?.email ?? 'Activé'
                : hasGoogle 
                    ? 'Ajouter un mot de passe pour ${user?.email ?? "votre compte"}'
                    : 'Non configuré',
            isActive: hasPassword,
            onTap: hasPassword 
                ? () => _showChangePasswordDialog(context)
                : () => _showAddPasswordDialog(context),
            actionLabel: hasPassword ? 'Modifier' : 'Ajouter',
          ),
          
          // Google
          _buildProviderCard(
            context,
            icon: Icons.g_mobiledata,
            title: 'Google',
            subtitle: hasGoogle 
                ? 'Connecté avec ${user?.email ?? "Google"}'
                : 'Non connecté',
            isActive: hasGoogle,
            onTap: hasGoogle ? null : () => _linkGoogle(),
            actionLabel: hasGoogle ? 'Actif' : 'Lier',
            iconColor: Colors.red,
          ),
          
          // Phone
          _buildProviderCard(
            context,
            icon: Icons.phone_android,
            title: 'Téléphone',
            subtitle: hasPhone 
                ? user?.phoneNumber ?? 'Activé'
                : 'Non configuré',
            isActive: hasPhone,
            onTap: hasPhone ? null : () => _showAddPhoneDialog(context),
            actionLabel: hasPhone ? 'Actif' : 'Ajouter',
            iconColor: Colors.green,
          ),
          
          const SizedBox(height: 24),
          
          // Section Sécurité avancée (2FA obligatoire pour admin/manager)
          FutureBuilder<bool>(
            future: _authService.isAdmin(),
            builder: (context, snapshot) {
              final isAdminOrManager = snapshot.data ?? false;
              if (!hasPassword || !isAdminOrManager) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sécurité avancée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_read_outlined,
                            color: AppTheme.success),
                      ),
                      title: const Text('Double authentification par email'),
                      subtitle: Text(
                        'Activée automatiquement pour votre rôle. Un code vous '
                        'sera demandé par email à chaque connexion.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check,
                                size: 16, color: AppTheme.success),
                            const SizedBox(width: 4),
                            const Text(
                              'Active',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
          
          // Section Actions
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Reset password
          if (hasPassword)
            _buildActionCard(
              context,
              icon: Icons.lock_reset,
              title: 'Réinitialiser le mot de passe',
              subtitle: 'Recevoir un email de réinitialisation',
              onTap: () => _sendPasswordResetEmail(context),
            ),
          
          // Delete account
          _buildActionCard(
            context,
            icon: Icons.delete_forever,
            title: 'Supprimer le compte',
            subtitle: 'Supprimer définitivement votre compte',
            isDanger: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),
          
          const SizedBox(height: 24),
          
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pour une meilleure sécurité, nous vous recommandons d\'activer au moins deux méthodes de connexion.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProviderCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    VoidCallback? onTap,
    String? actionLabel,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.primaryViolet).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppTheme.primaryViolet),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isActive ? AppTheme.success : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: onTap != null
            ? TextButton(
                onPressed: onTap,
                child: Text(actionLabel ?? ''),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 16, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      actionLabel ?? 'Actif',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? AppTheme.error : AppTheme.primaryViolet;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(color: isDanger ? color : null)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      ),
    );
  }
  
  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text(
                'Changer le mot de passe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (newPasswordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.error_outline, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Les mots de passe ne correspondent pas'),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }
                    
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      final credential = EmailAuthProvider.credential(
                        email: user!.email!,
                        password: currentPasswordController.text,
                      );
                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(newPasswordController.text);
                      
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Mot de passe modifié avec succès'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Erreur: $e')),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAddPasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text(
                'Créer un mot de passe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez un mot de passe pour pouvoir vous connecter avec votre email.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  helperText: 'Minimum 6 caractères',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryViolet),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryViolet,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (newPasswordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Le mot de passe doit contenir au moins 6 caractères'),
                                  ],
                                ),
                                backgroundColor: Colors.orange.shade700,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            return;
                          }
                          
                          if (newPasswordController.text != confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.error_outline, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Les mots de passe ne correspondent pas'),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            return;
                          }
                          
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user?.email == null) throw Exception('Email non disponible');
                            
                            // Créer le credential avec email/password
                            final credential = EmailAuthProvider.credential(
                              email: user!.email!,
                              password: newPasswordController.text,
                            );
                            
                            // Lier le provider email/password au compte
                            await user.linkWithCredential(credential);
                            
                            context.pop();
                            setState(() {}); // Refresh UI
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Mot de passe créé avec succès'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text('Erreur: $e')),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Créer',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
      ),
    );
  }
  
  void _showAddPhoneDialog(BuildContext context) {
    final phoneController = TextEditingController();
    String? verificationId;
    bool codeSent = false;
    bool isLoading = false;
    final codeController = TextEditingController();
    
    // Fonction pour formater le numéro
    String formatPhoneNumber(String value) {
      String digits = value.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isEmpty) return '+';
      
      // Format: +XXX XX XX XX XX XX
      StringBuffer formatted = StringBuffer('+');
      for (int i = 0; i < digits.length && i < 13; i++) {
        if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) {
          formatted.write(' ');
        }
        formatted.write(digits[i]);
      }
      return formatted.toString();
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  codeSent ? 'Entrez le code de vérification' : 'Ajouter un numéro de téléphone',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  codeSent 
                      ? 'Un SMS avec un code à 6 chiffres a été envoyé à ${phoneController.text}'
                      : 'Vous recevrez un SMS avec un code de vérification.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                
                if (!codeSent) ...[
                  // Champ numéro de téléphone avec formatage automatique
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    onChanged: (value) {
                      String formatted = formatPhoneNumber(value);
                      if (formatted != value) {
                        phoneController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: '+225 01 50 17 13 87',
                      prefixIcon: const Icon(Icons.phone_android),
                      counterText: '',
                      helperText: 'Format: +225 XX XX XX XX XX',
                      helperStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ] else ...[
                  // Champ code de vérification
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Code à 6 chiffres',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () {
                            if (codeSent) {
                              setModalState(() => codeSent = false);
                            } else {
                              context.pop();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryViolet),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            codeSent ? 'Retour' : 'Annuler',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryViolet,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () async {
                            if (!codeSent) {
                              // Envoyer le code SMS
                              final phone = phoneController.text.trim();
                              if (phone.isEmpty || phone.length < 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Numéro de téléphone invalide'),
                                      ],
                                    ),
                                    backgroundColor: Colors.orange.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                return;
                              }
                              
                              setModalState(() => isLoading = true);
                              
                              // Formater le numéro
                              String formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                              if (!formattedPhone.startsWith('+')) {
                                formattedPhone = '+$formattedPhone';
                              }
                              
                              await FirebaseAuth.instance.verifyPhoneNumber(
                                phoneNumber: formattedPhone,
                                verificationCompleted: (PhoneAuthCredential credential) async {
                                  // Auto-vérification sur Android
                                  try {
                                    await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
                                    context.pop();
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: const [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Numéro vérifié automatiquement'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  } catch (e) {
                                    debugPrint('Auto-verification error: $e');
                                  }
                                },
                                verificationFailed: (FirebaseAuthException e) {
                                  setModalState(() => isLoading = false);
                                  String message = 'Erreur de vérification';
                                  if (e.code == 'invalid-phone-number') {
                                    message = 'Numéro de téléphone invalide';
                                  } else if (e.code == 'too-many-requests') {
                                    message = 'Trop de tentatives. Réessayez plus tard.';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.white),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(message)),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                },
                                codeSent: (String verId, int? resendToken) {
                                  setModalState(() {
                                    verificationId = verId;
                                    codeSent = true;
                                    isLoading = false;
                                  });
                                },
                                codeAutoRetrievalTimeout: (String verId) {
                                  verificationId = verId;
                                },
                                timeout: const Duration(seconds: 60),
                              );
                            } else {
                              // Vérifier le code
                              final code = codeController.text.trim();
                              if (code.length != 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Entrez le code à 6 chiffres'),
                                      ],
                                    ),
                                    backgroundColor: Colors.orange.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                return;
                              }
                              
                              setModalState(() => isLoading = true);
                              
                              try {
                                final credential = PhoneAuthProvider.credential(
                                  verificationId: verificationId!,
                                  smsCode: code,
                                );
                                
                                await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
                                
                                context.pop();
                                setState(() {});
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Numéro de téléphone ajouté'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                setModalState(() => isLoading = false);
                                String message = 'Code invalide';
                                if (e.code == 'invalid-verification-code') {
                                  message = 'Code de vérification incorrect';
                                } else if (e.code == 'credential-already-in-use') {
                                  message = 'Ce numéro est déjà utilisé par un autre compte';
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(message)),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryViolet,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      codeSent ? Icons.check : Icons.send,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      codeSent ? 'Vérifier' : 'Envoyer',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
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
        ),
      ),
    );
  }
  
  Future<void> _linkGoogle() async {
    try {
      // Vérifier si déjà lié
      final user = FirebaseAuth.instance.currentUser;
      final providers = user?.providerData.map((p) => p.providerId).toList() ?? [];
      
      if (providers.contains('google.com')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Compte Google déjà lié'),
              ],
            ),
            backgroundColor: AppTheme.primaryViolet,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
      
      // Lier le compte Google
      final googleUser = await _authService.signInWithGoogle();
      
      if (googleUser != null) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Compte Google lié avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
  
  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.email_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('Email de réinitialisation envoyé'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
  
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le compte ?'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                context.go('/');
              } catch (e) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Erreur: $e')),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}