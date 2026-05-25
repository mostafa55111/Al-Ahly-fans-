import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

/// تنبيه تنازلي قبل انطلاق الحافلة إذا لم يُسجَّل مسح الصعود بعد.
class BoardingCountdownBanner extends StatefulWidget {
  const BoardingCountdownBanner({
    super.key,
    required this.departureAt,
    required this.boardingConfirmed,
  });

  final DateTime departureAt;
  final bool boardingConfirmed;

  @override
  State<BoardingCountdownBanner> createState() =>
      _BoardingCountdownBannerState();
}

class _BoardingCountdownBannerState extends State<BoardingCountdownBanner> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.boardingConfirmed) return const SizedBox.shrink();

    final now = DateTime.now();
    final diff = widget.departureAt.difference(now);
    if (diff.isNegative) {
      return _banner(
        color: AppColors.error,
        icon: Icons.warning_amber_rounded,
        title: 'انطلقت الحافلة',
        subtitle: 'راجع الإدارة إذا لم تتمكن من الصعود.',
      );
    }

    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);

    return _banner(
      color: h == 0 && m < 15 ? AppColors.warning : AppColors.royalRed,
      icon: Icons.timer_outlined,
      title: 'لم يُسجَّل دخولك بعد — موعد الانطلاق قريب',
      subtitle:
          'متبقي ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
    );
  }

  Widget _banner({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.lightGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
