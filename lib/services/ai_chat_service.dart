import 'package:cloud_functions/cloud_functions.dart';

/// Un tour de conversation, soit du client ('user') soit de l'assistant
/// ('model').
class ChatMessage {
  final String role;
  final String text;
  ChatMessage({required this.role, required this.text});
}

/// Service de chat avec l'assistant IA (propulsé par Gemini, via la Cloud
/// Function chatWithAssistant). Maintient l'historique de conversation en
/// mémoire pour la durée de la session, sans persistance — comme le panier
/// ou le comparateur, l'historique se vide à la fermeture de l'app.
class AiChatService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  final List<ChatMessage> _history = [];
  List<ChatMessage> get history => List.unmodifiable(_history);

  /// Envoie un message à l'assistant et retourne sa réponse. Met à jour
  /// l'historique interne (message envoyé + réponse reçue).
  Future<String> sendMessage(String message) async {
    _history.add(ChatMessage(role: 'user', text: message));

    final callable = _functions.httpsCallable('chatWithAssistant');
    final result = await callable.call({
      'message': message,
      'history': _history
          .sublist(0, _history.length - 1)
          .map((m) => {'role': m.role, 'text': m.text})
          .toList(),
    });

    final reply = (result.data as Map<String, dynamic>)['reply'] as String;
    _history.add(ChatMessage(role: 'model', text: reply));
    return reply;
  }

  void clearHistory() => _history.clear();
}