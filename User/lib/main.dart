import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_config.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // مفاتيح Firebase الخاصة بهذا المشروع
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
          title: AppConfig.restaurantFullName,
          debugShowCheckedModeBanner: false,

          // ---===  تطبيق الثيمات هنا  ===---
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Tajawal',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xfffbfbfb),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConfig.primaryColor,
              primary: AppConfig.primaryColor,
              secondary: AppConfig.secondaryColor,
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
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
                foregroundColor: AppConfig.primaryColor,
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppConfig.primaryColor,
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
                    BorderSide(color: AppConfig.primaryColor, width: 2),
                gapPadding: 4,
              ),
              prefixIconColor: AppConfig.primaryColor.withOpacity(0.7),
            ),
            // باقي إعدادات الثيم الفاتح
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Tajawal',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConfig.primaryColorDark,
              primary: AppConfig.primaryColorDark,
              secondary: AppConfig.secondaryColorDark,
              surface: const Color(0xFF1E1E1E),
              brightness: Brightness.dark,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColorDark,
                foregroundColor: Colors.white,
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
                foregroundColor: AppConfig.primaryColorDark,
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppConfig.primaryColorDark,
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
                    BorderSide(color: AppConfig.secondaryColorDark, width: 2),
                gapPadding: 4,
              ),
              prefixIconColor: AppConfig.secondaryColorDark.withOpacity(0.7),
            ),
            // باقي إعدادات الثيم الداكن
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
