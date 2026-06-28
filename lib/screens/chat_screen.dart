import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../widgets/app_toast.dart';
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
        AppToast.error(context, e.toString().contains('resource-exhausted')
            ? 'Service temporairement indisponible. Contactez-nous sur WhatsApp.'
            : 'Erreur de connexion, réessayez.');
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
      if (mounted) AppToast.error(context, "Impossible d\'ouvrir WhatsApp");
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
          // Texte de la réponse avec rendu Markdown
          _MarkdownBody(text: cleanText),

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

// ── Rendu Markdown pour les messages de l'assistant ───────────────────────

/// Transforme le Markdown simple de Gemini en widgets Flutter lisibles.
/// Gère : **gras**, *italique*, ## titres, - listes, ` code inline`.
class _MarkdownBody extends StatelessWidget {
  final String text;
  const _MarkdownBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();

      // Ligne vide
      if (line.isEmpty) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Titre ## ou ###
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: _inlineSpan(line.substring(4),
              baseStyle: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 14, color: Colors.black87)),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 3),
          child: _inlineSpan(line.substring(3),
              baseStyle: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 15, color: AppTheme.primaryViolet)),
        ));
        continue;
      }

      // Puce - ou *
      if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.shade500, shape: BoxShape.circle),
              ),
            ),
            Expanded(child: _inlineSpan(line.substring(2))),
          ]),
        ));
        continue;
      }

      // Ligne normale
      widgets.add(_inlineSpan(line));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// Transforme **gras**, *italique*, `code` en TextSpans.
  Widget _inlineSpan(String line, {TextStyle? baseStyle}) {
    final base = baseStyle ??
        const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5);

    final spans = <TextSpan>[];
    // Regex: **gras**, *italique*, `code`
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    int last = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start), style: base));
      }
      if (match.group(1) != null) {
        // **gras**
        spans.add(TextSpan(
            text: match.group(1),
            style: base.copyWith(fontWeight: FontWeight.bold)));
      } else if (match.group(2) != null) {
        // *italique*
        spans.add(TextSpan(
            text: match.group(2),
            style: base.copyWith(fontStyle: FontStyle.italic)));
      } else if (match.group(3) != null) {
        // `code`
        spans.add(TextSpan(
            text: match.group(3),
            style: base.copyWith(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey.shade200,
                fontSize: 13)));
      }
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last), style: base));
    }

    return RichText(
      text: TextSpan(children: spans, style: base),
    );
  }
}