import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/audit_service.dart';
import '../services/auth_service.dart';
import '../services/image_management_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  final AuditService _auditService = AuditService();
  final AuthService _authService = AuthService();
  final ImageManagementService _imageService = ImageManagementService();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: _categoryService.getAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!;

          if (categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune catégorie trouvée',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour ajouter une catégorie',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.isActive
                        ? Colors.green
                        : Colors.grey,
                    child: category.imageUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              category.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(_getIconData(category.iconName));
                              },
                            ),
                          )
                        : Icon(_getIconData(category.iconName)),
                  ),
                  title: Text(
                    category.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: category.isActive ? null : Colors.grey,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category.description.isNotEmpty)
                        Text(category.description),
                      Text('${category.productCount} produits'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => _handleAction(action, category),
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
                        value: category.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              category.isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            const SizedBox(width: 8),
                            Text(category.isActive ? 'Désactiver' : 'Activer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showCategoryDialog(category: category),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final icons = {
      'phone': Icons.phone_android,
      'accessory': Icons.headset,
      'screen': Icons.monitor,
      'pc': Icons.computer,
      'tablet': Icons.tablet,
      'headphones': Icons.headphones,
      'charger': Icons.battery_charging_full,
      'case': Icons.phone_android,
      'other': Icons.more_horiz,
    };
    return icons[iconName] ?? Icons.category;
  }

  void _handleAction(String action, Category category) async {
    switch (action) {
      case 'edit':
        _showCategoryDialog(category: category);
        break;
      case 'activate':
      case 'deactivate':
        await _toggleCategoryStatus(category);
        break;
      case 'delete':
        _showDeleteConfirmation(category);
        break;
    }
  }

  Future<void> _toggleCategoryStatus(Category category) async {
    try {
      final updatedCategory = Category(
        id: category.id,
        name: category.name,
        description: category.description,
        imageUrl: category.imageUrl,
        iconName: category.iconName,
        isActive: !category.isActive,
        createdAt: category.createdAt,
        productCount: category.productCount,
      );

      await _categoryService.update(updatedCategory);

      final currentUser = await _authService.getCurrentUserData();
      await _auditService.log(
        userId: currentUser?.id ?? 'unknown',
        userName: currentUser?.firstName ?? 'Admin',
        action: category.isActive ? 'deactivate_category' : 'activate_category',
        entityType: 'category',
        entityId: category.id,
        oldValues: {'isActive': category.isActive},
        newValues: {'isActive': !category.isActive},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Catégorie ${!category.isActive ? 'activée' : 'désactivée'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la catégorie "${category.name}" ?\n\n'
          'Cette action est irréversible et affectera ${category.productCount} produit(s).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await _categoryService.delete(category.id);

      final currentUser = await _authService.getCurrentUserData();
      await _auditService.log(
        userId: currentUser?.id ?? 'unknown',
        userName: currentUser?.firstName ?? 'Admin',
        action: 'delete_category',
        entityType: 'category',
        entityId: category.id,
        oldValues: category.toMap(),
        newValues: {},
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Catégorie supprimée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showCategoryDialog({Category? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    final imageUrlController = TextEditingController(
      text: category?.imageUrl ?? '',
    );
    String selectedIcon = category?.iconName ?? 'category';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la catégorie *',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de l\'image',
                          prefixIcon: Icon(Icons.image),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            // Show loading
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Upload en cours...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                            
                            // Upload image to Firebase Storage
                            final imageBytes = await image.readAsBytes();
                            final imagePath = 'categories/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
                            
                            final uploadResults = await _imageService.uploadImageWithThumbnails(
                              imageBytes,
                              imagePath,
                              metadata: {'type': 'category_image'},
                            );
                            
                            // Update the URL field with the uploaded image URL
                            imageUrlController.text = uploadResults['original'] ?? '';
                            
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image uploadée avec succès'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur upload: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'Icône',
                    prefixIcon: Icon(Icons.auto_awesome),
                  ),
                  items:
                      [
                        'phone',
                        'accessory',
                        'screen',
                        'pc',
                        'tablet',
                        'headphones',
                        'charger',
                        'case',
                        'other',
                      ].map((icon) {
                        return DropdownMenuItem(
                          value: icon,
                          child: Row(
                            children: [
                              Icon(_getIconData(icon)),
                              const SizedBox(width: 8),
                              Text(icon.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedIcon = value!;
                    });
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
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Le nom est requis')),
                    );
                  }
                  return;
                }

                try {
                  final newCategory = Category(
                    id:
                        category?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    description: descriptionController.text.trim(),
                    imageUrl: imageUrlController.text.trim(),
                    iconName: selectedIcon,
                    isActive: category?.isActive ?? true,
                    createdAt: category?.createdAt ?? DateTime.now(),
                    productCount: category?.productCount ?? 0,
                  );

                  if (isEdit) {
                    await _categoryService.update(newCategory);
                    final currentUser = await _authService.getCurrentUserData();
                    await _auditService.log(
                      userId: currentUser?.id ?? 'unknown',
                      userName: currentUser?.firstName ?? 'Admin',
                      action: 'update_category',
                      entityType: 'category',
                      entityId: newCategory.id,
                      oldValues: category.toMap(),
                      newValues: newCategory.toMap(),
                    );
                  } else {
                    await _categoryService.add(newCategory);
                    final currentUser = await _authService.getCurrentUserData();
                    await _auditService.log(
                      userId: currentUser?.id ?? 'unknown',
                      userName: currentUser?.firstName ?? 'Admin',
                      action: 'create_category',
                      entityType: 'category',
                      entityId: newCategory.id,
                      oldValues: {},
                      newValues: newCategory.toMap(),
                    );
                  }

                  if (mounted && context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Catégorie modifiée' : 'Catégorie créée',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              },
              child: Text(isEdit ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
