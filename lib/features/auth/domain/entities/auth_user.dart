import 'package:equatable/equatable.dart';

/// كيان المستخدم (Entity) في طبقة Domain
/// يحتوي على البيانات الأساسية للمستخدم فقط بدون أي تفاصيل Firebase
class AuthUser extends Equatable {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;

  const AuthUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
  });

  @override
  List<Object?> get props =>
      [uid, email, phoneNumber, displayName, photoUrl, isEmailVerified];
}
