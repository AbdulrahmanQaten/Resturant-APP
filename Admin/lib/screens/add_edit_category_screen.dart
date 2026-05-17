import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final DocumentSnapshot? categoryDoc;

  const AddEditCategoryScreen({Key? key, this.categoryDoc}) : super(key: key);

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool get _isEditing => widget.categoryDoc != null;

  Color _currentColor = const Color(0xFFf39c12);
  String? _oldCategoryName;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final data = widget.categoryDoc!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _oldCategoryName = data['name']; // حفظ الاسم القديم
      final colorString = data['color'] ?? 'f39c12';
      _currentColor = Color(int.parse('0xFF$colorString'));
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر لون التصنيف'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) {
              setState(() => _currentColor = color);
            },
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('اختيار'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // ---===  دالة الحفظ الجديدة والمحسنة  ===---
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final newName = _nameController.text.trim();
    final colorString = _currentColor.value.toRadixString(16).substring(2);

    try {
      if (_isEditing) {
        // --- منطق التحديث المتزامن ---
        if (_oldCategoryName != null && _oldCategoryName != newName) {
          // 1. ابحث عن كل الوجبات التي تستخدم التصنيف القديم
          final mealsToUpdate = await FirebaseFirestore.instance
              .collection('meals')
              .where('category', isEqualTo: _oldCategoryName)
              .get();

          // 2. استخدم "حزمة تعديل" (WriteBatch) لتحديثها كلها مرة واحدة
          WriteBatch batch = FirebaseFirestore.instance.batch();
          for (var doc in mealsToUpdate.docs) {
            batch.update(doc.reference, {'category': newName});
          }

          // 3. تحديث التصنيف نفسه
          batch.update(widget.categoryDoc!.reference,
              {'name': newName, 'color': colorString});

          // 4. تنفيذ كل التعديلات
          await batch.commit();
        } else {
          // إذا لم يتغير الاسم، قم بتحديث اللون فقط
          await widget.categoryDoc!.reference
              .update({'name': newName, 'color': colorString});
        }
      } else {
        final querySnapshot =
            await FirebaseFirestore.instance.collection('categories').get();
        final newIndex = querySnapshot.docs.length;

        // 2. إضافة حقل orderIndex مع بيانات التصنيف الجديد
        await FirebaseFirestore.instance.collection('categories').add({
          'name': newName,
          'color': colorString,
          'orderIndex': newIndex, // الإضافة هنا
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'تم تعديل التصنيف بنجاح!'
                : 'تم إضافة التصنيف بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل التصنيف' : 'إضافة تصنيف جديد'),
        centerTitle: true,
        actions: [
          if (_isLoading)
            Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ))),
          if (!_isLoading)
            IconButton(
                icon: const Icon(Remix.save_line), onPressed: _saveCategory),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم التصنيف'),
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('لون التصنيف'),
                trailing: CircleAvatar(backgroundColor: _currentColor),
                onTap: _pickColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
