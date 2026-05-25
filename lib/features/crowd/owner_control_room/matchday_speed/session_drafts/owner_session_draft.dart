import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_lineup_slot.dart';

enum OwnerSessionDraftState {
  draft,
  ready,
  live,
  archived;

  static OwnerSessionDraftState parse(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'ready':
        return OwnerSessionDraftState.ready;
      case 'live':
        return OwnerSessionDraftState.live;
      case 'archived':
        return OwnerSessionDraftState.archived;
      default:
        return OwnerSessionDraftState.draft;
    }
  }

  String get wire => name;
}

/// مسودة جلسة — تجهيز قبل المباراة.
class OwnerSessionDraft extends Equatable {
  const OwnerSessionDraft({
    required this.id,
    required this.formation,
    this.lineup = const [],
    this.bench = const [],
    this.durationMinutes = 60,
    this.notes = '',
    this.state = OwnerSessionDraftState.draft,
    this.updatedAt = 0,
    this.appId = '',
  });

  final String id;
  final String formation;
  final List<StadiumLineupSlot> lineup;
  final List<StadiumLineupSlot> bench;
  final int durationMinutes;
  final String notes;
  final OwnerSessionDraftState state;
  final int updatedAt;
  final String appId;

  factory OwnerSessionDraft.fromMap(String id, Map<dynamic, dynamic> m) {
    return OwnerSessionDraft(
      id: id,
      formation: m['formation']?.toString() ?? '4-3-3',
      lineup: OwnerMatchTemplateSlots.parse(m['lineup']),
      bench: OwnerMatchTemplateSlots.parse(m['bench']),
      durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 60,
      notes: m['notes']?.toString() ?? '',
      state: OwnerSessionDraftState.parse(m['state']?.toString()),
      updatedAt: (m['updatedAt'] as num?)?.toInt() ?? 0,
      appId: m['appId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'formation': formation,
        'lineup': lineup.map((e) => e.toWriteMap()).toList(),
        'bench': bench.map((e) => e.toWriteMap()).toList(),
        'durationMinutes': durationMinutes,
        'notes': notes,
        'state': state.wire,
        'updatedAt': updatedAt,
        'appId': appId,
      };

  @override
  List<Object?> get props => [
        id,
        formation,
        lineup,
        bench,
        durationMinutes,
        notes,
        state,
        updatedAt,
        appId,
      ];
}

abstract final class OwnerMatchTemplateSlots {
  static List<StadiumLineupSlot> parse(dynamic raw) {
    if (raw is! List) return const [];
    final out = <StadiumLineupSlot>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(StadiumLineupSlot.fromMap(Map<dynamic, dynamic>.from(e)));
      }
    }
    return out;
  }
}
