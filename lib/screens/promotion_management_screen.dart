import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/promotion.dart';
import '../services/promotion_service.dart';
import '../services/audit_service.dart';
import 'product_promotion_link_screen.dart';

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  State<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen> {
  final PromotionService _promotionService = PromotionService();
  final AuditService _auditService = AuditService();
  final TextEditingController _searchController = TextEditingController();

  List<Promotion> _promotions = [];
  List<Promotion> _filteredPromotions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      _promotionService.getAll().listen((promotions) {
        if (mounted) {
          setState(() {
            _promotions = promotions;
            _filteredPromotions = promotions;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
      }
    }
  }

  void _filterPromotions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPromotions = _promotions.where((promotion) {
        final matchesSearch =
            promotion.name.toLowerCase().contains(query) ||
            promotion.description.toLowerCase().contains(query);

        final matchesFilter =
            _selectedFilter == 'all' ||
            (_selectedFilter == 'active' && promotion.isActive) ||
            (_selectedFilter == 'inactive' && !promotion.isActive) ||
            (_selectedFilter == 'percentage' &&
                promotion.type == 'percentage') ||
            (_selectedFilter == 'fixed' && promotion.type == 'fixed');

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Promotions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPromotions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPromotionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPromotionDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Rechercher une promotion',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _filterPromotions(),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tous'),
                _buildFilterChip('active', 'Actives'),
                _buildFilterChip('inactive', 'Inactives'),
                _buildFilterChip('percentage', 'Pourcentage'),
                _buildFilterChip('fixed', 'Montant fixe'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
            _filterPromotions();
          });
        },
        selectedColor: AppTheme.success,
        backgroundColor: Colors.grey[200],
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.success : Colors.grey[300]!,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final activeCount = _promotions.where((p) => p.isActive).length;
    final inactiveCount = _promotions.length - activeCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      activeCount.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text('Actives'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      inactiveCount.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Text('Inactives'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _promotions.length.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text('Total'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsList() {
    if (_filteredPromotions.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucune promotion trouvée',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredPromotions.length,
      itemBuilder: (context, index) {
        final promotion = _filteredPromotions[index];
        return _buildPromotionCard(promotion);
      },
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: promotion.isActive ? Colors.green : Colors.red,
          child: Icon(_getPromotionIcon(promotion.type), color: Colors.white),
        ),
        title: Text(
          promotion.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(promotion.description),
            const SizedBox(height: 4),
            Text(_getPromotionDescription(promotion)),
            const SizedBox(height: 4),
            Text(
              'Valide du ${DateFormat('dd/MM/yyyy').format(promotion.startDate)} '
              'au ${DateFormat('dd/MM/yyyy').format(promotion.endDate)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  '${promotion.productIds.length} produit(s) lié(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(action, promotion),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'link_products',
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Lier produits'),
                ],
              ),
            ),
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
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    promotion.isActive
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  const SizedBox(width: 8),
                  Text(promotion.isActive ? 'Désactiver' : 'Activer'),
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
        onTap: () => _showPromotionDialog(promotion: promotion),
      ),
    );
  }

  IconData _getPromotionIcon(String type) {
    switch (type) {
      case 'percentage':
        return Icons.percent;
      case 'fixed':
        return Icons.attach_money;
      default:
        return Icons.local_offer;
    }
  }

  String _getPromotionDescription(Promotion promotion) {
    if (promotion.type == 'percentage') {
      return 'Réduction de ${promotion.value}%';
    } else {
      return 'Réduction de ${promotion.value}€';
    }
  }

  void _handleAction(String action, Promotion promotion) {
    switch (action) {
      case 'link_products':
        _openProductLinkScreen(promotion);
        break;
      case 'edit':
        _showPromotionDialog(promotion: promotion);
        break;
      case 'toggle':
        _togglePromotionStatus(promotion);
        break;
      case 'delete':
        _showDeleteConfirmation(promotion);
        break;
    }
  }

  void _openProductLinkScreen(Promotion promotion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPromotionLinkScreen(promotion: promotion),
      ),
    ).then((result) {
      if (result == true) {
        _loadPromotions();
      }
    });
  }

  Future<void> _togglePromotionStatus(Promotion promotion) async {
    try {
      promotion.isActive = !promotion.isActive;
      await _promotionService.update(promotion);
      await _auditService.log(
        userId: 'current_user_id',
        userName: 'Admin',
        action: promotion.isActive
            ? 'activate_promotion'
            : 'deactivate_promotion',
        entityType: 'promotion',
        entityId: promotion.id,
        oldValues: {},
        newValues: promotion.toMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              promotion.isActive ? 'Promotion activée' : 'Promotion désactivée',
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

  void _showDeleteConfirmation(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la promotion "${promotion.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePromotion(promotion);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePromotion(Promotion promotion) async {
    try {
      await _promotionService.delete(promotion.id);
      await _auditService.log(
        userId: 'current_user_id',
        userName: 'Admin',
        action: 'delete_promotion',
        entityType: 'promotion',
        entityId: promotion.id,
        oldValues: promotion.toMap(),
        newValues: {},
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Promotion supprimée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showPromotionDialog({Promotion? promotion}) {
    final isEdit = promotion != null;
    final nameController = TextEditingController(text: promotion?.name ?? '');
    final descriptionController = TextEditingController(
      text: promotion?.description ?? '',
    );
    final valueController = TextEditingController(
      text: promotion?.value.toString() ?? '',
    );
    String selectedType = promotion?.type ?? 'percentage';
    DateTime startDate = promotion?.startDate ?? DateTime.now();
    DateTime endDate =
        promotion?.endDate ?? DateTime.now().add(const Duration(days: 30));
    bool isActive = promotion?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête avec gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryViolet,
                          AppTheme.primaryViolet.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit : Icons.local_offer,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit ? 'Modifier la promotion' : 'Nouvelle promotion',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenu scrollable
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nom
                          _buildModernTextField(
                            controller: nameController,
                            label: 'Nom de la promotion',
                            icon: Icons.local_offer_outlined,
                            hint: 'Ex: Soldes d\'hiver',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          
                          // Description
                          _buildModernTextField(
                            controller: descriptionController,
                            label: 'Description',
                            icon: Icons.description_outlined,
                            hint: 'Décrivez votre promotion...',
                            maxLines: 2,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          
                          // Type et Valeur
                          Text(
                            'Réduction',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Type selector
                              Expanded(
                                child: _buildTypeSelector(
                                  selectedType: selectedType,
                                  onChanged: (type) => setDialogState(() => selectedType = type),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Valeur
                              SizedBox(
                                width: 120,
                                child: _buildModernTextField(
                                  controller: valueController,
                                  label: selectedType == 'percentage' ? '%' : 'FCFA',
                                  icon: selectedType == 'percentage' ? Icons.percent : Icons.payments_outlined,
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Dates
                          Text(
                            'Période de validité',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateCard(
                                  label: 'Début',
                                  date: startDate,
                                  icon: Icons.play_arrow_rounded,
                                  color: AppTheme.success,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: startDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setDialogState(() => startDate = date);
                                    }
                                  },
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateCard(
                                  label: 'Fin',
                                  date: endDate,
                                  icon: Icons.stop_rounded,
                                  color: AppTheme.error,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: endDate,
                                      firstDate: startDate,
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setDialogState(() => endDate = date);
                                    }
                                  },
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Status toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive 
                                ? AppTheme.success.withValues(alpha: 0.1)
                                : (isDark ? Colors.grey[800] : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? AppTheme.success : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.pause_circle_outline,
                                  color: isActive ? AppTheme.success : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isActive ? 'Promotion active' : 'Promotion inactive',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isActive ? AppTheme.success : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        isActive ? 'Visible par les clients' : 'Non visible',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  onChanged: (value) => setDialogState(() => isActive = value),
                                  activeColor: AppTheme.success,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Boutons d'action
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (nameController.text.isEmpty ||
                                  descriptionController.text.isEmpty ||
                                  valueController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.warning_amber, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Veuillez remplir tous les champs'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.warning,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                return;
                              }

                              final value = double.tryParse(valueController.text);
                              if (value == null || value <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Veuillez entrer une valeur valide'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                return;
                              }

                              try {
                                // Générer un ID si c'est une nouvelle promotion
                                final promotionId = promotion?.id ?? 
                                    'promo_${DateTime.now().millisecondsSinceEpoch}';
                                
                                final newPromotion = Promotion(
                                  id: promotionId,
                                  name: nameController.text,
                                  description: descriptionController.text,
                                  productIds: promotion?.productIds ?? [],
                                  type: selectedType,
                                  value: value,
                                  startDate: startDate,
                                  endDate: endDate,
                                  isActive: isActive,
                                );

                                if (isEdit) {
                                  await _promotionService.update(newPromotion);
                                  await _auditService.log(
                                    userId: 'current_user_id',
                                    userName: 'Admin',
                                    action: 'update_promotion',
                                    entityType: 'promotion',
                                    entityId: newPromotion.id,
                                    oldValues: promotion.toMap(),
                                    newValues: newPromotion.toMap(),
                                  );
                                } else {
                                  await _promotionService.add(newPromotion);
                                  await _auditService.log(
                                    userId: 'current_user_id',
                                    userName: 'Admin',
                                    action: 'create_promotion',
                                    entityType: 'promotion',
                                    entityId: newPromotion.id,
                                    oldValues: {},
                                    newValues: newPromotion.toMap(),
                                  );
                                }

                                if (mounted && context.mounted) {
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text(isEdit ? 'Promotion modifiée ✓' : 'Promotion créée ✓'),
                                        ],
                                      ),
                                      backgroundColor: AppTheme.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(isEdit ? Icons.save : Icons.add),
                            label: Text(isEdit ? 'Enregistrer' : 'Créer la promotion'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryViolet,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// TextField moderne avec style amélioré
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryViolet),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
  
  /// Sélecteur de type moderne
  Widget _buildTypeSelector({
    required String selectedType,
    required Function(String) onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged('percentage'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == 'percentage' 
                    ? AppTheme.primaryViolet 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '% %',
                    style: TextStyle(
                      color: selectedType == 'percentage' ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged('fixed'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == 'fixed' 
                    ? AppTheme.primaryViolet 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'XOF',
                    style: TextStyle(
                      color: selectedType == 'fixed' ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Card de date moderne
  Widget _buildDateCard({
    required String label,
    required DateTime date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd MMM yyyy', 'fr_FR').format(date),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
