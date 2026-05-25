import 'package:flutter/foundation.dart';

/// أنواع طبقة الـ FX فوق صورة الكرت الجاهزة — لا تُعدّل أصل الصورة.
enum MatchCardOverlayType {
  none,
  redLightning,
  goldenAura,
  royalGlow,
  fireBurst,
  ultraPulse,
  neonWave,
  eagleEnergy,
  knightEnergy,
  glitchEnergy,
  legendaryStorm,
}

String matchCardOverlayTypeWire(MatchCardOverlayType t) => t.name;

/// تحليل قيمة [cardAnimatedOverlay] من RTDB أو لوحة الإدارة.
MatchCardOverlayType parseMatchCardOverlayType(String raw) {
  var t = raw.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
  if (t.isEmpty || t == 'none' || t == 'off' || t == '0') {
    return MatchCardOverlayType.none;
  }
  for (final e in MatchCardOverlayType.values) {
    final en = e.name.toLowerCase().replaceAll('_', '');
    if (t == en) return e;
  }
  // مرادفات شائعة
  const aliases = <String, MatchCardOverlayType>{
    'lightning': MatchCardOverlayType.redLightning,
    'electric': MatchCardOverlayType.redLightning,
    'gold': MatchCardOverlayType.goldenAura,
    'goldaura': MatchCardOverlayType.goldenAura,
    'royal': MatchCardOverlayType.royalGlow,
    'whiteglow': MatchCardOverlayType.royalGlow,
    'fire': MatchCardOverlayType.fireBurst,
    'burst': MatchCardOverlayType.fireBurst,
    'pulse': MatchCardOverlayType.ultraPulse,
    'ultra': MatchCardOverlayType.ultraPulse,
    'neon': MatchCardOverlayType.neonWave,
    'wave': MatchCardOverlayType.neonWave,
    'eagle': MatchCardOverlayType.eagleEnergy,
    'knight': MatchCardOverlayType.knightEnergy,
    'glitch': MatchCardOverlayType.glitchEnergy,
    'storm': MatchCardOverlayType.legendaryStorm,
    'legend': MatchCardOverlayType.legendaryStorm,
  };
  final a = aliases[t];
  if (a != null) return a;

  for (final e in MatchCardOverlayType.values) {
    if (e == MatchCardOverlayType.none) continue;
    if (t.contains(e.name.toLowerCase().replaceAll('_', ''))) return e;
  }
  return MatchCardOverlayType.none;
}

/// عندما يكون الحقل فارغاً نشتق نوعاً خفيفاً من [rarity] / [style] / [theme].
/// إذا كتب الأدمن `none` صراحةً لا نشتق شيئاً.
MatchCardOverlayType resolveMatchCardOverlayType({
  required String animatedOverlayRaw,
  required String rarity,
  required String style,
  required String theme,
}) {
  final explicit = animatedOverlayRaw.trim();
  final low = explicit.toLowerCase();
  if (low == 'none' || low == 'off' || low == '0') {
    return MatchCardOverlayType.none;
  }
  if (explicit.isNotEmpty) {
    return parseMatchCardOverlayType(explicit);
  }

  final r = rarity.toLowerCase().trim();
  final s = style.toLowerCase().trim();
  final th = theme.toLowerCase().trim();

  if (r == 'legendary' || r == 'mythic') return MatchCardOverlayType.legendaryStorm;
  if (r == 'epic') return MatchCardOverlayType.neonWave;
  if (s == 'ultra_red' || th == 'ahly_fire') return MatchCardOverlayType.redLightning;
  if (th == 'zamalek_royal' || s == 'royal_white' || th == 'royal_white') {
    return MatchCardOverlayType.royalGlow;
  }
  if (th.contains('zamalek')) return MatchCardOverlayType.knightEnergy;
  if (th.contains('ahly') || s.contains('ahly')) return MatchCardOverlayType.eagleEnergy;
  return MatchCardOverlayType.none;
}

String matchCardOverlayTypeLabelAr(MatchCardOverlayType t) {
  switch (t) {
    case MatchCardOverlayType.none:
      return 'بدون';
    case MatchCardOverlayType.redLightning:
      return 'برق أحمر';
    case MatchCardOverlayType.goldenAura:
      return 'هالة ذهبية';
    case MatchCardOverlayType.royalGlow:
      return 'توهج ملكي';
    case MatchCardOverlayType.fireBurst:
      return 'انفجار نار';
    case MatchCardOverlayType.ultraPulse:
      return 'نبض Ultra';
    case MatchCardOverlayType.neonWave:
      return 'موجة نيون';
    case MatchCardOverlayType.eagleEnergy:
      return 'طاقة نسر';
    case MatchCardOverlayType.knightEnergy:
      return 'طاقة فارس';
    case MatchCardOverlayType.glitchEnergy:
      return 'طاقة Glitch';
    case MatchCardOverlayType.legendaryStorm:
      return 'عاصفة أسطورية';
  }
}

/// عناصر القائمة للـ Dropdown (قيمة سلكية = enum.name).
@immutable
class MatchCardOverlayMenuItem {
  const MatchCardOverlayMenuItem(this.type, this.label);
  final MatchCardOverlayType type;
  final String label;
}

List<MatchCardOverlayMenuItem> get matchCardOverlayMenuItems => [
      for (final e in MatchCardOverlayType.values)
        MatchCardOverlayMenuItem(e, matchCardOverlayTypeLabelAr(e)),
    ];
