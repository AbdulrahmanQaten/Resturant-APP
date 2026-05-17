import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';

class CategoryBar extends StatefulWidget {
  final Function(String) onCategorySelected;
  // --- إضافة جديدة: متغير لتحديد ما إذا كانت هناك عروض ---
  final bool hasOffers;

  const CategoryBar({
    Key? key,
    required this.onCategorySelected,
    required this.hasOffers, // استقبال المتغير الجديد
  }) : super(key: key);

  @override
  State<CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<CategoryBar> {
  String _selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('orderIndex') // احترام الترتيب
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 50);
        }

        final categories = snapshot.data!.docs;
        List<String> categoryNames = ['الكل'];
        // --- إضافة العروض إلى القائمة إذا كانت موجودة ---
        if (widget.hasOffers) {
          categoryNames.add('العروض');
        }
        for (var category in categories) {
          final data = category.data() as Map<String, dynamic>;
          categoryNames.add(data['name'] ?? '');
        }

        return Container(
          height: 50,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoryNames.length,
            itemBuilder: (context, index) {
              final categoryName = categoryNames[index];
              final bool isSelected = categoryName == _selectedCategory;
              final bool isOfferButton = categoryName == 'العروض';

              return Padding(
                padding: EdgeInsets.only(right: index == 0 ? 12 : 0, left: 12),
                // --- تصميم مميز لزر العروض ---
                child: ChoiceChip(
                  label: Text(categoryName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = categoryName;
                      });
                      widget.onCategorySelected(categoryName);
                    }
                  },
                  avatar: isOfferButton
                      ? Icon(
                          Remix.fire_fill,
                          color: isSelected ? Colors.white : Colors.redAccent,
                          size: 18,
                        )
                      : null,
                  backgroundColor: Theme.of(context).cardColor,
                  selectedColor: isOfferButton
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isOfferButton
                            ? Colors.redAccent
                            : Theme.of(context).textTheme.bodyLarge?.color),
                    fontWeight: FontWeight.bold,
                  ),
                  shape: const StadiumBorder(),
                  side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade300
                          : Colors.grey.shade900),
                  checkmarkColor: Colors.white,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
