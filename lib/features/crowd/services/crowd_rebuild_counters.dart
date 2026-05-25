import 'package:flutter/widgets.dart';

/// عدّادات إعادة البناء (تصحيح فقط) — لا تُفعَّل في release.
class CrowdRebuildCounters {
  CrowdRebuildCounters._();
  static final Map<String, int> _counts = {};

  static void bump(String id) {
    assert(() {
      _counts[id] = (_counts[id] ?? 0) + 1;
      return true;
    }());
  }

  static int read(String id) => _counts[id] ?? 0;

  static Map<String, int> snapshot() => Map<String, int>.from(_counts);

  static void clear() {
    assert(() {
      _counts.clear();
      return true;
    }());
  }
}

/// يلفّ [child] ويزيد العداد في كل [build] (لرصد العواصف).
class CrowdRebuildProbe extends StatelessWidget {
  const CrowdRebuildProbe({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(() {
      CrowdRebuildCounters.bump(label);
      return true;
    }());
    return child;
  }
}
