import 'package:equatable/equatable.dart';

/// هوية تكتيكية قابلة للتوسع — ليست لقطة جلسة بل نموذج مجال مستقبلي.
class StadiumTacticalIdentity extends Equatable {
  const StadiumTacticalIdentity({
    this.schemaVersion = currentSchemaVersion,
    this.tacticalPhilosophy = '',
    this.transitionsProfile = '',
    this.atmospherePreset = '',
    this.stadiumTone = '',
    this.rivalryMode = '',
    this.emergencyBenchLogic = '',
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String tacticalPhilosophy;
  final String transitionsProfile;
  final String atmospherePreset;
  final String stadiumTone;
  final String rivalryMode;
  final String emergencyBenchLogic;

  factory StadiumTacticalIdentity.fromMap(Map<dynamic, dynamic>? m) {
    if (m == null || m.isEmpty) return const StadiumTacticalIdentity();
    return StadiumTacticalIdentity(
      schemaVersion: (m['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
      tacticalPhilosophy: m['tacticalPhilosophy']?.toString() ?? '',
      transitionsProfile: m['transitionsProfile']?.toString() ?? '',
      atmospherePreset: m['atmospherePreset']?.toString() ?? '',
      stadiumTone: m['stadiumTone']?.toString() ?? '',
      rivalryMode: m['rivalryMode']?.toString() ?? '',
      emergencyBenchLogic: m['emergencyBenchLogic']?.toString() ?? '',
    );
  }

  /// يبني هوية من حقول الجلسة الحالية (جسر RTDB → مجال مستقبلي).
  factory StadiumTacticalIdentity.fromSessionContext({
    required String formation,
    required String sessionType,
    required String opponent,
    required String fxLevel,
    required String crowdProfile,
    required String stadiumTheme,
    required String overlaysProfile,
  }) {
    return StadiumTacticalIdentity(
      tacticalPhilosophy: _philosophyForFormation(formation),
      transitionsProfile: overlaysProfile.isNotEmpty ? overlaysProfile : 'default',
      atmospherePreset: crowdProfile.isNotEmpty ? crowdProfile : 'standard',
      stadiumTone: stadiumTheme.isNotEmpty ? stadiumTheme : 'default',
      rivalryMode: _rivalryFor(opponent, sessionType, crowdProfile),
      emergencyBenchLogic: 'standard_rotation',
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'schemaVersion': schemaVersion,
        'tacticalPhilosophy': tacticalPhilosophy,
        'transitionsProfile': transitionsProfile,
        'atmospherePreset': atmospherePreset,
        'stadiumTone': stadiumTone,
        'rivalryMode': rivalryMode,
        'emergencyBenchLogic': emergencyBenchLogic,
      };

  /// تطبيق على حقول `active_match` المعروفة اليوم.
  ({String crowdProfile, String stadiumTheme, String overlaysProfile}) sessionFields() {
    return (
      crowdProfile: atmospherePreset.isNotEmpty ? atmospherePreset : 'standard',
      stadiumTheme: stadiumTone.isNotEmpty ? stadiumTone : 'default',
      overlaysProfile: transitionsProfile.isNotEmpty ? transitionsProfile : 'default',
    );
  }

  static String _philosophyForFormation(String formation) {
    switch (formation.trim()) {
      case '4-2-3-1':
        return 'control_wide';
      case '3-5-2':
        return 'wing_overload';
      case '4-3-3':
      default:
        return 'balanced_press';
    }
  }

  static String _rivalryFor(String opponent, String sessionType, String crowd) {
    final o = opponent.toLowerCase();
    if (o.contains('ديربي') || o.contains('derby') || crowd.contains('derby')) {
      return 'derby_max';
    }
    if (sessionType == 'cup') return 'cup_intensity';
    return 'league_standard';
  }

  StadiumTacticalIdentity copyWith({
    int? schemaVersion,
    String? tacticalPhilosophy,
    String? transitionsProfile,
    String? atmospherePreset,
    String? stadiumTone,
    String? rivalryMode,
    String? emergencyBenchLogic,
  }) {
    return StadiumTacticalIdentity(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      tacticalPhilosophy: tacticalPhilosophy ?? this.tacticalPhilosophy,
      transitionsProfile: transitionsProfile ?? this.transitionsProfile,
      atmospherePreset: atmospherePreset ?? this.atmospherePreset,
      stadiumTone: stadiumTone ?? this.stadiumTone,
      rivalryMode: rivalryMode ?? this.rivalryMode,
      emergencyBenchLogic: emergencyBenchLogic ?? this.emergencyBenchLogic,
    );
  }

  @override
  List<Object?> get props => [
        schemaVersion,
        tacticalPhilosophy,
        transitionsProfile,
        atmospherePreset,
        stadiumTone,
        rivalryMode,
        emergencyBenchLogic,
      ];
}
