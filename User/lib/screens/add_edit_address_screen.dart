import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:remixicon/remixicon.dart';

class AddEditAddressScreen extends StatefulWidget {
  // متغيرات اختيارية لاستقبال بيانات العنوان المراد تعديله
  final String? addressId;
  final Map<String, dynamic>? initialData;

  const AddEditAddressScreen({
    Key? key,
    this.addressId,
    this.initialData,
  }) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _labelController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isLoading = false;

  // التحقق مما إذا كنا في وضع التعديل
  bool get _isEditing => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    // إذا كنا في وضع التعديل، قم بملء الحقول بالبيانات الحالية
    if (_isEditing && widget.initialData != null) {
      _labelController.text = widget.initialData!['label'] ?? '';
      _detailsController.text = widget.initialData!['details'] ?? '';
    }
  }

  Future<void> _saveAddress() async {
    if (_labelController.text.isEmpty || _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى ملء جميع الحقول.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final addressData = {
      'label': _labelController.text.trim(),
      'details': _detailsController.text.trim(),
      'createdAt': _isEditing
          ? widget.initialData!['createdAt']
          : FieldValue.serverTimestamp(),
    };

    try {
      if (_isEditing) {
        // إذا كنا في وضع التعديل، قم بتحديث المستند الحالي
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(widget.addressId!)
            .update(addressData);
      } else {
        // إذا كنا في وضع الإضافة، قم بإنشاء مستند جديد
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .add(addressData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing
                  ? 'تم تحديث العنوان بنجاح!'
                  : 'تم حفظ العنوان بنجاح!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // ... معالجة الخطأ
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل العنوان' : 'إضافة عنوان جديد'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'اسم العنوان (مثال: المنزل، العمل)',
                prefixIcon: const Icon(Remix.price_tag_3_line),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'العنوان بالتفصيل',
                hintText: 'مثال: حي حدة، شارع بيروت، جوار...',
                prefixIcon: const Icon(Remix.map_pin_user_line),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditing ? 'حفظ التعديلات' : 'حفظ العنوان',
                        style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
