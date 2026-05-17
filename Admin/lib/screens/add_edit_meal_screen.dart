import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:image_picker/image_picker.dart';
import '../services/imagekit_service.dart';

class AddEditMealScreen extends StatefulWidget {
  final DocumentSnapshot? mealDoc;

  const AddEditMealScreen({Key? key, this.mealDoc}) : super(key: key);

  @override
  State<AddEditMealScreen> createState() => _AddEditMealScreenState();
}

class _AddEditMealScreenState extends State<AddEditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;
  bool get _isEditing => widget.mealDoc != null;

  XFile? _imageFile;
  String? _networkImageUrl;
  String? _imageFileId;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final data = widget.mealDoc!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      _discountPriceController.text = (data['discountPrice'] ?? '').toString();
      _descriptionController.text = data['description'] ?? '';
      _selectedCategory = data['category'];
      _networkImageUrl = data['imageUrl'];
      _imageFileId = data['imageFileId'];
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }


  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الرجاء اختيار تصنيف')));
      return;
    }
    if (_imageFile == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار صورة للوجبة')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? imageUrl = _networkImageUrl;
    String? imageFileId = _imageFileId;

    if (_imageFile != null) {
      if (_isEditing && _imageFileId != null) {
        await ImageKitService.deleteImage(_imageFileId!);
      }

      final uploadResult = await ImageKitService.uploadImage(_imageFile!);
      if (uploadResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('فشل رفع الصورة، يرجى المحاولة مرة أخرى.'),
            backgroundColor: Colors.red));
        setState(() {
          _isLoading = false;
        });
        return;
      }
      imageUrl = uploadResult['url'];
      imageFileId = uploadResult['fileId'];
    }

    final mealData = {
      'name': _nameController.text.trim(),
      'price': num.tryParse(_priceController.text.trim()) ?? 0,
      'discountPrice': num.tryParse(_discountPriceController.text.trim()),
      'imageUrl': imageUrl,
      'imageFileId': imageFileId,
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
    };

    try {
      if (_isEditing) {
        await widget.mealDoc!.reference.update(mealData);
      } else {
        await FirebaseFirestore.instance.collection('meals').add(mealData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'تم تعديل الوجبة بنجاح!'
                : 'تم إضافة الوجبة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // ...
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
    _priceController.dispose();
    _discountPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل وجبة' : 'إضافة وجبة جديدة'),
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
            IconButton(icon: const Icon(Remix.save_line), onPressed: _saveMeal),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم الوجبة'),
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'السعر الأصلي'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _discountPriceController,
                  decoration:
                      const InputDecoration(labelText: 'سعر الخصم (اختياري)'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  maxLines: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _imageFile != null
                ? NetworkImage(_imageFile!.path)
                : (_networkImageUrl != null
                    ? NetworkImage(_networkImageUrl!)
                    : null) as ImageProvider?,
            child: (_imageFile == null && _networkImageUrl == null)
                ? Icon(Remix.image_add_line,
                    size: 50, color: Colors.grey.shade400)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: const Icon(Remix.pencil_line, color: Colors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---===  ويدجت القائمة المنسدلة الجديد والمحسن  ===---
  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('orderIndex')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final categoryDocs = snapshot.data!.docs;
        final categoryNames = categoryDocs
            .map(
                (doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
            .toList();

        // --- الإصلاح هنا: التحقق من وجود التصنيف القديم ---
        // إذا كان التصنيف المحفوظ مع الوجبة لم يعد موجوداً في القائمة، اجعله null
        if (_selectedCategory != null &&
            !categoryNames.contains(_selectedCategory)) {
          _selectedCategory = null;
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(labelText: 'التصنيف'),
          items: categoryNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          validator: (v) => v == null ? 'الرجاء اختيار تصنيف صالح' : null,
        );
      },
    );
  }
}
