import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier.dart';
import '../services/audit_service.dart';
import '../services/auth_service.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des fournisseurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSupplierDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('suppliers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final suppliers = snapshot.data?.docs ?? [];

          if (suppliers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun fournisseur trouvé',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplierDoc = suppliers[index];
              final supplierData = supplierDoc.data() as Map<String, dynamic>;
              supplierData['id'] = supplierDoc.id;
              final supplier = Supplier.fromMap(supplierData);

              return _buildSupplierCard(supplier);
            },
          );
        },
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: supplier.isActive ? Colors.green : Colors.grey,
          child: Text(
            supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(supplier.email),
            Text(supplier.phone),
            Row(
              children: [
                if (!supplier.isActive)
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
          onSelected: (value) => _handleSupplierAction(value, supplier),
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
              value: supplier.isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(supplier.isActive ? Icons.block : Icons.check_circle),
                  const SizedBox(width: 8),
                  Text(supplier.isActive ? 'Désactiver' : 'Activer'),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Email', supplier.email),
                _buildInfoRow('Téléphone', supplier.phone),
                _buildInfoRow('Adresse', supplier.address),
                _buildInfoRow('Contact', supplier.contact),
                if (supplier.website.isNotEmpty)
                  _buildInfoRow('Site web', supplier.website),
                _buildInfoRow('Note', supplier.rating.toString()),
                _buildInfoRow(
                  'Produits',
                  '${supplier.productIds.length} associés',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _handleSupplierAction(String action, Supplier supplier) {
    switch (action) {
      case 'edit':
        _showSupplierDialog(supplier: supplier);
        break;
      case 'activate':
      case 'deactivate':
        _toggleSupplierStatus(supplier);
        break;
      case 'delete':
        _showDeleteConfirmation(supplier);
        break;
    }
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final isEditing = supplier != null;
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final addressController = TextEditingController(
      text: supplier?.address ?? '',
    );
    final contactController = TextEditingController(
      text: supplier?.contact ?? '',
    );
    final websiteController = TextEditingController(
      text: supplier?.website ?? '',
    );
    bool isActive = supplier?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing ? 'Modifier le fournisseur' : 'Nouveau fournisseur',
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: contactController,
                          decoration: const InputDecoration(
                            labelText: 'Contact principal',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Site web',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Fournisseur actif'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveSupplier(
                  supplier: supplier,
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                  contact: contactController.text,
                  website: websiteController.text,
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

  Future<void> _saveSupplier({
    Supplier? supplier,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String contact,
    required String website,
    required bool isActive,
  }) async {
    if (name.isEmpty || email.isEmpty || phone.isEmpty || address.isEmpty) {
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
      final supplierData = {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'contact': contact,
        'website': website,
        'isActive': isActive,
        'rating': supplier?.rating ?? 5.0,
        'productIds': supplier?.productIds ?? [],
        'paymentTerms': supplier?.paymentTerms ?? {},
        'updatedAt': Timestamp.fromDate(now),
      };

      if (supplier == null) {
        // Création
        supplierData['createdAt'] = Timestamp.fromDate(now);
        await _firestore.collection('suppliers').add(supplierData);

        final currentUser = await _authService.getCurrentUserData();
        await _auditService.log(
          userId: currentUser?.id ?? 'unknown_admin',
          userName: currentUser?.fullName ?? 'Admin',
          action: 'create_supplier',
          entityType: 'supplier',
          entityId: email,
          newValues: {'supplier': 'Fournisseur créé: $name'},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fournisseur créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Modification
        await _firestore
            .collection('suppliers')
            .doc(supplier.id)
            .update(supplierData);

        final currentUser = await _authService.getCurrentUserData();
        await _auditService.log(
          userId: currentUser?.id ?? 'unknown_admin',
          userName: currentUser?.fullName ?? 'Admin',
          action: 'update_supplier',
          entityType: 'supplier',
          entityId: supplier.id,
          oldValues: {'supplier': supplier.name},
          newValues: {'supplier': name},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fournisseur modifié avec succès'),
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

  Future<void> _toggleSupplierStatus(Supplier supplier) async {
    try {
      final newStatus = !supplier.isActive;
      await _firestore.collection('suppliers').doc(supplier.id).update({
        'isActive': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final currentUser = await _authService.getCurrentUserData();
      await _auditService.log(
        userId: currentUser?.id ?? 'unknown_admin',
        userName: currentUser?.fullName ?? 'Admin',
        action: 'toggle_supplier_status',
        entityType: 'supplier',
        entityId: supplier.id,
        oldValues: {'status': supplier.isActive ? 'Actif' : 'Inactif'},
        newValues: {'status': newStatus ? 'Actif' : 'Inactif'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fournisseur ${newStatus ? 'activé' : 'désactivé'} avec succès',
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

  void _showDeleteConfirmation(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le fournisseur "${supplier.name}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSupplier(supplier);
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

  Future<void> _deleteSupplier(Supplier supplier) async {
    try {
      await _firestore.collection('suppliers').doc(supplier.id).delete();

      final currentUser = await _authService.getCurrentUserData();
      await _auditService.log(
        userId: currentUser?.id ?? 'unknown_admin',
        userName: currentUser?.fullName ?? 'Admin',
        action: 'delete_supplier',
        entityType: 'supplier',
        entityId: supplier.id,
        oldValues: {'supplier': supplier.name},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fournisseur supprimé avec succès'),
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
