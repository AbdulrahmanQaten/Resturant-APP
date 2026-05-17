import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'add_edit_category_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  String _searchQuery = '';
  List<DocumentSnapshot>? _categories;

  void _showDeleteConfirmationDialog(
      BuildContext context, DocumentSnapshot categoryDoc) {
    final categoryData = categoryDoc.data() as Map<String, dynamic>;
    final categoryName = categoryData['name'] ?? 'التصنيف المحدد';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف تصنيف "$categoryName"؟'),
        actions: [
          TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('نعم، حذف', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await categoryDoc.reference.delete();
              Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف التصنيف بنجاح.'),
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

  Future<void> _updateOrder(List<DocumentSnapshot> categories) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < categories.length; i++) {
      batch.update(categories[i].reference, {'orderIndex': i});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة وترتيب التصنيفات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم...',
                prefixIcon: Icon(Remix.search_line),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .orderBy('orderIndex')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('لم تقم بإضافة أي تصنيفات بعد.'));
                }

                _categories = snapshot.data!.docs;

                var displayedCategories = _categories!;
                if (_searchQuery.isNotEmpty) {
                  displayedCategories = _categories!.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['name'] as String? ?? '')
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: displayedCategories.length,
                  // ---===  التعديل هنا: تحسين مظهر العنصر أثناء السحب  ===---
                  proxyDecorator:
                      (Widget child, int index, Animation<double> animation) {
                    return Material(
                      elevation: 8.0,
                      borderRadius: BorderRadius.circular(12.0),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final categoryDoc = displayedCategories[index];
                    final categoryData =
                        categoryDoc.data() as Map<String, dynamic>;
                    final colorString = categoryData['color'] ?? '808080';
                    final color = Color(int.parse('0xFF$colorString'));

                    return Card(
                      key: ValueKey(categoryDoc.id),
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      child: ListTile(
                        // ---===  التعديل هنا: تحديد أيقونة السحب  ===---
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Remix.drag_move_2_line),
                        ),
                        title: Text(categoryData['name'] ?? 'اسم التصنيف',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(backgroundColor: color, radius: 14),
                            IconButton(
                              icon: const Icon(Remix.edit_line,
                                  color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditCategoryScreen(
                                        categoryDoc: categoryDoc),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Remix.delete_bin_line,
                                  color: Colors.redAccent),
                              onPressed: () => _showDeleteConfirmationDialog(
                                  context, categoryDoc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  // ---===  الإصلاح هنا: منطق إعادة الترتيب الصحيح  ===---
                  onReorder: (oldFilteredIndex, newFilteredIndex) {
                    setState(() {
                      final draggedItem = displayedCategories[oldFilteredIndex];
                      final originalOldIndex = _categories!
                          .indexWhere((doc) => doc.id == draggedItem.id);

                      if (newFilteredIndex > oldFilteredIndex) {
                        newFilteredIndex -= 1;
                      }

                      final targetItem = displayedCategories[newFilteredIndex];
                      final originalNewIndex = _categories!
                          .indexWhere((doc) => doc.id == targetItem.id);

                      final item = _categories!.removeAt(originalOldIndex);
                      _categories!.insert(originalNewIndex, item);

                      _updateOrder(_categories!);
                    });
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
            MaterialPageRoute(
                builder: (context) => const AddEditCategoryScreen()),
          );
        },
        label: const Text('إضافة تصنيف جديد'),
        icon: const Icon(Remix.add_line),
      ),
    );
  }
}
