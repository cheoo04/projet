import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/ui_components.dart';
import '../models/category.dart';
import '../services/category_service.dart';

/// Écran moderne de gestion des catégories
/// Permet de créer, modifier et supprimer des catégories de produits
class ModernCategoryManagementScreen extends StatefulWidget {
  const ModernCategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<ModernCategoryManagementScreen> createState() =>
      _ModernCategoryManagementScreenState();
}

class _ModernCategoryManagementScreenState
    extends State<ModernCategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? EmptyState(
                  icon: Icons.category,
                  title: 'Aucune catégorie',
                  message: 'Créez votre première catégorie',
                  actionLabel: 'Ajouter une catégorie',
                  onAction: _addCategory,
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: _buildCategoryList(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: AppTheme.primaryViolet,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95, // Plus de hauteur pour éviter l'overflow
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(_categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    final theme = Theme.of(context);
    final icon = _getCategoryIcon(category.name);
    final color = _getCategoryColor(category.name);

    return Card(
      child: InkWell(
        onTap: () => _editCategory(category),
        onLongPress: () => _showCategoryOptions(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Nom
              Text(
                category.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 2),
              
              // Nombre de produits
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${category.productCount} produit${category.productCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Actions compactes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSmallActionButton(
                    icon: Icons.edit_outlined,
                    color: AppTheme.primaryViolet,
                    onTap: () => _editCategory(category),
                  ),
                  const SizedBox(width: 8),
                  _buildSmallActionButton(
                    icon: Icons.delete_outline,
                    color: AppTheme.error,
                    onTap: () => _deleteCategory(category),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSmallActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
  
  void _showCategoryOptions(Category category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              category.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryViolet),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _editCategory(category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _deleteCategory(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('smartphone') || name.contains('phone')) {
      return Icons.phone_android;
    } else if (name.contains('tablette') || name.contains('tablet')) {
      return Icons.tablet_android;
    } else if (name.contains('accessoire')) {
      return Icons.headphones;
    } else if (name.contains('audio') || name.contains('ecouteur')) {
      return Icons.headset;
    } else if (name.contains('montre') || name.contains('watch')) {
      return Icons.watch;
    } else if (name.contains('chargeur')) {
      return Icons.power;
    }
    return Icons.category;
  }

  Color _getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('smartphone')) {
      return AppTheme.primaryViolet;
    } else if (name.contains('tablette')) {
      return Colors.blue;
    } else if (name.contains('accessoire')) {
      return Colors.orange;
    } else if (name.contains('audio')) {
      return Colors.green;
    } else if (name.contains('montre')) {
      return Colors.red;
    }
    return AppTheme.primaryViolet;
  }

  void _addCategory() {
    _showCategoryDialog();
  }

  void _editCategory(Category category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Category? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController =
        TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nom
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnelle)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              Navigator.pop(context);

              try {
                if (isEdit) {
                  await _categoryService.updateCategory(
                    category!.id,
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                } else {
                  await _categoryService.createCategory(
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                }

                await _loadCategories();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? 'Catégorie modifiée avec succès'
                            : 'Catégorie créée avec succès',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Enregistrer' : 'Créer'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(Category category) {
    if (category.productCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Impossible de supprimer'),
          content: Text(
            'La catégorie "${category.name}" contient ${category.productCount} produit(s).\n\n'
            'Veuillez d\'abord déplacer ou supprimer ces produits.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la catégorie "${category.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _categoryService.deleteCategory(category.id);
                await _loadCategories();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catégorie supprimée avec succès'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
