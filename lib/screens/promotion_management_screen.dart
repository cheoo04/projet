import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/promotion_service.dart';
import '../services/audit_service.dart';
import 'package:intl/intl.dart';

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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
            _filterPromotions();
          });
        },
        selectedColor: Colors.green.withValues(alpha: 0.3),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune promotion trouvée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
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
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(action, promotion),
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
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Modifier la promotion' : 'Nouvelle promotion'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la promotion',
                      prefixIcon: Icon(Icons.title),
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
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type de promotion',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Pourcentage (%)'),
                      ),
                      DropdownMenuItem(
                        value: 'fixed',
                        child: Text('Montant fixe (€)'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      labelText: selectedType == 'percentage'
                          ? 'Pourcentage de réduction'
                          : 'Montant de réduction (€)',
                      prefixIcon: Icon(
                        selectedType == 'percentage'
                            ? Icons.percent
                            : Icons.euro,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() {
                                startDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de début',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(startDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() {
                                endDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de fin',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(endDate),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Promotion active'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    valueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs'),
                    ),
                  );
                  return;
                }

                final value = double.tryParse(valueController.text);
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer une valeur valide'),
                    ),
                  );
                  return;
                }

                try {
                  final newPromotion = Promotion(
                    id: promotion?.id ?? '',
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
                        content: Text(
                          isEdit ? 'Promotion modifiée' : 'Promotion créée',
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
