import 'package:flutter/foundation.dart';

/// لقطة جو جماعي حي — تُحسب كل إطار بدون [ChangeNotifier] إضافي.
@immutable
class CrowdLiveAtmosphere {
  const CrowdLiveAtmosphere({
    this.emotionTemperature = 0.2,
    this.crowdDirectionX = 0,
    this.crowdPressure = 0,
    this.energyWave01 = 0,
    this.density01 = 0.35,
    this.collectiveBreath01 = 0.5,
    this.atmosphereMemory01 = 0,
    this.gravityNx = 0.5,
    this.gravityNy = 0.5,
    this.runtimeScale = 1,
  });

  /// حرارة المشاعر الجماعية 0..1.
  final double emotionTemperature;

  /// اتجاه الموجة الأفقي -1..1.
  final double crowdDirectionX;

  /// ضغط الجمهور 0..1.
  final double crowdPressure;

  /// موجة طاقة رئيسية 0..1.
  final double energyWave01;

  /// كثافة حضور محاكاة 0..1.
  final double density01;

  /// نبض جماعي متزامن 0..1.
  final double collectiveBreath01;

  /// ذاكرة مزاج تبقى بعد الأحداث 0..1.
  final double atmosphereMemory01;

  /// جاذبية اجتماعية — موضع المتصدر المعيّن 0..1.
  final double gravityNx;
  final double gravityNy;

  /// مقياس وقت التشغيل (guards + budget).
  final double runtimeScale;

  static const CrowdLiveAtmosphere zero = CrowdLiveAtmosphere();
}
