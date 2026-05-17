import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:http/http.dart' as http;
import 'add_edit_meal_screen.dart';

class AdminMealsScreen extends StatefulWidget {
  const AdminMealsScreen({Key? key}) : super(key: key);

  @override
  State<AdminMealsScreen> createState() => _AdminMealsScreenState();
}

class _AdminMealsScreenState extends State<AdminMealsScreen> {
  String? _selectedCategory;
  bool _showDiscountedOnly = false;
  String _searchQuery = '';

  Future<void> _deleteImageFromImageKit(String fileId) async {
    // !!! هام: لقد قمت بحذف المفاتيح من هنا. يرجى استبدالها بمفاتيحك الجديدة. !!!
    const String privateKey = "YOUR_PRIVATE_KEY";
    final url = Uri.parse('https://api.imagekit.io/v1/files/$fileId');

    final String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$privateKey:'));

    try {
      final response =
          await http.delete(url, headers: {'Authorization': basicAuth});
      if (response.statusCode == 204) {
        print('Successfully deleted old image from ImageKit.');
      } else {
        print('Failed to delete old image: ${response.body}');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, DocumentSnapshot mealDoc) {
    final mealData = mealDoc.data() as Map<String, dynamic>;
    final mealName = mealData['name'] ?? 'الوجبة المحددة';
    final imageFileId = mealData['imageFileId'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف وجبة "$mealName" بشكل نهائي؟'),
        actions: [
          TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('نعم، حذف', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();

              if (imageFileId != null) {
                await _deleteImageFromImageKit(imageFileId);
              }

              await mealDoc.reference.delete();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الوجبة بنجاح.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الوجبات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'ابحث بالاسم أو التصنيف...',
                    prefixIcon: Icon(Remix.search_line),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildCategoryDropdown()),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('عليها عرض'),
                      selected: _showDiscountedOnly,
                      onSelected: (selected) {
                        setState(() => _showDiscountedOnly = selected);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('meals').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('لم تقم بإضافة أي وجبات بعد.'));
                }

                var meals = snapshot.data!.docs;

                if (_selectedCategory != null && _selectedCategory != 'الكل') {
                  meals = meals
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)['category'] ==
                          _selectedCategory)
                      .toList();
                }
                if (_showDiscountedOnly) {
                  meals = meals.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final discountPrice = data['discountPrice'] as num?;
                    return discountPrice != null && discountPrice > 0;
                  }).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  meals = meals.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] as String? ?? '').toLowerCase();
                    final category =
                        (data['category'] as String? ?? '').toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return name.contains(query) || category.contains(query);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final mealDoc = meals[index];
                    final mealData = mealDoc.data() as Map<String, dynamic>;
                    final originalPrice = mealData['price'] as num?;
                    final discountPrice = mealData['discountPrice'] as num?;
                    final bool hasDiscount = discountPrice != null &&
                        originalPrice != null &&
                        discountPrice > 0 &&
                        discountPrice < originalPrice;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(mealData['imageUrl'] ?? ''),
                        ),
                        title: Text(mealData['name'] ?? 'اسم الوجبة',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        // ---===  الإصلاح هنا: عرض السعرين  ===---
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mealData['category'] ?? 'تصنيف غير محدد'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (hasDiscount)
                                  Text(
                                    '${originalPrice ?? 0} ريال',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (hasDiscount) const SizedBox(width: 8),
                                Text(
                                  '${hasDiscount ? discountPrice : originalPrice ?? 0} ريال',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: hasDiscount
                                        ? Colors.redAccent
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Remix.edit_line,
                                  color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddEditMealScreen(mealDoc: mealDoc),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Remix.delete_bin_line,
                                  color: Colors.redAccent),
                              onPressed: () {
                                _showDeleteConfirmationDialog(context, mealDoc);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditMealScreen()),
          );
        },
        label: const Text('إضافة وجبة جديدة'),
        icon: const Icon(Remix.add_line),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        var items = <DropdownMenuItem<String>>[
          const DropdownMenuItem(value: 'الكل', child: Text('كل التصنيفات')),
        ];

        items.addAll(snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return DropdownMenuItem<String>(
            value: data['name'],
            child: Text(data['name']),
          );
        }));

        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          hint: const Text('فلترة حسب التصنيف'),
          decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12)),
          items: items,
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        );
      },
    );
  }
}
