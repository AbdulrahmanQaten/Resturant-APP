import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:remixicon/remixicon.dart';
import '../widgets/theme_aware_image.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى إدخال بريدك الإلكتروني.'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase Auth تتولى التحقق من وجود الحساب بشكل داخلي.
      // لا نحتاج استعلام Firestore هنا — المستخدم غير مسجل ولن تُقبل قراءته.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'إذا كان البريد مسجلاً لدينا، ستصلك رسالة استعادة كلمة المرور.'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ، يرجى المحاولة مرة أخرى.';
      if (e.code == 'user-not-found') {
        // نعرض نفس الرسالة لأسباب أمنية (لا نكشف هل الإيميل مسجل أم لا)
        message =
            'إذا كان البريد مسجلاً لدينا، ستصلك رسالة استعادة كلمة المرور.';
      } else if (e.code == 'invalid-email') {
        message = 'صيغة البريد الإلكتروني غير صحيحة.';
      } else if (e.code == 'too-many-requests') {
        message = 'تم الإرسال مسبقاً، يرجى الانتظار قليلاً.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: e.code == 'user-not-found' ||
                    e.code == 'too-many-requests'
                ? Colors.green
                : Colors.red));
        if (e.code == 'user-not-found') Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }


  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
          title: const Text('استعادة كلمة المرور'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Padding(
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
            Text(
                'أدخل بريدك الإلكتروني المسجل لدينا وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),
            TextField(
                controller: _emailController,
                decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Remix.mail_line),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done),
            const SizedBox(height: 32),
            ElevatedButton(
                onPressed: _isLoading ? null : _sendPasswordResetEmail,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Text('إرسال رابط الاستعادة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)))
          ],
        ),
      ),
    );
  }
}
