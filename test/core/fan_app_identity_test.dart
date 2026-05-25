import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';

void main() {
  group('FanAppIdentity — سوبر أدمن عبر التطبيقين', () {
    test('البريد المعرّف في الكود يُعرَّف كسوبر أدمن', () {
      expect(
        FanAppIdentity.isCrossAppSuperAdmin('mostafareyad772@gmail.com'),
        isTrue,
      );
    });

    test('حالات الحافة: فراغات وحروف كبيرة', () {
      expect(
        FanAppIdentity.isCrossAppSuperAdmin('  MOSTAFAREYAD772@gmail.COM  '),
        isTrue,
      );
    });

    test('مستخدم عادي ليس سوبر أدمن', () {
      expect(FanAppIdentity.isCrossAppSuperAdmin('fan@example.com'), isFalse);
      expect(FanAppIdentity.isCrossAppSuperAdmin(null), isFalse);
      expect(FanAppIdentity.isCrossAppSuperAdmin(''), isFalse);
    });
  });

  group('normalizeEmail', () {
    test('إزالة الفراغات وتوحيد الحروف الصغيرة', () {
      expect(
        FanAppIdentity.normalizeEmail('  User@EXAMPLE.COM  '),
        'user@example.com',
      );
    });
  });

  group('رسائل القفل (initialAppLockMessageForStoredApp)', () {
    test('رسائل أهلي/زملك معروفة', () {
      expect(
        FanAppIdentity.initialAppLockMessageForStoredApp('ahly'),
        contains('أهلاوي'),
      );
      expect(
        FanAppIdentity.initialAppLockMessageForStoredApp('zamalek'),
        contains('زملك'),
      );
    });

    test('تطبيق غير معروف → رسالة افتراضية', () {
      final m = FanAppIdentity.initialAppLockMessageForStoredApp('other_club');
      expect(m, contains('تطبيق'));
      expect(m, isNot(contains('أهلاوي')));
    });
  });

  group('wrongAppMessageFor', () {
    test('أهلي وزمالك والافتراضي', () {
      expect(
        FanAppIdentity.wrongAppMessageFor('ahly'),
        contains('الأهلي'),
      );
      expect(
        FanAppIdentity.wrongAppMessageFor('zamalek'),
        contains('زملكاوي'),
      );
      final def = FanAppIdentity.wrongAppMessageFor('unknown');
      expect(def, contains('تطبيق'));
    });
  });

  group('ثوابت الهوية', () {
    test('registryAppId يطابق أحد التطبيقين المعتمدين', () {
      expect(
        FanAppIdentity.registryAppId,
        anyOf('zamalek', 'ahly'),
      );
    });
  });
}
