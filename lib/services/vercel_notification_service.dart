import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service pour envoyer des notifications push via l'API Vercel
/// 
/// Ce service appelle l'API serverless hébergée sur Vercel pour envoyer
/// des notifications FCM aux utilisateurs. Cela évite de payer pour
/// les Cloud Functions de Google.
class VercelNotificationService {
  // URL de l'API Vercel (déployée sur Vercel)
  static const String _defaultApiUrl = 'https://projet-eta-seven.vercel.app/api/send-notification';
  
  final String _apiUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  VercelNotificationService({String? apiUrl}) : _apiUrl = apiUrl ?? _defaultApiUrl;
  
  /// Vérifie si le service est configuré
  bool get isConfigured => _apiUrl.isNotEmpty && !_apiUrl.contains('your-project');
  
  /// Envoie une notification push à un topic FCM
  /// 
  /// [title] - Titre de la notification
  /// [body] - Corps de la notification  
  /// [topic] - Topic FCM (all_users, clients, admins)
  /// [data] - Données additionnelles (optionnel)
  Future<NotificationResult> sendNotification({
    required String title,
    required String body,
    String topic = 'all_users',
    Map<String, dynamic>? data,
  }) async {
    try {
      // Vérifier que l'utilisateur est connecté
      final user = _auth.currentUser;
      if (user == null) {
        return NotificationResult(
          success: false,
          error: 'Vous devez être connecté pour envoyer des notifications',
        );
      }
      
      // Obtenir le token Firebase
      final idToken = await user.getIdToken();
      if (idToken == null) {
        return NotificationResult(
          success: false,
          error: 'Impossible d\'obtenir le token d\'authentification',
        );
      }
      
      // Préparer le body de la requête
      final requestBody = {
        'title': title,
        'body': body,
        'topic': topic,
        if (data != null) 'data': data,
      };
      
      debugPrint('📤 Envoi notification via Vercel: $title');
      
      // Appeler l'API Vercel
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(requestBody),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        debugPrint('✅ Notification envoyée: ${responseData['messageId']}');
        return NotificationResult(
          success: true,
          messageId: responseData['messageId'],
          message: responseData['message'] ?? 'Notification envoyée',
        );
      } else {
        debugPrint('❌ Erreur API: ${responseData['error']}');
        return NotificationResult(
          success: false,
          error: responseData['error'] ?? 'Erreur inconnue',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      return NotificationResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Envoie une notification à tous les utilisateurs
  Future<NotificationResult> sendToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return sendNotification(
      title: title,
      body: body,
      topic: 'all_users',
      data: data,
    );
  }
  
  /// Envoie une notification aux clients uniquement
  Future<NotificationResult> sendToClients({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return sendNotification(
      title: title,
      body: body,
      topic: 'clients',
      data: data,
    );
  }
  
  /// Envoie une notification aux admins uniquement
  Future<NotificationResult> sendToAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return sendNotification(
      title: title,
      body: body,
      topic: 'admins',
      data: data,
    );
  }
}

/// Résultat de l'envoi d'une notification
class NotificationResult {
  final bool success;
  final String? messageId;
  final String? message;
  final String? error;
  final int? statusCode;
  
  NotificationResult({
    required this.success,
    this.messageId,
    this.message,
    this.error,
    this.statusCode,
  });
  
  @override
  String toString() {
    if (success) {
      return 'NotificationResult(success: true, messageId: $messageId)';
    } else {
      return 'NotificationResult(success: false, error: $error)';
    }
  }
}
