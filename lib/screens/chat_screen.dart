import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../services/ai_chat_service.dart';
import '../web_config/navigation_helper.dart';
import '../widgets/responsive_scaffold.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AiChatService _chatService = AiChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(text);
    } catch (e) {
      debugPrint('Erreur chatWithAssistant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().contains('resource-exhausted')
              ? 'Service temporairement occupé, contactez-nous sur WhatsApp.'
              : 'Erreur de connexion, réessayez.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse(
      'https://wa.me/2250788711896?text=${Uri.encodeComponent("Bonjour, j\'ai besoin d\'aide avec l\'application Pharrell Phone.")}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d\'ouvrir WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    _scrollToBottom();
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Assistant Pharrell Phone'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Contacter sur WhatsApp',
            onPressed: _openWhatsApp,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatService.history.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "Bonjour ! Je suis l'assistant de Pharrell Phone.\n"
                        "Posez-moi une question sur nos produits, prix ou livraisons !",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatService.history.length,
                    itemBuilder: (context, index) {
                      final msg = _chatService.history[index];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.primaryViolet : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: isUser
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Text(msg.text,
                                      style: const TextStyle(color: Colors.white)))
                              : _AssistantMessage(
                                  text: msg.text,
                                  onProductTap: (productId) =>
                                      AppNavigator.toProductDetail(context, productId),
                                ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryViolet)),
                const SizedBox(width: 10),
                Text('L\'assistant réfléchit…',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Posez votre question…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget message assistant avec liens produits ───────────────────────────

/// Parse le texte de l'IA et détecte les tags [PRODUIT:id:nom].
/// Affiche le texte normal + des chips cliquables pour chaque produit mentionné.
class _AssistantMessage extends StatelessWidget {
  final String text;
  final void Function(String productId) onProductTap;

  const _AssistantMessage({required this.text, required this.onProductTap});

  static final _tagRegex = RegExp(r'\[PRODUIT:([^:]+):([^\]]+)\]');

  @override
  Widget build(BuildContext context) {
    // Extraire les produits mentionnés (ordre d'apparition, sans doublons)
    final products = <({String id, String name})>[];
    final seenIds = <String>{};
    for (final match in _tagRegex.allMatches(text)) {
      final id = match.group(1)!;
      if (seenIds.add(id)) {
        products.add((id: id, name: match.group(2)!));
      }
    }

    // Nettoyer le texte affiché : retirer les tags
    final cleanText = text.replaceAll(_tagRegex, '').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texte de la réponse
          Text(cleanText, style: const TextStyle(color: Colors.black87)),

          // Chips produits (si l'IA en a mentionné)
          if (products.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 8),
            Text('Voir le produit :',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: products.map((p) => _ProductChip(
                name: p.name,
                onTap: () => onProductTap(p.id),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _ProductChip({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryViolet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.open_in_new, size: 13, color: AppTheme.primaryViolet),
          const SizedBox(width: 5),
          Text(name,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryViolet,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}