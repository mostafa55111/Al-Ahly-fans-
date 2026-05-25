import 'package:flutter/material.dart';

/// عدّاد تنازلي لتصويت رجل المباراة.
/// يستخدم [ThemeData.colorScheme] ليتوافق مع هوية كل تطبيق.
class MotmCountdown extends StatelessWidget {
  final int remainingSeconds;
  final int totalDurationSeconds;
  final bool closed;

  const MotmCountdown({
    super.key,
    required this.remainingSeconds,
    this.totalDurationSeconds = 60 * 60,
    this.closed = false,
  });

  String _format(int s) {
    if (s < 0) s = 0;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final secondary = scheme.secondary;
    final pct = (remainingSeconds / totalDurationSeconds).clamp(0.0, 1.0);
    final color = closed
        ? Colors.grey
        : (remainingSeconds < 300 ? primary : secondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            closed ? Icons.flag_circle : Icons.timer_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  closed ? 'انتهى التصويت' : 'متبقي على إغلاق التصويت',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _format(remainingSeconds),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
