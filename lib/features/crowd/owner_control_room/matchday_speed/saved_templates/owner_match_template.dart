import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_lineup_slot.dart';

/// قالب تشكيلة محفوظ للمالك — إطلاق سريع يوم المباراة.
class OwnerMatchTemplate extends Equatable {
  const OwnerMatchTemplate({
    required this.id,
    required this.name,
    required this.formation,
    this.starters = const [],
    this.bench = const [],
    this.createdAt = 0,
    this.lastUsedAt = 0,
    this.appId = '',
  });

  final String id;
  final String name;
  final String formation;
  final List<StadiumLineupSlot> starters;
  final List<StadiumLineupSlot> bench;
  final int createdAt;
  final int lastUsedAt;
  final String appId;

  factory OwnerMatchTemplate.fromMap(String id, Map<dynamic, dynamic> m) {
    return OwnerMatchTemplate(
      id: id,
      name: m['name']?.toString() ?? '',
      formation: m['formation']?.toString() ?? '4-3-3',
      starters: _parseSlots(m['starters']),
      bench: _parseSlots(m['bench']),
      createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
      lastUsedAt: (m['lastUsedAt'] as num?)?.toInt() ?? 0,
      appId: m['appId']?.toString() ?? '',
    );
  }

  static List<StadiumLineupSlot> _parseSlots(dynamic raw) {
    if (raw is! List) return const [];
    final out = <StadiumLineupSlot>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(StadiumLineupSlot.fromMap(Map<dynamic, dynamic>.from(e)));
      }
    }
    return out;
  }

  Map<String, dynamic> toWriteMap() => {
        'name': name,
        'formation': formation,
        'starters': starters.map((e) => e.toWriteMap()).toList(),
        'bench': bench.map((e) => e.toWriteMap()).toList(),
        'createdAt': createdAt,
        'lastUsedAt': lastUsedAt,
        'appId': appId,
      };

  List<StadiumLineupSlot> get allSlots => [...starters, ...bench];

  @override
  List<Object?> get props =>
      [id, name, formation, starters, bench, createdAt, lastUsedAt, appId];
}
