import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';

class CategoryBar extends StatefulWidget {
  final Function(String) onCategorySelected;
  final bool hasOffers;
  /// يُستدعى عند الضغط على زر تبديل طريقة العرض
  final VoidCallback onLayoutToggle;
  /// هل وضع العرض الحالي هو List؟ (true = قائمة، false = شبكة)
  final bool isListView;

  const CategoryBar({
    Key? key,
    required this.onCategorySelected,
    required this.hasOffers,
    required this.onLayoutToggle,
    required this.isListView,
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
          .orderBy('orderIndex')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 50);
        }

        final categories = snapshot.data!.docs;
        List<String> categoryNames = ['الكل'];
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
          child: Row(
            children: [
              // ── شريط التصنيفات — قابل للتمرير ──────────
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categoryNames.length,
                  itemBuilder: (context, index) {
                    final categoryName = categoryNames[index];
                    final bool isSelected = categoryName == _selectedCategory;
                    final bool isOfferButton = categoryName == 'العروض';

                    return Padding(
                      padding: EdgeInsets.only(
                          right: index == 0 ? 12 : 0, left: 8),
                      child: ChoiceChip(
                        label: Text(categoryName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = categoryName);
                            widget.onCategorySelected(categoryName);
                          }
                        },
                        avatar: isOfferButton
                            ? Icon(
                                Remix.fire_fill,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.redAccent,
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
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                            color: Theme.of(context).brightness ==
                                    Brightness.light
                                ? Colors.grey.shade300
                                : Colors.grey.shade900),
                        checkmarkColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  },
                ),
              ),

              // ── زر تبديل طريقة العرض ────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 10),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: IconButton(
                    key: ValueKey(widget.isListView),
                    onPressed: widget.onLayoutToggle,
                    icon: Icon(
                      widget.isListView
                          ? Remix.layout_grid_line
                          : Remix.list_unordered,
                      size: 22,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      foregroundColor:
                          Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.all(6),
                    ),
                    tooltip:
                        widget.isListView ? 'عرض شبكي' : 'عرض قائمة',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
