import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// فقاعة رسالة دردشة — نص، صورة، وروابط (زر فتح عند الحاجة).
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.text,
    this.imageUrl,
    required this.isMine,
    required this.accentColor,
  });

  final String text;
  final String? imageUrl;
  final bool isMine;
  final Color accentColor;

  static final _urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);

  Iterable<String> _urlsIn(String s) =>
      _urlRegex.allMatches(s).map((m) => m.group(0)!).toSet();

  @override
  Widget build(BuildContext context) {
    final bg = isMine
        ? accentColor.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.08);
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final urls = text.isEmpty ? const <String>[] : _urlsIn(text).toList();

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null && imageUrl!.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!.trim(),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 120,
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                        color: Colors.white54),
                  ),
                ),
              if (imageUrl != null &&
                  imageUrl!.trim().isNotEmpty &&
                  text.isNotEmpty)
                const SizedBox(height: 8),
              if (text.isNotEmpty)
                SelectableText(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              if (urls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: urls
                      .map(
                        (u) => TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            final uri = Uri.tryParse(u);
                            if (uri != null) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Text(
                            'فتح الرابط',
                            style: TextStyle(
                              color: Colors.lightBlueAccent.shade100,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
