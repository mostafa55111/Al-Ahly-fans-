import 'package:gomhor_alahly_clean_new/features/auth/domain/entities/auth_user.dart';

/// واجهة المصادقة (Repository Interface)
/// Domain layer - لا تعرف شيء عن Firebase أو أي مصدر بيانات
abstract class AuthRepository {
  /// الحالة الحالية لتغيرات المستخدم (Stream)
  Stream<AuthUser?> get authStateChanges;

  /// المستخدم الحالي إذا كان مسجّل دخول
  AuthUser? get currentUser;

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// إنشاء حساب جديد بالبريد وكلمة المرور
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// تسجيل الدخول بحساب Google
  Future<AuthUser> signInWithGoogle();

  /// إرسال كود التحقق على رقم الهاتف
  /// يرجع verificationId ليتم استخدامه في تأكيد الكود
  Future<String> sendPhoneVerificationCode({
    required String phoneNumber,
  });

  /// تأكيد كود OTP للهاتف
  Future<AuthUser> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  /// إعادة تعيين كلمة المرور
  Future<void> sendPasswordResetEmail({required String email});

  /// تسجيل الخروج
  Future<void> signOut();
}
