import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_theme.dart';
import '../models/order.dart' as order_model;
import '../services/order_service.dart';
import '../services/loyalty_service.dart';
import '../widgets/ui_components.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/styled_dialogs.dart';
import '../widgets/optimized_image.dart';
import '../widgets/responsive_scaffold.dart';
import '../providers/app_providers.dart';
import '../web_config/navigation_helper.dart';
import '../web_config/responsive_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Écran de panier moderne avec design élégant
class ModernCartScreen extends StatefulWidget {
  const ModernCartScreen({Key? key}) : super(key: key);

  @override
  State<ModernCartScreen> createState() => _ModernCartScreenState();
}

class _ModernCartScreenState extends State<ModernCartScreen>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  double get _deliveryFee => 5000.0;

  /// Numéro Wave pour le paiement — identique au numéro WhatsApp de commande.
  static const String _waveNumber = '07 88 71 18 96';

  final LoyaltyService _loyaltyService = LoyaltyService();
  final TextEditingController _pointsController = TextEditingController();
  int _availablePoints = 0;

  @override
  void initState() {
    super.initState();
    _loyaltyService.getPoints().then((points) {
      if (mounted) setState(() => _availablePoints = points);
    });
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  /// Réduction en FCFA correspondant au nombre de points actuellement saisi,
  /// plafonnée au solde réellement disponible. Purement indicatif côté UI :
  /// la vérification réelle se fait côté serveur au moment de _placeOrder.
  int get _pointsDiscountPreview {
    final typed = int.tryParse(_pointsController.text.trim()) ?? 0;
    final clamped = typed > _availablePoints ? _availablePoints : typed;
    return clamped < 0 ? 0 : clamped * 10;
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final cartItems = cart.items.entries.map((entry) {
          final product = cart.products[entry.key];
          if (product == null) return null;
          return {
            'product': product,
            'quantity': entry.value,
          };
        }).where((item) => item != null).toList();
        
        final subtotal = cart.totalAmount;
        final total = subtotal + _deliveryFee;
    
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        actions: [
          // Badge compteur
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CounterBadge(count: cart.itemCount),
            ),
          ),
        ],
      ),
      
      body: cart.itemCount == 0
          ? _buildEmptyCart(context)
          : Column(
              children: [
                // Liste des articles
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(context, cartItems[index]!, index, cart);
                    },
                  ),
                ),
                
                // Résumé et bouton
                _buildBottomSummary(context, isDark, subtotal, total, cart, cartItems),
              ],
            ),
      );
      },
    );
  }
  
  /// État vide du panier
  Widget _buildEmptyCart(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Votre panier est vide',
      message: 'Ajoutez des produits pour commencer vos achats',
      buttonText: 'Découvrir nos produits',
      onButtonPressed: () {
        AppNavigator.pushReplacement(context, AppNavigator.catalogRoute);
      },
    );
  }
  
  /// Item du panier
  Widget _buildCartItem(BuildContext context, Map<String, dynamic> itemData, int index, CartProvider cart) {
    final theme = Theme.of(context);
    final product = itemData['product'];
    final quantity = itemData['quantity'] as int;
    
    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        cart.removeItem(product.id);
        
        CustomSnackBar.show(
          context,
          message: '${product.name} retiré du panier',
          type: SnackBarType.info,
          actionLabel: 'ANNULER',
          onAction: () {
            cart.addItem(product, quantity: quantity);
          },
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProductImage(
                  imageUrl: product.imageUrls.isNotEmpty 
                    ? product.imageUrls.first 
                    : null,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Marque
                    Text(
                      product.brand,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    
                    // Nom
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Quantité et total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Stepper quantité
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            if (quantity > 1) {
                              cart.decrementQuantity(product.id);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.remove, size: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            quantity.toString(),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (quantity < product.stock) {
                              cart.incrementQuantity(product.id);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.add, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Total ligne
                  Text(
                    '${(product.price * quantity).toStringAsFixed(0)} FCFA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryViolet,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Résumé et bouton de commande
  Widget _buildBottomSummary(BuildContext context, bool isDark, double subtotal, double total, CartProvider cart, List<Map<String, dynamic>?> cartItems) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryVioletDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sous-total
            _buildSummaryRow(
              context,
              'Sous-total',
              '${subtotal.toStringAsFixed(0)} FCFA',
              false,
            ),
            
            const SizedBox(height: 8),
            
            // Frais de livraison
            _buildSummaryRow(
              context,
              'Livraison',
              '${_deliveryFee.toStringAsFixed(0)} FCFA',
              false,
            ),
            
            const Divider(height: 24),
            
            // Total
            _buildSummaryRow(
              context,
              'Total',
              '${total.toStringAsFixed(0)} FCFA',
              true,
            ),

            // Programme de fidélité (uniquement si le client a des points)
            if (_availablePoints > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 18,
                          color: AppTheme.primaryViolet,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$_availablePoints points disponibles (1 pt = 10 FCFA)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pointsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Points à utiliser',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_pointsDiscountPreview > 0)
                          Text(
                            '-${_pointsDiscountPreview.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Boutons
            Row(
              children: [
                // Continuer les achats
                Expanded(
                  child: SecondaryButton(
                    text: 'Continuer',
                    height: 56,
                    onPressed: () {
                      context.pop();
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Commander
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Commander',
                    icon: Icons.chat,
                    height: 56,
                    onPressed: () => _placeOrder(cart, cartItems),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info paiement Wave (non-bloquant, purement informatif)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  'Paiement accepté : Wave',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Ligne de résumé
  Widget _buildSummaryRow(BuildContext context, String label, String value, bool isTotal) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleLarge
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryViolet,
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
  
  /// Passer commande via WhatsApp
  void _placeOrder(CartProvider cart, List<Map<String, dynamic>?> cartItems) async {
    // Vérifier si l'utilisateur est connecté (et pas anonyme)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      // Montrer un dialogue stylé pour se connecter
      final shouldLogin = await StyledDialogs.showAuthRequiredDialog(
        context,
        customMessage: 'Pour finaliser votre commande, connectez-vous ou créez un compte.\n\nVos informations nous permettent de vous contacter.',
      );
      
      if (shouldLogin == true && mounted) {
        AppNavigator.push(context, AppNavigator.authRoute);
      }
      return;
    }

    // Utiliser les points de fidélité si le client en a saisi. Décompte
    // immédiat côté serveur (transaction), avant même la création de la
    // commande, pour empêcher toute double-dépense sur deux commandes
    // simultanées. Si ça échoue (solde insuffisant), on bloque la commande
    // plutôt que de continuer sans la réduction promise au client.
    int pointsRedeemed = 0;
    int discountAmount = 0;
    final pointsToUse = int.tryParse(_pointsController.text.trim()) ?? 0;

    if (pointsToUse > 0) {
      try {
        discountAmount = await _loyaltyService.redeemPoints(pointsToUse);
        pointsRedeemed = pointsToUse;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Impossible d'utiliser ces points : solde insuffisant",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Créer la commande dans Firestore (pour le suivi côté client dans
    // "Mes Commandes"). Ne bloque jamais l'envoi WhatsApp si ça échoue :
    // WhatsApp reste le canal principal de la commande aujourd'hui.
    try {
      final now = DateTime.now();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final order = order_model.Order(
        id: orderRef.id,
        userId: user.uid,
        customerName: user.displayName ?? '',
        customerEmail: user.email ?? '',
        customerPhone: user.phoneNumber ?? '',
        deliveryAddress: '[À compléter]',
        items: cartItems
            .where((item) => item != null)
            .map(
              (item) => order_model.OrderItem(
                productId: item!['product'].id as String,
                productName: item['product'].name as String,
                unitPrice: (item['product'].price as num).toDouble(),
                quantity: item['quantity'] as int,
              ),
            )
            .toList(),
        status: order_model.OrderStatus.pending,
        createdAt: now,
        statusHistory: [
          order_model.OrderStatusEntry(
            status: order_model.OrderStatus.pending,
            timestamp: now,
          ),
        ],
        pointsRedeemed: pointsRedeemed,
      );
      await OrderService().add(order);
    } catch (e) {
      debugPrint('Erreur lors de la création de la commande Firestore: $e');
    }
    
    // Construire le message
    String message = '🛒 *Nouvelle Commande Pharrell Phone*\n\n';
    
    // Ajouter l'identifiant utilisateur
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      message += '👤 *Client :* ${user.displayName}\n';
    }
    if (user.email != null && user.email!.isNotEmpty) {
      message += '📧 *Email :* ${user.email}\n';
    }
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      message += '📞 *Téléphone :* ${user.phoneNumber}\n';
    }
    message += '\n📱 *Produits :*\n';
    
    for (var itemData in cartItems) {
      if (itemData == null) continue;
      final product = itemData['product'];
      final quantity = itemData['quantity'];
      message += '• ${product.name} × $quantity = ${(product.price * quantity).toStringAsFixed(0)} FCFA\n';
    }
    
    final subtotal = cart.totalAmount;
    final totalBeforeDiscount = subtotal + _deliveryFee;
    final total = totalBeforeDiscount - discountAmount;
    
    message += '\n💰 *Sous-total :* ${subtotal.toStringAsFixed(0)} FCFA\n';
    message += '🚚 *Livraison :* ${_deliveryFee.toStringAsFixed(0)} FCFA\n';
    if (discountAmount > 0) {
      message += '🎁 *Réduction fidélité ($pointsRedeemed pts) :* -${discountAmount.toStringAsFixed(0)} FCFA\n';
    }
    message += '\n*TOTAL : ${total.toStringAsFixed(0)} FCFA*\n\n';
    message += '📍 *Adresse de livraison :* [À compléter]\n\n';
    message += '💳 *Paiement Wave disponible après confirmation :* $_waveNumber\n\n';
    message += 'Merci !';
    
    final url = Uri.parse('https://wa.me/2250788711896?text=${Uri.encodeComponent(message)}');
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      
      // Optionnel: Vider le panier après envoi
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Commande envoyée'),
            content: const Text('Votre commande a été envoyée sur WhatsApp. Voulez-vous vider le panier ?'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Non'),
              ),
              ElevatedButton(
                onPressed: () {
                  cart.clearCart();
                  context.pop();
                  context.pop();
                },
                child: const Text('Oui'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Impossible d\'ouvrir WhatsApp');
      }
    }
  }
}