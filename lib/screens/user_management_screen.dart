import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../services/audit_service.dart';
import '../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final AuthService _authService = AuthService();

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.visitor:
        return 'Visiteur';
      case UserRole.client:
        return 'Client';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.manager:
        return 'Manager';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showUserDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun utilisateur trouvé',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              userData['id'] = userDoc.id;
              final user = AppUser.fromMap(userData);

              return _buildUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Row(
              children: [
                _buildRoleChip(user.role),
                const SizedBox(width: 8),
                if (!user.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Inactif',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: user.isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(user.isActive ? Icons.block : Icons.check_circle),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getRoleDisplayName(role),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.visitor:
        return Colors.grey;
      case UserRole.client:
        return Colors.green;
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.blue;
    }
  }

  void _handleUserAction(String action, AppUser user) {
    switch (action) {
      case 'edit':
        _showUserDialog(user: user);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(user);
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showUserDialog({AppUser? user}) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    UserRole selectedRole = user?.role ?? UserRole.visitor;
    bool isActive = user?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    border: OutlineInputBorder(),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(_getRoleDisplayName(role)),
                    );
                  }).toList(),
                  onChanged: (role) {
                    if (role != null) {
                      setState(() => selectedRole = role);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Compte actif'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() => isActive = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveUser(
                  user: user,
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  role: selectedRole,
                  isActive: isActive,
                );
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUser({
    AppUser? user,
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required bool isActive,
  }) async {
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (user == null) {
        // Création
        userData['createdAt'] = Timestamp.fromDate(now);
        userData['lastLoginAt'] = Timestamp.fromDate(now);
        userData['permissions'] = <String, dynamic>{};

        await _firestore.collection('users').add(userData);

        final currentUser = await _authService.getCurrentUserData();
        await _auditService.log(
          userId: currentUser?.id ?? 'unknown_admin',
          userName: currentUser?.fullName ?? 'Admin',
          action: 'create_user',
          entityType: 'user',
          entityId: email,
          newValues: {
            'user':
                'Utilisateur créé: $name ($email) - ${_getRoleDisplayName(role)}',
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Modification
        await _firestore.collection('users').doc(user.id).update(userData);

        final currentUser = await _authService.getCurrentUserData();
        await _auditService.log(
          userId: currentUser?.id ?? 'unknown_admin',
          userName: currentUser?.fullName ?? 'Admin',
          action: 'update_user',
          entityType: 'user',
          entityId: user.id,
          oldValues: {
            'user':
                '${user.name} (${user.email}) - ${_getRoleDisplayName(user.role)}',
          },
          newValues: {'user': '$name ($email) - ${_getRoleDisplayName(role)}'},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur modifié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    try {
      final newStatus = !user.isActive;
      await _firestore.collection('users').doc(user.id).update({
        'isActive': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final currentUser = await _authService.getCurrentUserData();
      await _auditService.log(
        userId: currentUser?.id ?? 'unknown_admin',
        userName: currentUser?.fullName ?? 'Admin',
        action: 'toggle_user_status',
        entityType: 'user',
        entityId: user.id,
        oldValues: {'status': user.isActive ? 'Actif' : 'Inactif'},
        newValues: {'status': newStatus ? 'Actif' : 'Inactif'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Utilisateur ${newStatus ? 'activé' : 'désactivé'} avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteConfirmation(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'utilisateur "${user.name}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).delete();

      final currentUser = await _authService.getCurrentUserData();
      await _auditService.log(
        userId: currentUser?.id ?? 'unknown_admin',
        userName: currentUser?.fullName ?? 'Admin',
        action: 'delete_user',
        entityType: 'user',
        entityId: user.id,
        oldValues: {
          'user':
              '${user.name} (${user.email}) - ${_getRoleDisplayName(user.role)}',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
