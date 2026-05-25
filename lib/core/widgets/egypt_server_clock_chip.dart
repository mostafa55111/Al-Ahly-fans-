import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';

/// شريحة خفيفة: ساعة مصر من خادم Firebase (للملعب / الجمهور).
class EgyptServerClockChip extends StatefulWidget {
  const EgyptServerClockChip({super.key});

  @override
  State<EgyptServerClockChip> createState() => _EgyptServerClockChipState();
}

class _EgyptServerClockChipState extends State<EgyptServerClockChip> {
  Timer? _tick;
  late final EgyptServerTimeService _time;

  @override
  void initState() {
    super.initState();
    _time = getIt<EgyptServerTimeService>();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _time.formatCairoClock();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.public,
            size: 12,
            color: Colors.white.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 4),
          Text(
            'مصر $label',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
