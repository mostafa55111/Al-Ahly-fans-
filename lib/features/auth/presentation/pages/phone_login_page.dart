import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/app_shell.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/cubit/auth_cubit.dart';

/// شاشة تسجيل الدخول برقم الهاتف + إدخال كود OTP
class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _countryCode = '+20'; // مصر افتراضياً

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendCode() {
    var phone = _phoneController.text.trim();
    if (phone.startsWith('0')) {
      // Firebase expects international format without leading local zero.
      phone = phone.substring(1);
    }
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رقم هاتف صحيح')),
      );
      return;
    }
    final fullPhone = '$_countryCode$phone';
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().sendPhoneCode(fullPhone);
  }

  void _verifyCode() {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كود التحقق يتكون من 6 أرقام')),
      );
      return;
    }
    context.read<AuthCubit>().verifyPhoneCode(code);
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
        } else if (state.status == AuthStatus.codeSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال كود التحقق إلى هاتفك'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('تسجيل الدخول بالهاتف'),
        ),
        body: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isLoading = state.status == AuthStatus.loading;
              final hasCodeSent =
                  state.status == AuthStatus.codeSent || state.verificationId != null;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 26, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.royalRed, AppColors.darkRed],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalRed.withValues(alpha: 0.45),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        size: 60,
                        color: Colors.white,
                      ),
                    ).asCenter(),
                    const SizedBox(height: 26),
                    Text(
                      hasCodeSent
                          ? 'أدخل كود التحقق المُرسَل إلى ${state.phoneNumber ?? ''}'
                          : 'أدخل رقم هاتفك وسنرسل كود تحقق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (!hasCodeSent) _buildPhoneField() else _buildOtpField(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: isLoading
                            ? null
                            : (hasCodeSent ? _verifyCode : _sendCode),
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
                            : Text(
                                hasCodeSent ? 'تأكيد الكود' : 'إرسال الكود',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    if (hasCodeSent) ...[
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: isLoading ? null : _sendCode,
                        child: const Text(
                          'إعادة إرسال الكود',
                          style: TextStyle(color: AppColors.luminousGold),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C21),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2D33)),
          ),
          child: DropdownButton<String>(
            value: _countryCode,
            dropdownColor: AppColors.darkBlack,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: '+20', child: Text('🇪🇬 +20')),
              DropdownMenuItem(value: '+966', child: Text('🇸🇦 +966')),
              DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
              DropdownMenuItem(value: '+965', child: Text('🇰🇼 +965')),
              DropdownMenuItem(value: '+974', child: Text('🇶🇦 +974')),
            ],
            style: const TextStyle(color: Colors.white, fontSize: 15),
            onChanged: (v) {
              if (v != null) setState(() => _countryCode = v);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'رقم الهاتف',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpField() {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          letterSpacing: 8,
          fontWeight: FontWeight.bold),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        counterText: '',
        hintText: '______',
      ),
    );
  }
}

extension _CenterExtension on Widget {
  Widget asCenter() => Center(child: this);
}
