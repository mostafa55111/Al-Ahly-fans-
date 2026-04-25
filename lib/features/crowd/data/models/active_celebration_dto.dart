import 'package:equatable/equatable.dart';

/// عرض فائز — يُقرأ من [active_celebration] (يضبطه الأدمن لاحقاً).
///
/// **مدد العرض المقترحة (وقت خادم / `showUntilServerMs`):**
/// - مباراة: يومان من لحظة الإعلان.
/// - شهر: نحو 31 يوماً من الإعلان (مجمّع الأصوات التراكمي).
/// - موسم: حتى `showUntil` الذي يضبطه الأدمن (بداية الموسم الجديد).
enum CelebrationKind { match, month, season }

class ActiveCelebrationDto extends Equatable {
  final String uniqueKey;
  final CelebrationKind kind;
  final String playerId;
  final String playerName;
  final String? photoUrl;
  final int showUntilServerMs;
  final int? createdAtServerMs;

  const ActiveCelebrationDto({
    required this.uniqueKey,
    required this.kind,
    required this.playerId,
    required this.playerName,
    this.photoUrl,
    required this.showUntilServerMs,
    this.createdAtServerMs,
  });

  static CelebrationKind _parseKind(String? s) {
    switch (s) {
      case 'month':
        return CelebrationKind.month;
      case 'season':
        return CelebrationKind.season;
      case 'match':
      default:
        return CelebrationKind.match;
    }
  }

  factory ActiveCelebrationDto.fromMap(Map<dynamic, dynamic> m) {
    final k = m['uniqueKey']?.toString() ?? m['id']?.toString() ?? '';
    return ActiveCelebrationDto(
      uniqueKey: k,
      kind: _parseKind(m['kind']?.toString()),
      playerId: (m['playerId'] ?? '').toString(),
      playerName: (m['playerName'] ?? m['name'] ?? 'الفائز').toString(),
      photoUrl: m['photoUrl']?.toString(),
      showUntilServerMs: _asInt(m['showUntil'] ?? m['showUntilServerMs'] ?? 0),
      createdAtServerMs: m['createdAt'] != null ? _asInt(m['createdAt']) : null,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  List<Object?> get props =>
      [uniqueKey, kind, playerId, playerName, showUntilServerMs];
}
