import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../services/app_init_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  String _statusMessage = 'Chargement...';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();

    // Animation de fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Animation de scale
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Animation de glow pulsation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 20.0, end: 30.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Démarrer les animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _glowController.repeat(reverse: true);
    });

    // Initialiser l'application
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Sur WEB: Navigation immédiate après animation courte
    // L'initialisation Firebase continue en arrière-plan
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        FlutterNativeSplash.remove();
      } catch (e) {
        debugPrint('⚠️ FlutterNativeSplash.remove() error: $e');
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      // Continuer l'init en arrière-plan (non-bloquant)
      AppInitService.initializeApp().catchError((e) {
        debugPrint('⚠️ Init background: $e');
      });
      return;
    }
    
    // Sur MOBILE: Comportement normal avec attente
    try {
      final timeout = const Duration(seconds: 10);
      
      setState(() => _statusMessage = 'Connexion...');
      
      // Initialiser avec timeout
      final result = await AppInitService.initializeApp()
          .timeout(timeout, onTimeout: () {
        debugPrint('⚠️ Timeout initialisation - Navigation directe');
        return InitResult()..isFirstLaunch = false;
      });
      
      setState(() => _statusMessage = 'Préparation...');
      
      // Retirer le splash natif
      FlutterNativeSplash.remove();
      
      if (mounted) {
        if (result.isFirstLaunch) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          final targetRoute = await _getTargetRouteBasedOnRole();
          Navigator.pushReplacementNamed(context, targetRoute);
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation: $e');
      FlutterNativeSplash.remove();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
  
  /// Détermine la route cible en fonction du rôle de l'utilisateur
  Future<String> _getTargetRouteBasedOnRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Si pas d'utilisateur ou utilisateur anonyme -> home client
      if (user == null || user.isAnonymous) {
        return '/home';
      }
      
      // Vérifier le rôle dans Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final role = userDoc.data()?['role'] as String?;
        
        // Si admin ou manager -> écran admin
        if (role == 'admin' || role == 'manager') {
          print('✅ Utilisateur admin/manager détecté, redirection vers /admin');
          return '/admin';
        }
      }
      
      // Par défaut -> home client
      return '/home';
    } catch (e) {
      print('⚠️ Erreur vérification rôle: $e');
      return '/home';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C3BAE), // Éviter flash blanc
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7C3BAE), // Violet moyen
              Color(0xFF5F2A8C), // Violet foncé
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Logo animé avec glow
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.6),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: _glowAnimation.value + 20,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: _glowAnimation.value + 40,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              fontSize: 70,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF9B6DB8),
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Texte du nom
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Pharrell phone',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Qualité supérieur / Satisfaction garantie',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Loading dots
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: _buildLoadingDots(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _AnimatedDot(delay: index * 200),
        );
      }),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;

  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => __AnimatedDotState();
}

class __AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}
