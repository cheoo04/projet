import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/promotion.dart';
import '../services/promotion_service.dart';
import 'promotion_form_screen.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final PromotionService _service = PromotionService();
  List<Promotion> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final promotions = await _service.fetchAll();
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePromotion(Promotion promotion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la promotion'),
        content: Text('Voulez-vous supprimer "${promotion.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.delete(promotion.id);
        _loadPromotions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${promotion.name} supprimée')),
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

  Future<void> _toggleActive(Promotion promotion) async {
    try {
      await _service.toggleActive(promotion.id, !promotion.isActive);
      _loadPromotions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              promotion.isActive
                  ? '${promotion.name} désactivée'
                  : '${promotion.name} activée',
            ),
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

  Future<void> _openForm([Promotion? promotion]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PromotionFormScreen(promotion: promotion),
      ),
    );
    if (result == true) _loadPromotions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des promotions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
            tooltip: 'Ajouter une promotion',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadPromotions,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _promotions.length,
                itemBuilder: (context, index) {
                  final promotion = _promotions[index];
                  return _buildPromotionCard(promotion);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Ajouter une promotion',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune promotion',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre première promotion',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Créer une promotion'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isExpired = promotion.endDate.isBefore(DateTime.now());
    final isUpcoming = promotion.startDate.isAfter(DateTime.now());

    Color statusColor = Colors.green;
    String statusText = 'Active';

    if (!promotion.isActive) {
      statusColor = Colors.grey;
      statusText = 'Inactive';
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expirée';
    } else if (isUpcoming) {
      statusColor = Colors.orange;
      statusText = 'À venir';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(Icons.local_offer, color: statusColor),
        ),
        title: Text(
          promotion.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(promotion.discountText),
            Text(
              '${dateFormat.format(promotion.startDate)} - ${dateFormat.format(promotion.endDate)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${promotion.productIds.length} produit(s)',
              style: const TextStyle(fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _openForm(promotion);
                break;
              case 'toggle':
                _toggleActive(promotion);
                break;
              case 'delete':
                _deletePromotion(promotion);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(
                  promotion.isActive ? Icons.pause : Icons.play_arrow,
                ),
                title: Text(promotion.isActive ? 'Désactiver' : 'Activer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
