import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/image_viewer.dart';
import '../services/cart_service.dart';

class MealCardList extends StatefulWidget {
  final String mealId;
  final Map<String, dynamic> mealData;
  final bool isFavorite;
  final Color categoryColor;
  final String? userId;
  final void Function(String mealId, bool isFavorite) onFavoriteToggle;

  const MealCardList({
    Key? key,
    required this.mealId,
    required this.mealData,
    required this.isFavorite,
    required this.categoryColor,
    required this.userId,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  State<MealCardList> createState() => _MealCardListState();
}

class _MealCardListState extends State<MealCardList>
    with SingleTickerProviderStateMixin {
  late AnimationController _addController;
  late Animation<double> _scaleAnim;
  bool _addedFeedback = false;

  @override
  void initState() {
    super.initState();
    _addController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _addController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _handleAddToCart() async {
    final originalPrice = widget.mealData['price'] as num?;
    final discountPrice = widget.mealData['discountPrice'] as num?;
    final bool hasDiscount = discountPrice != null &&
        originalPrice != null &&
        discountPrice < originalPrice;
    final finalPrice = hasDiscount ? discountPrice : originalPrice;
    if (finalPrice == null) return;

    await _addController.forward();
    await _addController.reverse();
    if (!mounted) return;
    setState(() => _addedFeedback = true);
    // ignore: use_build_context_synchronously
    addToCart(context, widget.mealId, widget.mealData, finalPrice);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _addedFeedback = false);
  }

  @override
  Widget build(BuildContext context) {
    final mealData = widget.mealData;
    final mealId = widget.mealId;
    final originalPrice = mealData['price'] as num?;
    final discountPrice = mealData['discountPrice'] as num?;
    final bool hasDiscount = discountPrice != null &&
        originalPrice != null &&
        discountPrice < originalPrice;
    final finalPrice = hasDiscount ? discountPrice : originalPrice;
    final categoryName = mealData['category'] ?? '';
    final description = mealData['description'] as String? ?? '';
    final bool isAvailable = mealData['isAvailable'] != false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      key: ValueKey(mealId),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── الصورة على اليسار ─────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).push(PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => ImageViewerScreen(
                          imageUrl: mealData['imageUrl'] ?? '',
                          heroTag: '${mealId}_list',
                        ),
                      ));
                    },
                    child: Hero(
                      tag: '${mealId}_list',
                      child: CachedNetworkImage(
                        imageUrl: mealData['imageUrl'] ?? '',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 100,
                          height: 100,
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image,
                              size: 30, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                // غير متاح
                if (!isAvailable)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        alignment: Alignment.center,
                        child: const Text('غير متاح',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                // شارة الخصم
                if (hasDiscount)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(((originalPrice - discountPrice) / originalPrice) * 100).round()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── المحتوى النصي ─────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم
                  Text(
                    mealData['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // التصنيف
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      categoryName,
                      style: TextStyle(
                          color: widget.categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                  // الوصف
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // السعر + زر السلة + زر المفضلة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // السعر
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              '${originalPrice} ر',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '${finalPrice ?? 0} ر',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount
                                  ? Colors.redAccent
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      // أزرار المفضلة + السلة
                      Row(
                        children: [
                          if (widget.userId != null)
                            GestureDetector(
                              onTap: () => widget.onFavoriteToggle(
                                  widget.mealId, widget.isFavorite),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: widget.isFavorite
                                      ? Colors.redAccent.withOpacity(0.12)
                                      : (isDark
                                          ? Colors.white10
                                          : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: widget.isFavorite
                                        ? Colors.redAccent.withOpacity(0.4)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: widget.isFavorite
                                      ? Colors.redAccent
                                      : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          ScaleTransition(
                            scale: _scaleAnim,
                            child: GestureDetector(
                              onTap: isAvailable ? _handleAddToCart : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? (_addedFeedback
                                          ? Colors.green
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary)
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _addedFeedback ? Icons.check : Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
