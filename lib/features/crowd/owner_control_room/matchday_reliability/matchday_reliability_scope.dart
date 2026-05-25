import 'package:flutter/widgets.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_bundle.dart';

/// يوفّر حزمة الموثوقية لشجرة غرفة التحكم.
class MatchdayReliabilityScope extends InheritedWidget {
  const MatchdayReliabilityScope({
    super.key,
    required this.bundle,
    required super.child,
  });

  final MatchdayReliabilityBundle bundle;

  static MatchdayReliabilityBundle of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MatchdayReliabilityScope>();
    assert(scope != null, 'MatchdayReliabilityScope missing');
    return scope!.bundle;
  }

  @override
  bool updateShouldNotify(MatchdayReliabilityScope oldWidget) =>
      oldWidget.bundle != bundle;
}
