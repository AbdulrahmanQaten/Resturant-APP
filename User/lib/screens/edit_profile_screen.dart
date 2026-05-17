import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _initialPhoneNumber = '';
  String _initialName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _initialName = user.displayName ?? '';
      _nameController.text = _initialName;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()!.containsKey('phone')) {
        String phone = userDoc.data()!['phone'];
        _initialPhoneNumber = phone;
        if (phone.startsWith('+967')) {
          phone = phone.substring(4);
        }
        _phoneController.text = phone;
      }
    }
  }

  // ---===  دالة الحفظ الجديدة والمبسطة  ===---
  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى ملء جميع الحقول.'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newName = _nameController.text.trim();
      final newPhoneNumber = "+967" + _phoneController.text.trim();
      bool hasChanges = false;

      // 1. تحديث الاسم إذا تغير
      if (newName != _initialName) {
        await user.updateDisplayName(newName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': newName});
        hasChanges = true;
      }

      // 2. تحديث رقم الهاتف إذا تغير
      if (newPhoneNumber != _initialPhoneNumber) {
        // التحقق من طول الرقم الجديد
        if (_phoneController.text.trim().length != 9) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('رقم الهاتف يجب أن يتكون من 9 أرقام.'),
              backgroundColor: Colors.red));
          setState(() {
            _isLoading = false;
          });
          return;
        }
        // التحديث المباشر في قاعدة البيانات
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'phone': newPhoneNumber});
        hasChanges = true;
      }

      if (mounted) {
        if (hasChanges) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم حفظ التغييرات بنجاح!'),
              backgroundColor: Colors.green));
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("حدث خطأ: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: const Icon(Remix.user_line),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  child: Text('+967',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ))
                    : const Text('حفظ التغييرات',
                        style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
