import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Un tour de conversation, soit du client ('user') soit de l'assistant ('model').
class ChatMessage {
  final String role;
  final String text;
  ChatMessage({required this.role, required this.text});
}

/// Service centralisé pour toutes les fonctions IA de Pharrell Phone.
/// Utilise HTTP direct — contournement bug FlutterFire #17924 (dart2js/Int64).
class AiChatService {
  static const String _base =
      'https://europe-west1-first-pro-cheoo.cloudfunctions.net';

  final List<ChatMessage> _history = [];
  List<ChatMessage> get history => List.unmodifiable(_history);

  /// Headers communs — token auth optionnel si connecté.
  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Envoie un message au chat et retourne la réponse.
  /// Le catalogue est chargé côté serveur — données toujours fraîches.
  Future<String> sendMessage(String message) async {
    _history.add(ChatMessage(role: 'user', text: message));

    try {
      final historyPayload = _history
          .sublist(0, _history.length - 1)
          .map((m) => {'role': m.role, 'text': m.text})
          .toList();

      final response = await http
          .post(
            Uri.parse('$_base/chatWithAssistant'),
            headers: await _headers(),
            body: jsonEncode({
              'data': {
                'message': message,
                'history': historyPayload,
              },
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        final msg = err['error']?['message'] ?? 'Erreur ${response.statusCode}';
        if (msg.contains('resource-exhausted')) {
          throw Exception('[firebase_functions/resource-exhausted] $msg');
        }
        throw Exception(msg);
      }

      final data = jsonDecode(response.body)['result'] as Map<String, dynamic>;
      final reply = data['reply'] as String;
      _history.add(ChatMessage(role: 'model', text: reply));
      return reply;
    } catch (_) {
      if (_history.isNotEmpty && _history.last.role == 'user') {
        _history.removeLast();
      }
      rethrow;
    }
  }

  /// Demande une analyse IA comparative de [productIds] (2 ou 3 produits).
  /// Retourne le texte d'analyse structuré généré par Gemini.
  Future<String> compareProducts(List<String> productIds) async {
    final response = await http
        .post(
          Uri.parse('$_base/compareProducts'),
          headers: await _headers(),
          body: jsonEncode({
            'data': {'productIds': productIds},
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(
          err['error']?['message'] ?? 'Erreur ${response.statusCode}');
    }

    final data = jsonDecode(response.body)['result'] as Map<String, dynamic>;
    return data['analysis'] as String;
  }

  void clearHistory() => _history.clear();
}