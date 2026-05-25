import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/widgets/match_voting_idle_surface.dart';

/// يمنع مؤشر تحميل لا نهائي — بعد مهلة قصيرة يعرض حالة idle السينمائية.
class CrowdVoteLoadingGate extends StatefulWidget {
  const CrowdVoteLoadingGate({super.key, this.maxWait = const Duration(seconds: 3)});

  final Duration maxWait;

  @override
  State<CrowdVoteLoadingGate> createState() => _CrowdVoteLoadingGateState();
}

class _CrowdVoteLoadingGateState extends State<CrowdVoteLoadingGate> {
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.maxWait, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) {
      return const MatchVotingIdleSurface();
    }
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
