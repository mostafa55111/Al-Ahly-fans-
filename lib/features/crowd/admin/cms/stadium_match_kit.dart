import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_lineup_slot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_tactical_identity.dart';

/// حزمة تكتيكية قابلة لإعادة الاستخدام — تشكيلة + هوية + أجواء.
class StadiumMatchKit extends Equatable {
  const StadiumMatchKit({
    required this.id,
    required this.name,
    required this.formation,
    required this.starterSlots,
    this.benchSlots = const [],
    this.tacticalIdentity = const StadiumTacticalIdentity(),
    this.defaultTitle = '',
    this.opponent = '',
    this.sessionType = 'league',
    this.fxLevel = 'warm',
    this.crowdProfile = 'standard',
    this.stadiumTheme = 'default',
    this.overlaysProfile = 'default',
    this.savedAt = 0,
  });

  final String id;
  final String name;
  final String formation;
  final List<StadiumLineupSlot> starterSlots;
  final List<StadiumLineupSlot> benchSlots;
  final StadiumTacticalIdentity tacticalIdentity;
  final String defaultTitle;
  final String opponent;
  final String sessionType;
  final String fxLevel;
  final String crowdProfile;
  final String stadiumTheme;
  final String overlaysProfile;
  final int savedAt;

  List<StadiumLineupSlot> get slots => starterSlots;

  factory StadiumMatchKit.fromMap(String id, Map<dynamic, dynamic> m) {
    List<StadiumLineupSlot> parseList(dynamic raw) {
      final out = <StadiumLineupSlot>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            out.add(StadiumLineupSlot.fromMap(Map<dynamic, dynamic>.from(e)));
          }
        }
      }
      return out;
    }

    final starters = parseList(m['starterSlots']);
    final legacy = starters.isEmpty ? parseList(m['slots']) : starters;
    final identityRaw = m['tacticalIdentity'];
    final identity = identityRaw is Map
        ? StadiumTacticalIdentity.fromMap(Map<dynamic, dynamic>.from(identityRaw))
        : StadiumTacticalIdentity.fromSessionContext(
            formation: m['formation']?.toString() ?? '4-3-3',
            sessionType: m['sessionType']?.toString() ?? 'league',
            opponent: m['opponent']?.toString() ?? '',
            fxLevel: m['fxLevel']?.toString() ?? 'warm',
            crowdProfile: m['crowdProfile']?.toString() ?? 'standard',
            stadiumTheme: m['stadiumTheme']?.toString() ?? 'default',
            overlaysProfile: m['overlaysProfile']?.toString() ?? 'default',
          );

    return StadiumMatchKit(
      id: id,
      name: m['name']?.toString() ?? '',
      formation: m['formation']?.toString() ?? '4-3-3',
      starterSlots: legacy,
      benchSlots: parseList(m['benchSlots']),
      tacticalIdentity: identity,
      defaultTitle: m['defaultTitle']?.toString() ?? m['title']?.toString() ?? '',
      opponent: m['opponent']?.toString() ?? '',
      sessionType: m['sessionType']?.toString() ?? 'league',
      fxLevel: m['fxLevel']?.toString() ?? 'warm',
      crowdProfile: m['crowdProfile']?.toString() ?? identity.atmospherePreset,
      stadiumTheme: m['stadiumTheme']?.toString() ?? identity.stadiumTone,
      overlaysProfile: m['overlaysProfile']?.toString() ?? identity.transitionsProfile,
      savedAt: (m['savedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toWriteMap() {
    final session = tacticalIdentity.sessionFields();
    return {
      'name': name,
      'formation': formation,
      'starterSlots': starterSlots.map((e) => e.toWriteMap()).toList(),
      'benchSlots': benchSlots.map((e) => e.toWriteMap()).toList(),
      'slots': starterSlots.map((e) => e.toWriteMap()).toList(),
      'tacticalIdentity': tacticalIdentity.toWriteMap(),
      'defaultTitle': defaultTitle,
      'opponent': opponent,
      'sessionType': sessionType,
      'fxLevel': fxLevel,
      'crowdProfile': session.crowdProfile,
      'stadiumTheme': session.stadiumTheme,
      'overlaysProfile': session.overlaysProfile,
      'savedAt': savedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        formation,
        starterSlots,
        benchSlots,
        tacticalIdentity,
        defaultTitle,
        opponent,
        sessionType,
        fxLevel,
        crowdProfile,
        stadiumTheme,
        overlaysProfile,
        savedAt,
      ];
}

typedef StadiumSavedLineup = StadiumMatchKit;
