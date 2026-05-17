import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _deleteImage(String fileId) async {
    // !!! هام: لقد قمت بحذف المفاتيح من هنا. يرجى استبدالها بمفاتيحك الجديدة. !!!
    const String privateKey = "private_lgVfvTjwE4gXiOfWPib07U6ZIOE=";
    final url = Uri.parse('https://api.imagekit.io/v1/files/$fileId');

    final String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$privateKey:'));

    try {
      print('Attempting to delete image with fileId: $fileId');
      final response =
          await http.delete(url, headers: {'Authorization': basicAuth});
      if (response.statusCode == 204) {
        print('Successfully deleted old image from ImageKit.');
      } else {
        print(
            'Failed to delete old image. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<Map<String, String>?> _uploadImage(XFile image) async {
    // !!! هام: استبدل القيم هنا بالقيم الخاصة بك من ImageKit.io !!!
    const String publicKey = "public_IQs0W4JRSIO0lizon9bRQPTTpPM=";
    const String privateKey = "private_8QG/DSp930xIjGpZ6qmkYK1iz/E=";
    final url = Uri.parse('https://upload.imagekit.io/api/v1/files/upload');
    final request = http.MultipartRequest('POST', url);

    final String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$privateKey:'));
    request.headers['Authorization'] = basicAuth;

    final bytes = await image.readAsBytes();
    final multipartFile =
        http.MultipartFile.fromBytes('file', bytes, filename: image.name);
    request.files.add(multipartFile);

    request.fields['publicKey'] = publicKey;
    request.fields['fileName'] = image.name;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        print(
            'Image uploaded successfully. URL: ${jsonResponse['url']}, FileID: ${jsonResponse['fileId']}');
        return {
          'url': jsonResponse['url'],
          'fileId': jsonResponse['fileId'],
        };
      } else {
        print(
            'ImageKit Upload Error: ${await response.stream.bytesToString()}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
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
        await _deleteImage(_imageFileId!);
      }

      final uploadResult = await _uploadImage(_imageFile!);
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
