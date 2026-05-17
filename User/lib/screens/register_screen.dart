import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'verify_email_screen.dart';
import 'placeholder_screen.dart';
import '../widgets/theme_aware_image.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى ملء جميع الحقول.'), backgroundColor: Colors.red));
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('كلمة المرور يجب أن تتكون من 6 خانات على الأقل.'),
          backgroundColor: Colors.red));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('كلمة المرور غير متطابقة!'),
          backgroundColor: Colors.red));
      return;
    }
    // ---===  الإضافة الجديدة هنا: التحقق من طول رقم الهاتف  ===---
    if (_phoneController.text.trim().length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('رقم الهاتف يجب أن يتكون من 9 أرقام.'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        await newUser.sendEmailVerification();
        await newUser.updateDisplayName(_nameController.text.trim());

        // ---===  الإضافة الجديدة هنا  ===---
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': "+967" + _phoneController.text.trim(),
          'uid': newUser.uid,
          'createdAt': Timestamp.now(),
          'isNewUser': true,
          'emailVerified': false, // إضافة هذه العلامة
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ ما.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
      // ...
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPlaceholder(String title, String pageId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              PlaceholderScreen(title: title, pageId: pageId)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ThemeAwareImage(
                  imagePath: 'assets/images/logo.png',
                  height: 150,
                ),
                const SizedBox(height: 16),
                Text('إنشاء حساب جديد',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: const Icon(Remix.user_line),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    textInputAction: TextInputAction.next),
                const SizedBox(height: 16),
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
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: Text('+967',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
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
                            onPressed: () => setState(() =>
                                _isPasswordVisible = !_isPasswordVisible)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    textInputAction: TextInputAction.next),
                const SizedBox(height: 16),
                TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: const Icon(Remix.lock_line),
                        suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible
                                ? Remix.eye_off_line
                                : Remix.eye_line),
                            onPressed: () => setState(() =>
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    textInputAction: TextInputAction.done),
                const SizedBox(height: 24),

                // ---===  التعديل هنا: إزالة مربع الاختيار  ===---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        const TextSpan(
                            text: 'بالضغط على إنشاء الحساب، أنت توافق على '),
                        TextSpan(
                          text: 'شروط الخدمة',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _navigateToPlaceholder(
                                'شروط الخدمة', 'terms-of-service'),
                        ),
                        const TextSpan(text: ' و '),
                        TextSpan(
                          text: 'سياسة الخصوصية',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _navigateToPlaceholder(
                                'سياسة الخصوصية', 'privacy-policy'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _isLoading ? null : _registerUser,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                      : const Text('إنشاء الحساب',
                          style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب بالفعل؟'),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('تسجيل الدخول')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
