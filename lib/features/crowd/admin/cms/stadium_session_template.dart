import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_lineup_slot.dart';

/// قالب جلسة — يُطبَّق على `active_match` + اختياري تشكيلة من المكتبة.
class StadiumSessionTemplate extends Equatable {
  const StadiumSessionTemplate({
    required this.id,
    required this.name,
    required this.formation,
    this.sessionType = 'league',
    this.defaultTitle = '',
    this.opponent = '',
    this.fxLevel = 'warm',
    this.crowdProfile = 'standard',
    this.stadiumTheme = 'default',
    this.lineupSlots = const [],
    this.isBuiltin = false,
    this.updatedAt = 0,
  });

  final String id;
  final String name;
  final String formation;
  final String sessionType;
  final String defaultTitle;
  final String opponent;
  final String fxLevel;
  final String crowdProfile;
  final String stadiumTheme;
  final List<StadiumLineupSlot> lineupSlots;
  final bool isBuiltin;
  final int updatedAt;

  factory StadiumSessionTemplate.fromMap(String id, Map<dynamic, dynamic> m) {
    final slotsRaw = m['lineupSlots'];
    final slots = <StadiumLineupSlot>[];
    if (slotsRaw is List) {
      for (final e in slotsRaw) {
        if (e is Map) {
          slots.add(StadiumLineupSlot.fromMap(Map<dynamic, dynamic>.from(e)));
        }
      }
    }
    return StadiumSessionTemplate(
      id: id,
      name: m['name']?.toString() ?? '',
      formation: m['formation']?.toString() ?? '4-3-3',
      sessionType: m['sessionType']?.toString() ?? 'league',
      defaultTitle: m['defaultTitle']?.toString() ?? '',
      opponent: m['opponent']?.toString() ?? '',
      fxLevel: m['fxLevel']?.toString() ?? 'warm',
      crowdProfile: m['crowdProfile']?.toString() ?? 'standard',
      stadiumTheme: m['stadiumTheme']?.toString() ?? 'default',
      lineupSlots: slots,
      isBuiltin: m['isBuiltin'] == true || m['isBuiltin'] == 1,
      updatedAt: (m['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'name': name,
        'formation': formation,
        'sessionType': sessionType,
        'defaultTitle': defaultTitle,
        'opponent': opponent,
        'fxLevel': fxLevel,
        'crowdProfile': crowdProfile,
        'stadiumTheme': stadiumTheme,
        'lineupSlots': lineupSlots.map((e) => e.toWriteMap()).toList(),
        'isBuiltin': isBuiltin,
        'updatedAt': updatedAt,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        formation,
        sessionType,
        defaultTitle,
        opponent,
        fxLevel,
        crowdProfile,
        stadiumTheme,
        lineupSlots,
        isBuiltin,
        updatedAt,
      ];
}

/// قوالب جاهزة — لا تُكتب RTDB إلا عند حفظ نسخة مخصصة.
List<StadiumSessionTemplate> builtinStadiumSessionTemplates(String clubTag) {
  final home = clubTag == 'ahly' ? 'الأهلي' : 'الزمالك';
  return [
    StadiumSessionTemplate(
      id: 'builtin_home',
      name: '$home — داخل الأرض',
      formation: '4-3-3',
      sessionType: 'league',
      defaultTitle: 'مباراة داخل الأرض',
      fxLevel: 'warm',
      crowdProfile: 'home_standard',
      stadiumTheme: 'home_classic',
      isBuiltin: true,
    ),
    StadiumSessionTemplate(
      id: 'builtin_big',
      name: 'أجواء مباراة كبيرة',
      formation: '4-2-3-1',
      sessionType: 'league',
      defaultTitle: 'مباراة كبيرة',
      fxLevel: 'hot',
      crowdProfile: 'big_match',
      stadiumTheme: 'intense_spotlight',
      isBuiltin: true,
    ),
    StadiumSessionTemplate(
      id: 'builtin_derby',
      name: 'ليلة ديربي',
      formation: '4-3-3',
      sessionType: 'league',
      defaultTitle: 'ليلة الديربي',
      opponent: 'ديربي',
      fxLevel: 'inferno',
      crowdProfile: 'derby_night',
      stadiumTheme: 'derby_fire',
      isBuiltin: true,
    ),
    StadiumSessionTemplate(
      id: 'builtin_cup',
      name: 'نهائي كأس',
      formation: '3-5-2',
      sessionType: 'cup',
      defaultTitle: 'نهائي الكأس',
      fxLevel: 'hot',
      crowdProfile: 'cup_final',
      stadiumTheme: 'cup_celebration',
      isBuiltin: true,
    ),
  ];
}
