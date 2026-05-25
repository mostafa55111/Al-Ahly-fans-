import 'package:flutter/material.dart';

/// أوضاع دمج طبقة الـ overlay المتحرك فوق الكرت (لا تُستبدل [BlendMode] الخاص بـ Flutter).
enum MatchCardBlendMode {
  normal,
  screen,
  additive,
  softLight,
  overlay,
}

MatchCardBlendMode parseMatchCardBlendMode(String raw) {
  final t = raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '');
  switch (t) {
    case '':
    case 'normal':
    case 'srcover':
      return MatchCardBlendMode.normal;
    case 'screen':
      return MatchCardBlendMode.screen;
    case 'additive':
    case 'plus':
      return MatchCardBlendMode.additive;
    case 'softlight':
    case 'soft_light':
      return MatchCardBlendMode.softLight;
    case 'overlay':
      return MatchCardBlendMode.overlay;
    default:
      return MatchCardBlendMode.screen;
  }
}

String matchCardBlendModeWire(MatchCardBlendMode m) {
  switch (m) {
    case MatchCardBlendMode.normal:
      return 'normal';
    case MatchCardBlendMode.screen:
      return 'screen';
    case MatchCardBlendMode.additive:
      return 'additive';
    case MatchCardBlendMode.softLight:
      return 'softLight';
    case MatchCardBlendMode.overlay:
      return 'overlay';
  }
}

String matchCardBlendModeLabelAr(MatchCardBlendMode m) {
  switch (m) {
    case MatchCardBlendMode.normal:
      return 'عادي';
    case MatchCardBlendMode.screen:
      return 'Screen';
    case MatchCardBlendMode.additive:
      return 'Additive';
    case MatchCardBlendMode.softLight:
      return 'Soft Light';
    case MatchCardBlendMode.overlay:
      return 'Overlay';
  }
}

/// يلف الـ [child] بطبقة [ColorFilter] قريبة من وضع الدمج المطلوب.
Widget matchCardApplyBlendMode(MatchCardBlendMode mode, Widget child) {
  switch (mode) {
    case MatchCardBlendMode.normal:
      return child;
    case MatchCardBlendMode.screen:
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.screen),
        child: child,
      );
    case MatchCardBlendMode.additive:
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.plus),
        child: child,
      );
    case MatchCardBlendMode.softLight:
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.softLight),
        child: child,
      );
    case MatchCardBlendMode.overlay:
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.overlay),
        child: child,
      );
  }
}
