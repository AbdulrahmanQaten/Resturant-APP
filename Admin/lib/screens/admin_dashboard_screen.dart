import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'admin_orders_screen.dart';
import 'admin_meals_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_delivery_zones_screen.dart';
import 'admin_pages_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_about_screen.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  // ---===  دالة جديدة لعرض نافذة اختيار الثيم  ===---
  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر المظهر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('فاتح'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('داكن'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('تلقائي (حسب النظام)'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'تغيير المظهر',
          icon: const Icon(Remix.contrast_2_line),
          onPressed: () => _showThemeDialog(context),
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Remix.logout_circle_r_line),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: <Widget>[
          _buildDashboardItem(context,
              icon: Remix.receipt_line, label: 'إدارة الطلبات', onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminOrdersScreen()));
          }),
          _buildDashboardItem(context,
              icon: Remix.restaurant_line, label: 'إدارة الوجبات', onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminMealsScreen()));
          }),
          _buildDashboardItem(context,
              icon: Remix.price_tag_3_line,
              label: 'إدارة التصنيفات', onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminCategoriesScreen()));
          }),
          _buildDashboardItem(context,
              icon: Remix.image_line, label: 'إدارة البانر', onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminBannersScreen()));
          }),
          _buildDashboardItem(context,
              icon: Remix.map_pin_line, label: 'مناطق التوصيل', onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminDeliveryZonesScreen()));
          }),
          _buildDashboardItem(context,
              icon: Remix.file_text_line, label: 'إدارة الصفحات', onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminPagesScreen()));
          }),
          _buildDashboardItem(context,
              icon: Remix.bar_chart_2_line, label: 'الإحصائيات', onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminAnalyticsScreen()));
          }),
          _buildDashboardItem(context,
              icon: Remix.information_line, label: 'حول', onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AboutScreen()));
          }),
          // --- تم حذف زر الإعدادات من هنا ---
        ],
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
