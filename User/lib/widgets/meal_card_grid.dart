import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/image_viewer.dart';
import '../services/cart_service.dart';

class MealCardGrid extends StatefulWidget {
  final String mealId;
  final Map<String, dynamic> mealData;
  final bool isFavorite;
  final Color categoryColor;
  final String? userId;
  final void Function(String mealId, bool isFavorite) onFavoriteToggle;

  const MealCardGrid({
    Key? key,
    required this.mealId,
    required this.mealData,
    required this.isFavorite,
    required this.categoryColor,
    required this.userId,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  State<MealCardGrid> createState() => _MealCardGridState();
}

class _MealCardGridState extends State<MealCardGrid>
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
    final bool isAvailable = mealData['isAvailable'] != false;

    return Card(
      key: ValueKey(mealId),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── الصورة الخلفية ──────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).push(PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => ImageViewerScreen(
                    imageUrl: mealData['imageUrl'] ?? '',
                    heroTag: mealId,
                  ),
                ));
              },
              child: Hero(
                tag: mealId,
                child: CachedNetworkImage(
                  imageUrl: mealData['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child:
                        const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          // ── Gradient overlay من الأسفل ────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.82),
                  ],
                ),
              ),
            ),
          ),

          // ── غير متاح overlay ─────────────────────────────
          if (!isAvailable)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.55),
                alignment: Alignment.center,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('غير متاح',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
            ),

          // ── شارة التصنيف — أعلى اليسار ───────────────────
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.categoryColor.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categoryName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ── شارة "عرض" — أعلى اليمين ─────────────────────
          if (hasDiscount)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer,
                        color: Colors.white, size: 10),
                    const SizedBox(width: 3),
                    Text(
                      '${(((originalPrice - discountPrice) / originalPrice) * 100).round()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // ── زر المفضلة — أسفل اليمين أعلى النص ──────────
          if (widget.userId != null)
            Positioned(
              bottom: 58,
              right: 8,
              child: GestureDetector(
                onTap: () =>
                    widget.onFavoriteToggle(widget.mealId, widget.isFavorite),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.isFavorite
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

          // ── الاسم + السعر + زر السلة — أسفل الكارد ──────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // الاسم والسعر
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mealData['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54,
                                  offset: Offset(0, 1))
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (hasDiscount)
                              Text(
                                '$originalPrice',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.white60,
                                ),
                              ),
                            if (hasDiscount) const SizedBox(width: 6),
                            Text(
                              '${finalPrice ?? 0} ر',
                              style: TextStyle(
                    color: hasDiscount
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // زر الإضافة للسلة
                  const SizedBox(width: 8),
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: GestureDetector(
                      onTap: isAvailable ? _handleAddToCart : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? (_addedFeedback
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
            ),
          ),
        ],
      ),
    );
  }
}
