import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({Key? key}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  Timer? _verificationTimer;

  // --- متغيرات جديدة لإدارة مؤقت إعادة الإرسال ---
  Timer? _resendTimer;
  int _resendCooldown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      _verificationTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
      // بدء مؤقت إعادة الإرسال لأول مرة
      startResendTimer();
    }
  }

  void startResendTimer() {
    setState(() => _canResend = false);
    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_resendCooldown == 0) {
          setState(() {
            _resendTimer?.cancel();
            _canResend = true;
          });
        } else {
          setState(() {
            _resendCooldown--;
          });
        }
      },
    );
  }

  Future<void> checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();

    final isNowVerified = user.emailVerified;

    if (isNowVerified && mounted) {
      _verificationTimer?.cancel();
      _resendTimer?.cancel();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'emailVerified': true}, SetOptions(merge: true));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  // --- دالة جديدة لإعادة إرسال رابط التحقق ---
  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إرسال رابط تحقق جديد.'),
            backgroundColor: Colors.green),
      );
      // إعادة ضبط المؤقت
      _resendCooldown = 60;
      startResendTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: لا يمكن إرسال الرابط الآن.')),
      );
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('توثيق الحساب'),
        actions: [
          IconButton(
            icon: const Icon(Remix.logout_circle_r_line),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Remix.mail_send_line, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'تم إرسال رابط التوثيق!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'لقد أرسلنا رابطاً إلى بريدك الإلكتروني:\n${user?.email}\n\nيرجى الضغط على الرابط ثم العودة إلى التطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('في انتظار التوثيق...'),
              const SizedBox(height: 24),
              // ---===  زر إعادة الإرسال الجديد  ===---
              TextButton.icon(
                icon: const Icon(Remix.send_plane_line),
                label: Text(_canResend
                    ? "إعادة إرسال الرابط"
                    : "يمكن إعادة الإرسال بعد $_resendCooldown ثانية"),
                onPressed: _canResend ? _resendVerificationEmail : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
