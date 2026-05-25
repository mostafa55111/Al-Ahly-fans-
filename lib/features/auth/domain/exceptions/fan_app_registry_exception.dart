/// خطأ تعارُض: الإيميل مُسوَّى أساسًا على التطبيق الآخر في سجلّ Firestore الموحّد
class FanAppRegistryException implements Exception {
  FanAppRegistryException(this.message);

  /// نص رسالة الواجهة (عربي)
  final String message;

  @override
  String toString() => message;
}
