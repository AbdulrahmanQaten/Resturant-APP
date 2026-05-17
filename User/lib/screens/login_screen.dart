import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'main_screen.dart';
import 'verify_email_screen.dart';
import '../widgets/theme_aware_image.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // ---===  دالة تسجيل الدخول الجديدة والآمنة  ===---
  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى ملء جميع الحقول.'), backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());

      final user = userCredential.user;

      if (mounted && user != null) {
        if (user.emailVerified) {
          // 1. إذا كان موثقاً، اذهب للشاشة الرئيسية
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false);
        } else {
          // 2. إذا لم يكن موثقاً، أرسل رابط تحقق جديد
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم إرسال رابط تحقق جديد إلى بريدك الإلكتروني.'),
              backgroundColor: Colors.orange));
          // 3. ثم اذهب لشاشة التوثيق
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const VerifyEmailScreen()),
              (route) => false);
        }
      }
    } on FirebaseAuthException {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة.'),
          backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ غير متوقع: $e'), backgroundColor: Colors.red));
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ThemeAwareImage(
                  imagePath: 'assets/images/logo.png',
                  height: 150,
                ),
                const SizedBox(height: 48),
                TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Remix.mail_line),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next),
                const SizedBox(height: 16),
                TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Remix.lock_line),
                        suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Remix.eye_off_line
                                : Remix.eye_line),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            }),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    textInputAction: TextInputAction.done),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen()));
                        },
                        child: const Text('نسيت كلمة المرور؟'))),
                const SizedBox(height: 24),
                ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3))
                        : const Text('تسجيل الدخول',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('ليس لديك حساب؟'),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()));
                      },
                      child: const Text('إنشاء حساب جديد'))
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}
