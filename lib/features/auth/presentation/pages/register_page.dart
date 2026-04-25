import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/app_shell.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/cubit/auth_cubit.dart';

/// شاشة إنشاء حساب جديد عن طريق البريد الإلكتروني
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
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
              content: Text(state.errorMessage ?? 'خطأ'),
              backgroundColor: AppColors.royalRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('إنشاء حساب جديد'),
        ),
        body: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isLoading = state.status == AuthStatus.loading;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 26, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'انضم لعائلة الأهلي',
                        style: TextStyle(
                          color: AppColors.luminousGold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'املأ البيانات لإنشاء حسابك',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 2) {
                            return 'أدخل اسمك (حرفين على الأقل)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'أدخل البريد';
                          }
                          if (!v.contains('@')) return 'صيغة البريد غير صحيحة';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.luminousGold,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return '6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: Colors.white),
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'كلمتا المرور غير متطابقتين';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.royalRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'إنشاء الحساب',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
