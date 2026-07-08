import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/order.dart' as order_model;
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../services/order_service.dart';
import '../services/loyalty_service.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../widgets/responsive_scaffold.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  final _pointsController = TextEditingController();

  bool _isLoading = false;
  String _paymentMethod = 'wave';
  int _availablePoints = 0;
  int _pointsToUse = 0;

  final LoyaltyService _loyaltyService = LoyaltyService();

  static const String _waveNumber = '+225 07 88 71 18 96';
  static const double _deliveryFee = 2000;

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
    _loadPoints();
  }

  void _prefillUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _loadPoints() async {
    try {
      final points = await _loyaltyService.getPoints();
      if (mounted) setState(() => _availablePoints = points);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  double get _discount => (_pointsToUse / 100).floorToDouble() * 100;
  double get _subtotal =>
      Provider.of<CartProvider>(context, listen: false).totalAmount;
  double get _total => (_subtotal + _deliveryFee - _discount).clamp(0, double.infinity);

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Non connecté');

      final cart = Provider.of<CartProvider>(context, listen: false);
      // items = Map<String, int> (productId → quantity)
      // products = Map<String, Product> (productId → Product)
      final cartItems = cart.items.entries
          .map((e) => {
                'product': cart.products[e.key],
                'quantity': e.value,
              })
          .where((e) => e['product'] != null)
          .toList();

      debugPrint('🛒 Checkout - cartItems: ${cartItems.length} produits');
      if (cartItems.isEmpty) {
        throw Exception('Le panier est vide ou les produits ne sont pas chargés');
      }

      // 1. Utiliser les points si demandé
      int pointsRedeemed = 0;
      int discountAmount = 0;
      if (_pointsToUse > 0) {
        discountAmount = await _loyaltyService.redeemPoints(_pointsToUse);
        pointsRedeemed = _pointsToUse;
      }

      // 2. Créer la commande dans Firestore
      final now = DateTime.now();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final deliveryAddress =
          '${_addressController.text.trim()}, ${_cityController.text.trim()}';

      final order = order_model.Order(
        id: orderRef.id,
        userId: user.uid,
        customerName: _nameController.text.trim(),
        customerEmail: user.email ?? '',
        customerPhone: _phoneController.text.trim(),
        deliveryAddress: deliveryAddress,
        items: cartItems
            .map((item) {
              final product = item['product'] as Product;
              return order_model.OrderItem(
                productId: product.id,
                productName: product.name,
                unitPrice: product.price,
                quantity: item['quantity'] as int,
              );
            })
            .toList(),
        status: order_model.OrderStatus.pending,
        createdAt: now,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        statusHistory: [
          order_model.OrderStatusEntry(
            status: order_model.OrderStatus.pending,
            timestamp: now,
          ),
        ],
        pointsRedeemed: pointsRedeemed,
      );

      await OrderService().add(order);

      // 3. Notifier l'admin
      try {
        // Notifier les admins de la nouvelle commande
        await NotificationService().createForAllAdmins(
          title: '🛒 Nouvelle commande',
          message: '${_nameController.text.trim()} — ${_total.toStringAsFixed(0)} FCFA',
          type: NotificationType.order,
          entityId: order.id,
        );
      } catch (_) {}

      // 4. Vider le panier
      cart.clearCart();

      // 5. Afficher confirmation
      if (mounted) {
        _showConfirmation(order.id, discountAmount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConfirmation(String orderId, int discountAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Commande confirmée !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'N° ${orderId.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _confirmRow('Total', '${_total.toStringAsFixed(0)} FCFA'),
                  if (_paymentMethod == 'wave') ...[
                    const SizedBox(height: 6),
                    _confirmRow('Paiement', 'Wave Mobile Money'),
                    const SizedBox(height: 6),
                    _confirmRow('Numéro Wave', _waveNumber),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notre équipe vous contactera pour confirmer la livraison.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          // Bouton WhatsApp optionnel
          TextButton.icon(
            onPressed: () => _openWhatsApp(),
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('Contacter sur WhatsApp'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // ferme dialog
              context.go('/'); // retour accueil
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );

  Future<void> _openWhatsApp() async {
    final message =
        'Bonjour, j\'ai passé une commande sur Pharrell Phone. '
        'Nom: ${_nameController.text.trim()}, '
        'Téléphone: ${_phoneController.text.trim()}';
    final url = Uri.parse(
        'https://wa.me/2250788711896?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(
        url,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    // Construire une liste {product, quantity} pour l'affichage
    final cartItems = cart.items.entries
        .map((e) => {'product': cart.products[e.key], 'quantity': e.value})
        .where((e) => e['product'] != null)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        backgroundColor: AppTheme.primaryViolet,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Résumé panier ──
              _sectionTitle('Votre commande'),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = cartItems[i];
                    final product = item['product'] as Product;
                    final qty = item['quantity'] as int;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryViolet.withOpacity(0.1),
                        child: Text(
                          '$qty×',
                          style: TextStyle(
                              color: AppTheme.primaryViolet,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      trailing: Text(
                        '${(product.price * qty).toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                            color: AppTheme.primaryViolet,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── Informations client ──
              _sectionTitle('Vos informations'),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _field(_nameController, 'Nom complet', Icons.person,
                          required: true,
                          extraValidator: (v) {
                            if (v == null || v.trim().length < 3) {
                              return 'Minimum 3 caractères';
                            }
                            if (RegExp(r'\d').hasMatch(v)) {
                              return 'Le nom ne doit pas contenir de chiffres';
                            }
                            return null;
                          }),
                      const SizedBox(height: 12),
                      _field(_phoneController, 'Téléphone', Icons.phone,
                          required: true,
                          keyboardType: TextInputType.phone,
                          extraValidator: (v) {
                            if (v == null) return 'Champ requis';
                            final clean = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                            if (!RegExp(r'^\+?\d{8,15}$').hasMatch(clean)) {
                              return 'Format invalide (ex: 0788711896 ou +2250788711896)';
                            }
                            return null;
                          }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Adresse de livraison ──
              _sectionTitle('Adresse de livraison'),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _field(_addressController, 'Quartier / Rue',
                          Icons.location_on,
                          required: true,
                          extraValidator: (v) {
                            if (v != null && v.trim().length < 5) {
                              return 'Adresse trop courte (minimum 5 caractères)';
                            }
                            return null;
                          }),
                      const SizedBox(height: 12),
                      _field(_cityController, 'Ville', Icons.location_city,
                          required: true,
                          extraValidator: (v) {
                            if (v != null && v.trim().length < 2) {
                              return 'Ville trop courte';
                            }
                            if (v != null && RegExp(r'\d').hasMatch(v.trim())) {
                              return 'Le nom de ville ne doit pas contenir de chiffres';
                            }
                            return null;
                          }),
                      const SizedBox(height: 12),
                      _field(_notesController, 'Instructions (optionnel)',
                          Icons.note,
                          required: false, maxLines: 2),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Paiement ──
              _sectionTitle('Mode de paiement'),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'wave',
                      groupValue: _paymentMethod,
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v!),
                      title: const Text('Wave Mobile Money'),
                      subtitle: Text(_waveNumber),
                      secondary: const Icon(Icons.waves, color: Colors.blue),
                    ),
                    RadioListTile<String>(
                      value: 'cash',
                      groupValue: _paymentMethod,
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v!),
                      title: const Text('Paiement à la livraison'),
                      subtitle: const Text('Espèces uniquement'),
                      secondary:
                          const Icon(Icons.money, color: Colors.green),
                    ),
                    RadioListTile<String>(
                      value: 'orange',
                      groupValue: _paymentMethod,
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v!),
                      title: const Text('Orange Money'),
                      subtitle: const Text('Contactez-nous pour le numéro'),
                      secondary: const Icon(Icons.phone_android,
                          color: Colors.orange),
                    ),
                  ],
                ),
              ),

              // ── Points fidélité ──
              if (_availablePoints > 0) ...[
                const SizedBox(height: 20),
                _sectionTitle('Points de fidélité'),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Vous avez $_availablePoints points disponibles'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _pointsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Points à utiliser',
                            hintText:
                                'Max $_availablePoints pts',
                            border: const OutlineInputBorder(),
                            suffixText: 'pts',
                          ),
                          onChanged: (v) {
                            final pts =
                                int.tryParse(v) ?? 0;
                            setState(() => _pointsToUse =
                                pts.clamp(0, _availablePoints));
                          },
                        ),
                        if (_pointsToUse > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Réduction : -${_discount.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Récapitulatif ──
              Card(
                color: AppTheme.primaryViolet.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _totalRow('Sous-total',
                          '${_subtotal.toStringAsFixed(0)} FCFA'),
                      _totalRow('Livraison',
                          '${_deliveryFee.toStringAsFixed(0)} FCFA'),
                      if (_discount > 0)
                        _totalRow('Réduction fidélité',
                            '-${_discount.toStringAsFixed(0)} FCFA',
                            color: AppTheme.success),
                      const Divider(height: 20),
                      _totalRow(
                        'TOTAL',
                        '${_total.toStringAsFixed(0)} FCFA',
                        bold: true,
                        color: AppTheme.primaryViolet,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Bouton commander ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitOrder,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isLoading ? 'Traitement...' : 'Confirmer la commande',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? extraValidator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return 'Champ requis';
          }
          if (extraValidator != null) return extraValidator(v);
          return null;
        },
      );

  Widget _totalRow(String label, String value,
          {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal)),
            Text(value,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal,
                    color: color)),
          ],
        ),
      );
}