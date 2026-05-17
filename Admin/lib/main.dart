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
        storageBucket: "tajalqaisar-605bf.appspot.com",
        messagingSenderId: "320025271662",
        appId: "1:320025271662:web:8dd08f731b3f7efaab357f"),
  );
  // ---===  التعديل هنا: إضافة مزود الثيم  ===---
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({Key? key}) : super(key: key);

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
          title: 'إدارة ${AppConfig.restaurantFullName}',
          debugShowCheckedModeBanner: false,

          // ---===  تطبيق الثيمات هنا  ===---
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            // --- الثيم الفاتح ---
            useMaterial3: true,
            fontFamily: 'Tajawal',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            cardColor: Colors.white,
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
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppConfig.primaryColor,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 4.0,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
            cardTheme: const CardTheme(
              color: Colors.white,
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
          ),
          darkTheme: ThemeData(
            // --- الثيم الداكن ---
            useMaterial3: true,
            fontFamily: 'Tajawal',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
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
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppConfig.primaryColorDark,
              foregroundColor: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppConfig.secondaryColorDark,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF1E1E1E),
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 4.0,
              shadowColor: Colors.black.withOpacity(0.5),
            ),
            cardTheme: const CardTheme(
              color: Color(0xFF1E1E1E),
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
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
