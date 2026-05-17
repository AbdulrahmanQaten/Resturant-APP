import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_screen.dart';
import 'admin_dashboard_screen.dart';
import '../widgets/theme_aware_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      // التحقق مما إذا كان الأدمن مسجلاً دخوله
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // إذا كان مسجلاً، اذهب إلى لوحة التحكم
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen()));
      } else {
        // إذا لم يكن، اذهب إلى شاشة تسجيل الدخول
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ThemeAwareImage(
                    imagePath: 'assets/images/logo.png',
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  const Text("لوحة تحكم الأدمن",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            ),

            // توقيع Qatenic في أسفل الشاشة مع مسافة بسيطة من الحافة
            Positioned(
              bottom: 24, // مسافة من الأسفل، عدلها كما تريد (مثلاً 16، 32...)
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تم التطوير بواسطة Qatenic',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Image.asset(
                    'assets/images/qatenic.png',
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
