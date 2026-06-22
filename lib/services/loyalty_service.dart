import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service de gestion du programme de fidélité par points.
/// 1 point gagné par 1000 FCFA dépensés (crédité à la livraison, côté serveur).
/// 1 point = 10 FCFA de réduction (utilisable au checkout, décompté immédiatement).
class LoyaltyService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Lit le solde de points actuel du client connecté.
  /// Retourne 0 si non connecté ou si le champ n'existe pas encore.
  Future<int> getPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['loyaltyPoints'] as int? ?? 0;
  }

  /// Utilise [pointsToUse] points au checkout. Décompte immédiat côté serveur,
  /// dans une transaction qui vérifie le solde réel (jamais confiance dans une
  /// valeur affichée côté client). Retourne le montant de la réduction en FCFA.
  /// Lève une [FirebaseFunctionsException] si le solde est insuffisant ou si
  /// l'argument est invalide.
  Future<int> redeemPoints(int pointsToUse) async {
    final callable = _functions.httpsCallable('redeemLoyaltyPoints');
    final result = await callable.call({'pointsToUse': pointsToUse});
    final data = result.data as Map<String, dynamic>;
    return data['discountAmount'] as int;
  }
}