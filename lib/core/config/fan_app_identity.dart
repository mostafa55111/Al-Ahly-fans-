/// هوية التطبيق في سجلّ Firestore الموحّد (مشروع gomhor-al-ahly واحد مع تطبيقين).
/// مجموعة [fan_app_registry] تربط كل بريد بـ homeApp لتفادي خلط حساب الأهلي/الزمالك.
class FanAppIdentity {
  FanAppIdentity._();

  /// هذا الملف لبناء جمهور الأهلي — لا تغيّر القيمة إلا بتنسيق بين التطبيقين
  static const String registryAppId = 'ahly';

  static const String _ahly = 'ahly';
  static const String _zamalek = 'zamalek';

  /// حساب إداري يُسمح له بالدخول للتطبيقين دون قفل [initial_app].
  static const String crossAppSuperAdminEmail = 'mostafareyad772@gmail.com';

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isCrossAppSuperAdmin(String? email) {
    if (email == null || email.isEmpty) return false;
    return normalizeEmail(email) == normalizeEmail(crossAppSuperAdminEmail);
  }

  /// رسالة القفل عند وجود [initial_app] لمشجّع التطبيق الآخر.
  static String initialAppLockMessageForStoredApp(String storedInitialApp) {
    switch (storedInitialApp) {
      case _ahly:
        return 'أنت أهلاوي انتقل إلى تطبيقك المخصص';
      case _zamalek:
        return 'أنت زملكاوي انتقل إلى تطبيقك المخصص';
      default:
        return 'هذا الحساب مخصص لتطبيق آخر؛ استخدم التطبيق الصحيح.';
    }
  }

  static String wrongAppMessageFor(String registeredOtherHomeApp) {
    switch (registeredOtherHomeApp) {
      case _ahly:
        return 'هذا الإيميل مسجل من قبل في تطبيق جمهور الأهلي، انتقل إليه';
      case _zamalek:
        return 'هذا الإيميل مسجل من قبل في تطبيق زملكاوي، انتقل إليه';
      default:
        return 'هذا الإيميل مسجّل من قبل على تطبيق آخر؛ استخدم التطبيق الصحيح.';
    }
  }
}
