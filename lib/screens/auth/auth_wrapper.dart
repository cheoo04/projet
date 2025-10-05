import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/auth_service.dart';
import '/models/app_user.dart';
import '../auth/login_screen.dart';
import '../visitor/visitor_home_screen.dart';
import '../client/client_home_screen.dart';
import '../admin_navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // En attente de la vérification de l'état d'authentification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Utilisateur non connecté
        if (!snapshot.hasData || snapshot.data == null) {
          return const VisitorHomeScreen();
        }

        // Utilisateur connecté - rediriger selon le rôle
        return FutureBuilder<UserRole>(
          future: AuthService().getCurrentUserRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data ?? UserRole.client;

            switch (role) {
              case UserRole.admin:
              case UserRole.manager:
                return const AdminNavigationScreen();
              case UserRole.client:
                return const ClientHomeScreen();
              default:
                return const VisitorHomeScreen();
            }
          },
        );
      },
    );
  }
}

/// Widget pour protéger les routes admin
class AdminRoute extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminRoute({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return fallback ?? const UnauthorizedScreen();
      },
    );
  }
}

/// Widget pour protéger les routes client
class ClientRoute extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const ClientRoute({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isClient(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true || AuthService().isAuthenticated) {
          return child;
        }

        return fallback ?? const LoginScreen();
      },
    );
  }
}

/// Écran d'accès non autorisé
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès refusé'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Accès non autorisé',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous n\'avez pas les permissions nécessaires pour accéder à cette page.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retour à l\'accueil'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
