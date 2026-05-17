import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'admin_dashboard_screen.dart';
import '../widgets/theme_aware_image.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _loginAdmin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى ملء جميع الحقول.'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. التحقق من صحة البريد وكلمة المرور
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ---===  2. التحقق من صلاحيات المستخدم (Authorization)  ===---
      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
          // إذا كان المستخدم مديراً، اسمح له بالدخول
          if (mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen()));
          }
        } else {
          // إذا لم يكن مديراً، قم بتسجيل خروجه وأظهر رسالة خطأ
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('ليس لديك صلاحيات الدخول.'),
              backgroundColor: Colors.red));
        }
      }
      // ---======================================================---
    } on FirebaseAuthException {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('بيانات الدخول غير صحيحة.'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ThemeAwareImage(
                imagePath: 'assets/images/logo.png',
                height: 200,
              ),
              const SizedBox(height: 16),
              Text('تسجيل دخول المدير',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Remix.mail_line)),
                keyboardType: TextInputType.emailAddress,
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
                      icon: Icon(
                        _isPasswordVisible
                            ? Remix.eye_off_line
                            : Remix.eye_line,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  )),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isLoading ? null : _loginAdmin,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ))
                    : const Text('دخول', style: TextStyle(fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
