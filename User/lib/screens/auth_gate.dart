import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'offline_screen.dart';
import 'verify_email_screen.dart'; // استيراد الشاشة الجديدة

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<List<ConnectivityResult>> _connectivityFuture;
  @override
  void initState() {
    super.initState();
    _connectivityFuture = Connectivity().checkConnectivity();
  }

  void _retryCheck() {
    setState(() {
      _connectivityFuture = Connectivity().checkConnectivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConnectivityResult>>(
      future: _connectivityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData &&
            snapshot.data!.contains(ConnectivityResult.none)) {
          return OfflineScreen(onRetry: _retryCheck);
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (authSnapshot.hasData) {
              // ---===  الإصلاح هنا: التحقق من توثيق البريد  ===---
              if (authSnapshot.data!.emailVerified) {
                // إذا كان موثقاً، اذهب للشاشة الرئيسية
                return const MainScreen();
              } else {
                // إذا لم يكن، اذهب لشاشة انتظار التوثيق
                return const VerifyEmailScreen();
              }
            } else {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
