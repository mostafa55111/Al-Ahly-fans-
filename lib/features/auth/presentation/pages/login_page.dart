import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/app_shell.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/phone_login_page.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/register_page.dart';

/// شاشة تسجيل الدخول الموحّدة
/// تدعم: البريد + كلمة المرور، حساب Google، رقم الهاتف
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginWithEmail() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _loginWithGoogle() {
    context.read<AuthCubit>().signInWithGoogle();
  }

  void _goToPhoneLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneLoginPage()),
    );
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _showForgotPasswordSheet() {
    final controller = TextEditingController(text: _emailController.text);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'استعادة كلمة المرور',
              style: TextStyle(
                color: AppColors.luminousGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final email = controller.text.trim();
                if (email.isEmpty) return;
                context.read<AuthCubit>().sendPasswordResetEmail(email);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال رابط إعادة تعيين كلمة المرور'),
                  ),
                );
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AppShell()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'خطأ غير متوقع'),
              backgroundColor: AppColors.royalRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isLoading = state.status == AuthStatus.loading;
              return Stack(
                children: [
                  _buildBackgroundDecor(),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: _buildHeader(),
                          ),
                          const SizedBox(height: 36),
                          FadeInUp(
                            delay: const Duration(milliseconds: 100),
                            child: _buildEmailField(),
                          ),
                          const SizedBox(height: 14),
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: _buildPasswordField(),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _showForgotPasswordSheet,
                              child: const Text(
                                'نسيت كلمة المرور؟',
                                style: TextStyle(
                                    color: AppColors.luminousGold,
                                    fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FadeInUp(
                            delay: const Duration(milliseconds: 300),
                            child: _buildLoginButton(isLoading),
                          ),
                          const SizedBox(height: 26),
                          _buildOrDivider(),
                          const SizedBox(height: 22),
                          FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            child: _buildSocialButtons(),
                          ),
                          const SizedBox(height: 32),
                          FadeInUp(
                            delay: const Duration(milliseconds: 500),
                            child: _buildRegisterRow(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// خلفية بسيطة بدوائر متوهجة (ذهبي + أحمر)
  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.royalRed.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -90,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.luminousGold.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// شعار + عنوان الترحيب
  Widget _buildHeader() {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.luminousGold, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalRed.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.royalRed,
                  child: const Icon(
                    Icons.shield,
                    color: AppColors.luminousGold,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'أهلاً بعودتك',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'سجّل دخولك لمواكبة نادي القرن',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'البريد الإلكتروني',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
        if (!v.contains('@')) return 'صيغة البريد غير صحيحة';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: Colors.white),
      onFieldSubmitted: (_) => _loginWithEmail(),
      decoration: InputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.luminousGold,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
        if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
        return null;
      },
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? null : _loginWithEmail,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.royalRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'أو تابع عن طريق',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: Icons.g_mobiledata_rounded,
            label: 'Google',
            iconColor: Colors.white,
            onTap: _loginWithGoogle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            icon: Icons.phone_android_rounded,
            label: 'الهاتف',
            iconColor: AppColors.luminousGold,
            onTap: _goToPhoneLogin,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        TextButton(
          onPressed: _goToRegister,
          child: const Text(
            'سجّل الآن',
            style: TextStyle(
              color: AppColors.luminousGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// زر تسجيل دخول عبر وسيلة خارجية (Google / Phone)
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.luminousGold.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
