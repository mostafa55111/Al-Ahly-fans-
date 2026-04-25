import 'package:equatable/equatable.dart';

/// جلسة تصويت «نسر المباراة» — بيانات من [session_current].
/// **`startedAt`**: يُفضَّل تسجيله بـ `ServerValue.timestamp` في RTDB ليتوافق مع مزامنة وقت الخادم في التطبيق.
class EagleSessionDto extends Equatable {
  final String id;
  final int startedAtServerMs;
  final String yyyymm;
  final String seasonId;
  final Set<String> eligiblePlayerIds;

  const EagleSessionDto({
    required this.id,
    required this.startedAtServerMs,
    required this.yyyymm,
    required this.seasonId,
    required this.eligiblePlayerIds,
  });

  factory EagleSessionDto.fromMap(Map<dynamic, dynamic> m) {
    final id = (m['id'] ?? m['sessionId'] ?? '').toString();
    final started = m['startedAt'] ?? m['startedAtServerMs'] ?? 0;
    final startedMs = started is int
        ? started
        : (started is num)
            ? started.toInt()
            : int.tryParse('$started') ?? 0;
    final ym = (m['yyyymm'] ?? '').toString();
    final season = (m['seasonId'] ?? m['season'] ?? 'default').toString();
    final elig = <String>{};
    final raw = m['eligible'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v == true || v == 1) elig.add(k.toString());
      });
    } else if (raw is List) {
      for (final e in raw) {
        if (e != null) elig.add(e.toString());
      }
    }

    return EagleSessionDto(
      id: id,
      startedAtServerMs: startedMs,
      yyyymm: ym,
      seasonId: season,
      eligiblePlayerIds: elig,
    );
  }

  bool get isValid => id.isNotEmpty && startedAtServerMs > 0 && yyyymm.isNotEmpty;

  @override
  List<Object?> get props => [id, startedAtServerMs, yyyymm, seasonId, eligiblePlayerIds];
}
