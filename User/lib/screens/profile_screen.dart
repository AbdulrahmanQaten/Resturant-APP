import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'addresses_screen.dart';
import 'placeholder_screen.dart';
import 'about_screen.dart';
import 'dart:ui' as ui;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  // --- دالة مساعدة للانتقال إلى الصفحات ---
  void _navigateToPage(String title, String pageId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              PlaceholderScreen(title: title, pageId: pageId)),
    );
  }

// ---===  دوال جديدة لإعادة تعيين كلمة المرور  ===---
  void _showPasswordResetDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد'),
        content: Text(
            'هل أنت متأكد أنك تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني (${user.email})؟'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('نعم، أرسل الرابط'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _sendPasswordReset();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'تم إرسال رابط إعادة التعيين بنجاح. يرجى تفقد بريدك الإلكتروني.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال الرابط: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        centerTitle: true,
      ),
      // ---===  التعديل هنا: عرض الهيكل الرئيسي دائماً  ===---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- عرض الهيكل أو البيانات الحقيقية هنا فقط ---
            _isLoading ? _buildSkeletonProfile() : _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildOptionsCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildLogoutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Remix.user_line,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userData?['name'] ?? user?.displayName ?? 'اسم المستخدم',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData?['email'] ?? user?.email ?? 'البريد الإلكتروني',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(
                        (_userData?['phone'] as String?)
                                ?.replaceFirst('+967', '') ??
                            'رقم غير محدد',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonProfile() {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
                radius: 35, backgroundColor: Theme.of(context).splashColor),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonLoader(width: 150, height: 20),
                  const SizedBox(height: 8),
                  _buildSkeletonLoader(width: 200),
                  const SizedBox(height: 8),
                  _buildSkeletonLoader(width: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildProfileMenuItem(
            context,
            icon: Remix.edit_line,
            title: 'تعديل الملف الشخصي',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              ).then((_) {
                // إعادة جلب البيانات عند العودة من شاشة التعديل
                _fetchUserData();
              });
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildProfileMenuItem(context,
              icon: Remix.map_pin_line, title: 'عناويني', onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddressesScreen()));
          }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildProfileMenuItem(context,
              icon: Remix.contrast_2_line,
              title: 'المظهر',
              onTap: _showThemeDialog),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildProfileMenuItem(context,
              icon: Remix.key_2_line,
              title: 'إعادة تعيين كلمة المرور',
              onTap: _showPasswordResetDialog),
          // _buildProfileMenuItem(context,
          //     icon: Remix.notification_3_line,
          //     title: 'إعدادات الإشعارات',
          //     onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildProfileMenuItem(context,
              icon: Remix.shield_check_line,
              title: 'سياسة الخصوصية',
              onTap: () => _navigateToPage('سياسة الخصوصية', 'privacy-policy')),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildProfileMenuItem(context,
              icon: Remix.file_text_line,
              title: 'شروط الخدمة',
              onTap: () => _navigateToPage('شروط الخدمة', 'terms-of-service')),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildProfileMenuItem(context,
              icon: Remix.question_line,
              title: 'مركز المساعدة',
              onTap: () => _navigateToPage('مركز المساعدة', 'help-center')),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // ---===  الإضافة الجديدة هنا  ===---
          _buildProfileMenuItem(context,
              icon: Remix.information_line, title: 'حول التطبيق', onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AboutScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: _buildProfileMenuItem(
        context,
        icon: Remix.logout_circle_r_line,
        title: 'تسجيل الخروج',
        tileColor: Theme.of(context).brightness == Brightness.light
            ? Colors.red.shade50
            : Colors.red.shade900.withOpacity(0.3),
        iconColor: Colors.red.shade700,
        textColor: Colors.red.shade700,
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildSkeletonLoader({double width = 150, double height = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).splashColor,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? tileColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      tileColor: tileColor,
      leading:
          Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}
