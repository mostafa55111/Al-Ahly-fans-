import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/screens/main_navigation_screen.dart';
import 'package:animate_do/animate_do.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى ملء جميع الحقول")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في تسجيل الدخول: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/images/gold_pattern.png',
                  repeat: ImageRepeat.repeat,
                  errorBuilder: (c, e, s) => Container()),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/logo.png'),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    child: const Text(
                      "تسجيل الدخول",
                      style: TextStyle(
                          color: Color(0xFFC5A059),
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildTextField(_emailController,
                        "البريد الإلكتروني", Icons.email_outlined, false),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: _buildTextField(_passwordController, "كلمة المرور",
                        Icons.lock_outline, true),
                  ),
                  const SizedBox(height: 40),
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.red)
                        : GestureDetector(
                            onTap: _login,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "دخول",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "ليس لديك حساب؟ سجل الآن",
                        style:
                            TextStyle(color: Color(0xFFC5A059), fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      IconData icon, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFC5A059).withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: const Color(0xFFC5A059)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
