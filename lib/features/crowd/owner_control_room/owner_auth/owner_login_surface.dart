import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_auth_service.dart';

/// واجهة دخول المالك — سينمائية، بدون Firebase UI الافتراضي.
class OwnerLoginSurface extends StatefulWidget {
  const OwnerLoginSurface({
    super.key,
    required this.onAuthenticated,
  });

  final VoidCallback onAuthenticated;

  @override
  State<OwnerLoginSurface> createState() => _OwnerLoginSurfaceState();
}

class _OwnerLoginSurfaceState extends State<OwnerLoginSurface> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = getIt<OwnerAuthService>();
    final result = await auth.signIn(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    switch (result) {
      case OwnerSignInResult.success:
        widget.onAuthenticated();
      case OwnerSignInResult.invalidCredentials:
        setState(() {
          _busy = false;
          _error = 'بيانات الدخول غير صحيحة';
        });
      case OwnerSignInResult.notOwner:
        setState(() {
          _busy = false;
          _error = 'هذا الحساب غير مصرّح';
        });
      case OwnerSignInResult.networkError:
        setState(() {
          _busy = false;
          _error = 'تعذّر الاتصال — حاول مجدداً';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ControlRoomTheme.of(null);
    final primary = theme.identity.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withValues(alpha: 0.22),
              theme.scaffold,
              const Color(0xFF050506),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.sports_soccer, size: 52, color: primary),
                    const SizedBox(height: 16),
                    Text(
                      'غرفة التحكم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.primaryText,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'دخول المالك فقط — البث والتشغيل',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.secondaryText, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: theme.panelDecoration(radius: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(
                            theme: theme,
                            controller: _email,
                            label: 'البريد الإلكتروني',
                            keyboard: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 14),
                          _field(
                            theme: theme,
                            controller: _password,
                            label: 'كلمة المرور',
                            obscure: _obscure,
                            autofillHints: const [AutofillHints.password],
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.secondaryText,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'دخول غرفة التحكم',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required ControlRoomTheme theme,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboard,
    bool obscure = false,
    List<String>? autofillHints,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      autofillHints: autofillHints,
      style: TextStyle(color: theme.primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.secondaryText),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.identity.primaryColor),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}
