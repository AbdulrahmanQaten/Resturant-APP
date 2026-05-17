import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // !!! هام: الصق مفاتيح الربط الخاصة بك هنا !!!
    options: const FirebaseOptions(
        apiKey: "AIzaSyDn7j9WaR66wDXTmy1SsjwxY4_AUssf7eA",
        authDomain: "tajalqaisar-605bf.firebaseapp.com",
        projectId: "tajalqaisar-605bf",
        storageBucket: "tajalqaisar-605bf.firebasestorage.app",
        messagingSenderId: "320025271662",
        appId: "1:320025271662:web:8dd08f731b3f7efaab357f"),
  );
  // ---===  التعديل هنا: إضافة مزود الثيم  ===---
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ---===  جعل التطبيق يستمع لمزود الثيم  ===---
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'YE'),
          ],
          locale: const Locale('ar', 'YE'),
          title: 'مطعم تاج القيصر',
          debugShowCheckedModeBanner: false,

          // ---===  تطبيق الثيمات هنا  ===---
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Tajawal',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xfffbfbfb),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6a2e0e),
              primary: const Color(0xFF6a2e0e),
              secondary: const Color(0xFFf39c12),
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6a2e0e), // اللون الرئيسي للزر
                foregroundColor: Colors.white, // لون النص
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // حواف دائرية للزر
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 24), // الحشو داخل الزر
                elevation: 5, // الظل
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6a2e0e), // اللون الرئيسي للنص
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: const Color(0xFF6a2e0e),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              // filled: true,
              // fillColor: Colors.white,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
                gapPadding: 4,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
                gapPadding: 4,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: const Color(0xFF6a2e0e), width: 2),
                gapPadding: 4,
              ),
              prefixIconColor: const Color(0xFF6a2e0e).withOpacity(0.7),
            ),
            // باقي إعدادات الثيم الفاتح
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Tajawal',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6a2e0e),
              primary: const Color(0xff9c5d32), // نسخة أفتح من البني
              secondary: const Color(0xFFFFB74D), // نسخة أفتح من الذهبي
              surface: const Color(0xFF1E1E1E), // لون البطاقات الداكن
              brightness: Brightness.dark,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                    0xFF9c5d32), // اللون الرئيسي للزر في الثيم الداكن
                foregroundColor: Colors.white, // لون النص
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // حواف دائرية للزر
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 24), // الحشو داخل الزر
                elevation: 5, // الظل
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(
                    0xFF9c5d32), // اللون الرئيسي للنص في الثيم الداكن
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: const Color(0xFF9c5d32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              // filled: true,
              // fillColor: const Color(0xFF2A2A2A),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade800),
                gapPadding: 4,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade800),
                gapPadding: 4,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: const Color(0xFFFFB74D), width: 2),
                gapPadding: 4,
              ),
              prefixIconColor: const Color(0xFFFFB74D).withOpacity(0.7),
            ),
            // باقي إعدادات الثيم الداكن
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
