import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/entities/auth_user.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

/// كيوبت المصادقة - مسؤول عن:
/// 1. الاستماع لحالة تسجيل الدخول (authStateChanges)
/// 2. تنفيذ عمليات تسجيل الدخول/الخروج
/// 3. التحقق من OTP للهاتف
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AuthUser?>? _authSub;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    _listenToAuthChanges();
  }

  /// الاستماع لتغييرات المستخدم من Firebase
  void _listenToAuthChanges() {
    _authSub = _authRepository.authStateChanges.listen((user) {
      if (user == null) {
        emit(const AuthState.unauthenticated());
      } else {
        emit(AuthState.authenticated(user));
      }
    });
  }

  /// التحقق من وجود مستخدم مسجّل دخول بعد انتهاء الشاشة الترحيبية
  Future<void> checkInitialAuthState() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthState.loading());
    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(_extractErrorMessage(e)));
    }
  }

  /// إنشاء حساب جديد بالبريد
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    emit(const AuthState.loading());
    try {
      final user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(_extractErrorMessage(e)));
    }
  }

  /// تسجيل الدخول بحساب Google
  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(_extractErrorMessage(e)));
    }
  }

  /// إرسال كود التحقق على الهاتف
  Future<void> sendPhoneCode(String phoneNumber) async {
    emit(const AuthState.loading());
    try {
      final verificationId = await _authRepository.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
      );
      emit(AuthState.codeSent(
        verificationId: verificationId,
        phoneNumber: phoneNumber,
      ));
    } catch (e) {
      emit(AuthState.error(_extractErrorMessage(e)));
    }
  }

  /// تأكيد كود OTP
  Future<void> verifyPhoneCode(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      emit(const AuthState.error('لم يتم إرسال كود التحقق بعد'));
      return;
    }
    emit(const AuthState.loading());
    try {
      final user = await _authRepository.verifyPhoneCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(_extractErrorMessage(e)));
    }
  }

  /// إرسال رابط إعادة تعيين كلمة المرور
  Future<void> sendPasswordResetEmail(String email) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(_extractErrorMessage(e)));
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      debugPrint('AuthCubit signOut error: $e');
      emit(const AuthState.unauthenticated());
    }
  }

  String _extractErrorMessage(Object error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
