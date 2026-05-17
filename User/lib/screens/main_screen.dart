import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  // قائمة بسيطة بالشاشات التي سيتم التنقل بينها
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    FavoritesScreen(),
    CartScreen(),
    OrdersScreen(),
  ];

  // قائمة بعناوين الشريط العلوي لكل شاشة
  static const List<String> _appBarTitles = <String>[
    'قائمة الطعام',
    'المفضلة',
    'سلة المشتريات',
    'طلباتي',
  ];

  @override
  void initState() {
    super.initState();
    // تعيين الفهرس المبدئي عند بدء الشاشة
    _selectedIndex = widget.initialIndex;

    // ---===  الإضافة الجديدة هنا: التحقق من المستخدم الجديد  ===---
    _checkIfNewUser();
  }

  // ---===  دالة جديدة للتحقق من المستخدم وعرض رسالة الترحيب  ===---
  Future<void> _checkIfNewUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    // التحقق من وجود علامة المستخدم الجديد
    if (userDoc.exists && (userDoc.data()?['isNewUser'] == true)) {
      // استخدام addPostFrameCallback لضمان عرض الحوار بعد اكتمال بناء الواجهة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeDialog(user.displayName ?? 'صديقنا الجديد');
      });
      // تحديث العلامة لمنع ظهور الرسالة مرة أخرى
      await userDocRef.update({'isNewUser': false});
    }
  }

  // ---===  دالة جديدة لعرض رسالة الترحيب  ===---
  void _showWelcomeDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Remix.sparkling_2_line,
                color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 10),
            const Text('أهلاً بك!'),
          ],
        ),
        content: Text(
            'مرحباً بك يا $name في مطعم تاج القيصر! نتمنى لك تجربة ممتعة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لنبدأ'),
          ),
        ],
      ),
    );
  }

  // دالة لتحديث الفهرس عند الضغط على أيقونة
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4.0,
        shadowColor: Colors.black.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Remix.user_line),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // استخدام IndexedStack للحفاظ على حالة كل شاشة ومنع إعادة بنائها
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black.withOpacity(.1)
                  : Colors.white.withOpacity(.05),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Theme.of(context).colorScheme.surface,
              hoverColor: Theme.of(context).colorScheme.surface,
              gap: 8,
              activeColor: Theme.of(context).scaffoldBackgroundColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Theme.of(context).colorScheme.primary,
              color: Colors.grey[600],
              tabs: const [
                GButton(icon: Remix.home_2_line, text: 'الرئيسية'),
                GButton(icon: Remix.heart_line, text: 'المفضلة'),
                GButton(icon: Remix.shopping_cart_2_line, text: 'السلة'),
                GButton(icon: Remix.receipt_line, text: 'طلباتي'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
