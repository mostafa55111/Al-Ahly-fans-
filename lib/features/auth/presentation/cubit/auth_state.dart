part of 'auth_cubit.dart';

/// حالة المصادقة المختلفة
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  error,
  codeSent,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final String? verificationId;
  final String? phoneNumber;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.verificationId,
    this.phoneNumber,
  });

  const AuthState.unknown() : this();

  const AuthState.authenticated(AuthUser user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.error(String message)
      : this(status: AuthStatus.error, errorMessage: message);

  const AuthState.codeSent({
    required String verificationId,
    required String phoneNumber,
  }) : this(
          status: AuthStatus.codeSent,
          verificationId: verificationId,
          phoneNumber: phoneNumber,
        );

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    String? verificationId,
    String? phoneNumber,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, errorMessage, verificationId, phoneNumber];
}
