import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// جلسة مالك محلية آمنة — بدون تخزين كلمة مرور.
abstract final class OwnerSessionTimeoutPolicy {
  static const Duration inactivityLimit = Duration(hours: 12);
}

/// يحفظ بيانات جلسة المالك (UID + نشاط) في التخزين الآمن.
class OwnerSecureSession {
  OwnerSecureSession({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kUid = 'owner_session_uid';
  static const _kEmail = 'owner_session_email';
  static const _kLastActivity = 'owner_session_last_activity_ms';
  static const _kStarted = 'owner_session_started_ms';

  Future<void> open({
    required String uid,
    required String email,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _storage.write(key: _kUid, value: uid);
    await _storage.write(key: _kEmail, value: email.trim().toLowerCase());
    await _storage.write(key: _kLastActivity, value: '$now');
    await _storage.write(key: _kStarted, value: '$now');
  }

  Future<void> touch() async {
    final uid = await _storage.read(key: _kUid);
    if (uid == null || uid.isEmpty) return;
    await _storage.write(
      key: _kLastActivity,
      value: '${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<bool> isActiveForUid(String? uid) async {
    if (uid == null || uid.isEmpty) return false;
    final stored = await _storage.read(key: _kUid);
    if (stored == null || stored != uid) return false;
    return !(await isExpired());
  }

  Future<bool> isExpired({
    Duration limit = OwnerSessionTimeoutPolicy.inactivityLimit,
    int? nowMs,
  }) async {
    final raw = await _storage.read(key: _kLastActivity);
    if (raw == null || raw.isEmpty) return true;
    final last = int.tryParse(raw);
    if (last == null) return true;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return isExpiredAt(lastActivityMs: last, nowMs: now, limit: limit);
  }

  /// منطق انتهاء الجلسة — قابل للاختبار بدون تخزين.
  static bool isExpiredAt({
    required int lastActivityMs,
    required int nowMs,
    Duration limit = OwnerSessionTimeoutPolicy.inactivityLimit,
  }) {
    return nowMs - lastActivityMs > limit.inMilliseconds;
  }

  Future<String?> storedEmail() => _storage.read(key: _kEmail);

  Future<void> clear() async {
    await _storage.delete(key: _kUid);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kLastActivity);
    await _storage.delete(key: _kStarted);
  }
}
