import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../web_config/navigation_helper.dart';

/// Écran d'authentification moderne
/// Permet la connexion et l'inscription avec différentes méthodes
class AuthScreen extends StatefulWidget {
  final String? redirectRoute;
  final String? message;
  
  const AuthScreen({
    Key? key,
    this.redirectRoute,
    this.message,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  
  // Controllers pour connexion
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  
  // Controllers pour inscription
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header avec logo
            _buildHeader(context, isDark),
            
            // Message si présent (ex: "Connectez-vous pour commander")
            if (widget.message != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message!,
                        style: TextStyle(color: AppTheme.info, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Tabs Connexion / Inscription
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryViolet,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white70 : Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Connexion'),
                  Tab(text: 'Inscription'),
                ],
              ),
            ),
            
            // Contenu des tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginForm(context, isDark),
                  _buildRegisterForm(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Bouton retour
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(height: 16),
          
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primaryViolet, AppTheme.accentVioletLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryViolet.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Pharrell Phone',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryViolet,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Qualité supérieure, satisfaction garantie',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          // Email
          TextField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Mot de passe
          TextField(
            controller: _loginPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Mot de passe oublié
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          const SizedBox(height: 16),
          
          // Bouton connexion
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
          
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ou continuer avec',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Boutons sociaux
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20),
                  ),
                  label: const Text('Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handlePhoneSignIn,
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Téléphone'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          // Nom complet
          TextField(
            controller: _registerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Email
          TextField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Téléphone
          TextField(
            controller: _registerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: const Icon(Icons.phone_outlined),
              hintText: '+225 07 88 71 18 96',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Mot de passe
          TextField(
            controller: _registerPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Confirmer mot de passe
          TextField(
            controller: _registerConfirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Bouton inscription
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Créer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          
          // Conditions
          Text(
            'En créant un compte, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // === Handlers ===
  
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _loginEmailController.text.trim();
      final password = _loginPasswordController.text;

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Veuillez remplir tous les champs');
      }

      await _authService.signInWithEmailAndPassword(email, password);
      
      if (mounted) {
        _navigateAfterAuth();
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _registerNameController.text.trim();
      final email = _registerEmailController.text.trim();
      final phone = _registerPhoneController.text.trim();
      final password = _registerPasswordController.text;
      final confirmPassword = _registerConfirmPasswordController.text;

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('Veuillez remplir tous les champs obligatoires');
      }

      if (password != confirmPassword) {
        throw Exception('Les mots de passe ne correspondent pas');
      }

      if (password.length < 6) {
        throw Exception('Le mot de passe doit contenir au moins 6 caractères');
      }

      // Séparer le nom en prénom et nom
      final nameParts = name.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await _authService.createUserWithEmailAndPassword(
        email,
        password,
        firstName,
        lastName,
      );
      
      if (mounted) {
        _navigateAfterAuth();
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle();
      
      if (user != null && mounted) {
        _navigateAfterAuth();
      }
    } catch (e) {
      // Ignorer les erreurs d'annulation par l'utilisateur
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('canceled') || 
          errorStr.contains('cancelled') || 
          errorStr.contains('user_canceled') ||
          errorStr.contains('sign_in_canceled') ||
          errorStr.contains('popup_closed') ||
          errorStr.contains('popup-closed-by-user') ||
          errorStr.contains('user-cancelled') ||
          errorStr.contains('closed by the user')) {
        // L'utilisateur a annulé, pas d'erreur à afficher
        debugPrint('ℹ️ Google Sign-In annulé par l\'utilisateur');
      } else if (errorStr.contains('null') && errorStr.contains('string')) {
        // Erreur de type null - probablement déjà connecté
        // Vérifier si l'utilisateur est connecté
        if (_authService.isAuthenticated) {
          if (mounted) {
            _navigateAfterAuth();
          }
        } else {
          setState(() {
            _errorMessage = 'Erreur de connexion Google. Veuillez réessayer.';
          });
        }
      } else {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePhoneSignIn() async {
    final phoneController = TextEditingController();
    
    // Dialogue amélioré pour entrer le numéro de téléphone
    final phoneNumber = await showModalBottomSheet<String>(
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
            children: [
              // Barre de poignée
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Icône
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: AppTheme.primaryViolet,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              
              // Titre
              const Text(
                'Connexion par téléphone',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                'Entrez votre numéro pour recevoir un code de vérification par SMS.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Champ téléphone
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18, letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: '+225 07 00 00 00 00',
                  prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryViolet),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bouton Envoyer
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (phoneController.text.isNotEmpty) {
                      Navigator.pop(context, phoneController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Envoyer le code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Bouton Annuler
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    
    // Formater le numéro si nécessaire
    String formattedPhone = phoneNumber;
    if (!phoneNumber.startsWith('+')) {
      formattedPhone = '+225$phoneNumber';
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId, resendToken) async {
          if (mounted) {
            setState(() => _isLoading = false);
            
            // Dialogue pour entrer le code OTP
            final smsCode = await _showOtpDialog(formattedPhone);
            
            if (smsCode != null && smsCode.length == 6) {
              setState(() => _isLoading = true);
              
              try {
                await _authService.signInWithSmsCode(
                  verificationId: verificationId,
                  smsCode: smsCode,
                );
                
                if (mounted) {
                  _navigateAfterAuth();
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _errorMessage = 'Code invalide. Veuillez réessayer.';
                    _isLoading = false;
                  });
                }
              }
            }
          }
        },
        onVerificationCompleted: (credential) async {
          // Auto-vérification sur Android
          await _authService.signInWithPhoneCredential(credential: credential);
          if (mounted) {
            _navigateAfterAuth();
          }
        },
        onVerificationFailed: (errorMessage) {
          if (mounted) {
            setState(() {
              _errorMessage = errorMessage;
              _isLoading = false;
            });
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          // Le timeout est géré, pas d'action nécessaire
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }
  
  Future<String?> _showOtpDialog(String phoneNumber) async {
    final otpController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sms, color: AppTheme.primaryViolet, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Vérification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Un code a été envoyé au\n$phoneNumber',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '------',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (otpController.text.length == 6) {
                Navigator.pop(context, otpController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _loginEmailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre email')),
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(e))),
      );
    }
  }

  void _navigateAfterAuth() async {
    debugPrint('🔄 _navigateAfterAuth() appelé');
    try {
      // Vérifier le rôle de l'utilisateur
      final role = await _authService.getCurrentUserRole();
      debugPrint('👤 Rôle détecté: $role, canAccessAdmin: ${role.canAccessAdmin}');
      
      if (mounted) {
        if (role.canAccessAdmin) {
          // Admin ou Manager → Espace admin
          debugPrint('🔑 Redirection vers /admin...');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bienvenue Admin !'),
              backgroundColor: Colors.green,
            ),
          );
          // Attendre un peu pour que le SnackBar s'affiche
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            debugPrint('➡️ AppNavigator.go(context, /admin)');
            AppNavigator.go(context, '/admin');
          }
        } else if (widget.redirectRoute != null) {
          // Redirection spécifique demandée
          debugPrint('➡️ Redirection vers ${widget.redirectRoute}');
          AppNavigator.go(context, widget.redirectRoute!);
        } else {
          // Client normal → Home
          debugPrint('➡️ Redirection vers /');
          AppNavigator.go(context, '/');
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur dans _navigateAfterAuth: $e');
      // En cas d'erreur, aller vers home par défaut
      if (mounted) {
        AppNavigator.go(context, '/home');
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    debugPrint('🔍 Auth error: $error (type: ${error.runtimeType})');
    
    // Ignorer les erreurs d'annulation
    if (errorStr.contains('canceled') || 
        errorStr.contains('cancelled') || 
        errorStr.contains('user_canceled')) {
      return '';
    }
    
    // Détecter les erreurs d'identifiants invalides (Firebase web utilise des messages différents)
    if (errorStr.contains('invalid-credential') || 
        errorStr.contains('wrong-password') ||
        errorStr.contains('user-not-found') ||
        errorStr.contains('invalid-login-credentials') ||
        errorStr.contains('auth/invalid-credential')) {
      return 'Email ou mot de passe incorrect';
    }
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun compte trouvé avec cet email';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé';
        case 'weak-password':
          return 'Le mot de passe est trop faible';
        case 'invalid-email':
          return 'Email invalide';
        case 'invalid-credential':
          return 'Email ou mot de passe incorrect';
        case 'network-request-failed':
          return 'Erreur de connexion. Vérifiez votre connexion internet.';
        default:
          return error.message ?? 'Erreur d\'authentification';
      }
    }
    
    // Erreurs réseau
    if (errorStr.contains('network') || 
        errorStr.contains('timeout') || 
        errorStr.contains('unreachable') ||
        errorStr.contains('connection')) {
      return 'Erreur de connexion. Vérifiez votre connexion internet et réessayez.';
    }
    
    // Nettoyer le message d'erreur
    String message = error.toString()
        .replaceAll('Exception: ', '')
        .replaceAll('FirebaseAuthException', '')
        .replaceAll('GoogleSignInException', '');
    
    // Si le message est trop technique, afficher un message générique
    if (message.contains('Exception') || message.length > 100) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }
    
    return message;
  }
}