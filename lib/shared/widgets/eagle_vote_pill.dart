import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Pill شفاف/فخم فوق الفيديو يعرض:
/// - عنوان التصويت
/// - عدّ تنازلي Real-time
/// - (اختياري) زر إجراء
class EagleVotePill extends StatefulWidget {
  const EagleVotePill({
    super.key,
    required this.title,
    required this.voteEndAt,
    this.nowOverride,
    this.onPressed,
    this.buttonText,
    this.icon,
  });

  final String title;
  final DateTime voteEndAt;
  final DateTime? nowOverride;
  final VoidCallback? onPressed;
  final String? buttonText;
  final IconData? icon;

  @override
  State<EagleVotePill> createState() => _EagleVotePillState();
}

class _EagleVotePillState extends State<EagleVotePill> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.nowOverride ?? DateTime.now();

    // إذا الأب أعطى الآن بشكل مباشر (nowOverride)، ما نحتاجش Timer داخلي.
    if (widget.nowOverride == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.nowOverride ?? _now;
    final left = widget.voteEndAt.difference(now);
    final votingOpen = left.inMilliseconds > 0;

    final durationText = votingOpen ? _formatDuration(left) : 'انتهى';
    final hasButton = widget.onPressed != null && widget.buttonText != null;

    final icon = widget.icon ?? Icons.emoji_events_outlined;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.95), size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.98),
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black87),
                        Shadow(blurRadius: 2, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    votingOpen ? 'يتبقى $durationText' : 'التصويت مغلق',
                    style: TextStyle(
                      color: votingOpen
                          ? const Color(0xFF53D769)
                          : Colors.orangeAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black87),
                        Shadow(blurRadius: 2, color: Colors.black54),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasButton) ...[
                const SizedBox(width: 10),
                const SizedBox(height: 0),
                _ActionButton(
                  enabled: votingOpen,
                  text: widget.buttonText!,
                  onPressed: widget.onPressed!,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return card;
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.enabled,
    required this.text,
    required this.onPressed,
  });

  final bool enabled;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.95),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black87),
              Shadow(blurRadius: 2, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
