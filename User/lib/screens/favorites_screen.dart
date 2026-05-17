import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/image_viewer.dart';
import '../services/cart_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, Color> _processCategoryColors(QuerySnapshot categorySnapshot) {
    final Map<String, Color> loadedColors = {};
    for (var doc in categorySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final colorString = data['color'] as String? ?? '808080';
      final color = Color(int.parse('0xFF$colorString'));
      final categoryName = data['name'] as String? ?? 'غير مصنف';
      loadedColors[categoryName.trim().toLowerCase()] = color;
    }
    return loadedColors;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Force rebuild when theme changes
    final brightness = Theme.of(context).brightness;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('يرجى تسجيل الدخول لعرض المفضلة.'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, categorySnapshot) {
          if (!categorySnapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final categoryColors = _processCategoryColors(categorySnapshot.data!);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('favorites')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Remix.heart_line,
                          size: 50,
                          color: Colors.grey), // يمكنك تغيير أيقونة حسب الحاجة
                      SizedBox(height: 10),
                      Text('لم تقم بإضافة أي وجبات للمفضلة بعد!',
                          style: TextStyle(fontSize: 22, color: Colors.grey)),
                    ],
                  ),
                );
              }

              final favoriteMealIds =
                  snapshot.data!.docs.map((doc) => doc.id).toList();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('meals')
                    .where(FieldPath.documentId, whereIn: favoriteMealIds)
                    .snapshots(),
                builder: (context, mealSnapshot) {
                  if (!mealSnapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final favoriteMeals = mealSnapshot.data!.docs;

                  return GridView.builder(
                    key: const PageStorageKey<String>('favoritesGrid'),
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: favoriteMeals.length,
                    itemBuilder: (context, index) {
                      final mealDoc = favoriteMeals[index];
                      final mealData = mealDoc.data() as Map<String, dynamic>;
                      final mealId = mealDoc.id;
                      final categoryName = mealData['category'] ?? 'غير مصنف';
                      final lookupKey = categoryName.trim().toLowerCase();
                      final categoryColor =
                          categoryColors[lookupKey] ?? Colors.grey;

                      final originalPrice = mealData['price'] as num?;
                      final discountPrice = mealData['discountPrice'] as num?;
                      final bool hasDiscount = discountPrice != null &&
                          originalPrice != null &&
                          discountPrice < originalPrice;

                      return Card(
                        key: ValueKey(mealId),
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(PageRouteBuilder(
                                        opaque: false,
                                        pageBuilder: (_, __, ___) =>
                                            ImageViewerScreen(
                                                imageUrl:
                                                    mealData['imageUrl'] ?? '',
                                                heroTag: 'fav_$mealId'),
                                      ));
                                    },
                                    child: Hero(
                                      tag: 'fav_$mealId',
                                      child: CachedNetworkImage(
                                        imageUrl: mealData['imageUrl'] ?? '',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(color: Colors.grey[200]),
                                        errorWidget: (context, error,
                                                stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.7),
                                      radius: 18,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Remix.heart_fill,
                                            color: Colors.redAccent, size: 22),
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .collection('favorites')
                                              .doc(mealId)
                                              .delete();
                                        },
                                      ),
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Positioned(
                                      top: 10,
                                      left: -30,
                                      child: Transform.rotate(
                                        angle: -45 * (3.14159265359 / 180),
                                        child: Container(
                                          color: Colors.redAccent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40, vertical: 4),
                                          child: const Text('عرض',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mealData['name'] ?? 'اسم الوجبة',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color:
                                                categoryColor.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            categoryName,
                                            style: TextStyle(
                                                color: categoryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (hasDiscount)
                                              Text(
                                                '${originalPrice ?? 0} ريال',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                    decoration: TextDecoration
                                                        .lineThrough),
                                              ),
                                            Text(
                                              '${hasDiscount ? discountPrice : originalPrice ?? 0} ريال',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: hasDiscount
                                                      ? Colors.redAccent
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                            ),
                                          ],
                                        ),
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          child: IconButton(
                                            icon: const Icon(
                                                Icons.add_shopping_cart,
                                                color: Colors.white),
                                            onPressed: () {
                                              final finalPrice = hasDiscount
                                                  ? discountPrice
                                                  : originalPrice;
                                              if (finalPrice != null) {
                                                addToCart(context, mealId,
                                                    mealData, finalPrice);
                                              }
                                            },
                                            iconSize: 18,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
