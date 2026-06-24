import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Service de gestion du programme de fidélité par points.
/// 1 point gagné par 1000 FCFA dépensés (crédité à la livraison, côté serveur).
/// 1 point = 10 FCFA de réduction (utilisable au checkout, décompté immédiatement).
/// Utilise HTTP direct — contournement bug FlutterFire #17924 (dart2js/Int64).
class LoyaltyService {
  static const String _base =
      'https://europe-west1-first-pro-cheoo.cloudfunctions.net';

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
  /// dans une transaction qui vérifie le solde réel. Retourne le montant de la
  /// réduction en FCFA.
  Future<int> redeemPoints(int pointsToUse) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final token = await user.getIdToken();
    final response = await http
        .post(
          Uri.parse('$_base/redeemLoyaltyPoints'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'data': {'pointsToUse': pointsToUse}}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'Erreur ${response.statusCode}');
    }

    final data =
        jsonDecode(response.body)['result'] as Map<String, dynamic>;
    return data['discountAmount'] as int;
  }
}