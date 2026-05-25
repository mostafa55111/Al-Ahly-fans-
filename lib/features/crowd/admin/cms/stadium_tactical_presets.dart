import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_tactical_identity.dart';

/// بذور هوية تكتيكية لقوالب الجلسة — تُدمج عند تطبيق القالب أو حفظ Kit.
class StadiumTacticalPresets {
  StadiumTacticalPresets._();

  static const home = StadiumTacticalIdentity(
    tacticalPhilosophy: 'balanced_press',
    transitionsProfile: 'smooth',
    atmospherePreset: 'home_standard',
    stadiumTone: 'home_classic',
    rivalryMode: 'league_standard',
    emergencyBenchLogic: 'standard_rotation',
  );

  static const bigMatch = StadiumTacticalIdentity(
    tacticalPhilosophy: 'control_wide',
    transitionsProfile: 'punchy',
    atmospherePreset: 'big_match',
    stadiumTone: 'intense_spotlight',
    rivalryMode: 'league_standard',
    emergencyBenchLogic: 'impact_subs',
  );

  static const derbyNight = StadiumTacticalIdentity(
    tacticalPhilosophy: 'balanced_press',
    transitionsProfile: 'staccato',
    atmospherePreset: 'derby_night',
    stadiumTone: 'derby_fire',
    rivalryMode: 'derby_max',
    emergencyBenchLogic: 'early_impact_sub',
  );

  static const cupFinal = StadiumTacticalIdentity(
    tacticalPhilosophy: 'wing_overload',
    transitionsProfile: 'celebration',
    atmospherePreset: 'cup_final',
    stadiumTone: 'cup_celebration',
    rivalryMode: 'cup_intensity',
    emergencyBenchLogic: 'defensive_lock',
  );

  static StadiumTacticalIdentity forTemplateId(String templateId) {
    switch (templateId) {
      case 'builtin_big':
        return bigMatch;
      case 'builtin_derby':
        return derbyNight;
      case 'builtin_cup':
        return cupFinal;
      case 'builtin_home':
      default:
        return home;
    }
  }
}
