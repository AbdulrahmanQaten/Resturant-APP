import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cart_service.dart';
import '../widgets/image_viewer.dart';
import '../widgets/category_bar.dart';
import '../widgets/promo_banner.dart';
import '../widgets/search_bar.dart';

// --- دالة مساعدة لمعالجة بيانات التصنيفات ---
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

// --- ويدجت مساعد لتثبيت شريط التصنيفات ---
class _SliverCategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final CategoryBar categoryBar;

  _SliverCategoryBarDelegate(this.categoryBar);

  @override
  double get minExtent => 50.0;
  @override
  double get maxExtent => 50.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: categoryBar,
    );
  }

  @override
  bool shouldRebuild(_SliverCategoryBarDelegate oldDelegate) {
    return false;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _addToCart(
      String mealId, Map<String, dynamic> mealData, num finalPrice) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartItemData = Map<String, dynamic>.from(mealData);
    cartItemData.remove('discountPrice');
    cartItemData['price'] = finalPrice;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(mealId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(cartRef);
      if (!snapshot.exists) {
        transaction.set(cartRef, {
          ...cartItemData,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp()
        });
      } else {
        final newQuantity = (snapshot.data()!['quantity'] ?? 0) + 1;
        transaction.update(cartRef, {'quantity': newQuantity});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تمت إضافة "${mealData['name']}" إلى السلة!'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollStartNotification) {
              FocusScope.of(context).unfocus();
            }
            return false;
          },
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('categories').snapshots(),
            builder: (context, categorySnapshot) {
              if (!categorySnapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final categoryColors =
                  _processCategoryColors(categorySnapshot.data!);

              return StreamBuilder<QuerySnapshot>(
                stream: userId != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('favorites')
                        .snapshots()
                    : Stream<QuerySnapshot>.empty(),
                builder: (context, favoritesSnapshot) {
                  final favoriteMealIds = favoritesSnapshot.hasData
                      ? favoritesSnapshot.data!.docs
                          .map((doc) => doc.id)
                          .toSet()
                      : <String>{};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('meals')
                        .snapshots(),
                    builder: (context, mealSnapshot) {
                      if (!mealSnapshot.hasData)
                        return const Center(child: CircularProgressIndicator());

                      var meals = mealSnapshot.data!.docs;

                      // ---===  المنطق الجديد هنا: التحقق من وجود عروض أولاً  ===---
                      final bool hasAnyOffers = meals.any((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final discountPrice = data['discountPrice'] as num?;
                        return discountPrice != null && discountPrice > 0;
                      });

                      // ---===  منطق الفلترة الشامل  ===---
                      if (_selectedCategory == 'العروض') {
                        meals = meals.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final discountPrice = data['discountPrice'] as num?;
                          return discountPrice != null && discountPrice > 0;
                        }).toList();
                      } else if (_selectedCategory != 'الكل') {
                        meals = meals.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['category'] == _selectedCategory;
                        }).toList();
                      }

                      if (_searchQuery.isNotEmpty) {
                        meals = meals.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              (data['name'] as String? ?? '').toLowerCase();
                          return name.contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      return CustomScrollView(
                        key: const PageStorageKey<String>(
                            'homeScreenScrollView'),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SearchBarWidget(
                                onSearchChanged: _onSearchChanged),
                          ),
                          SliverToBoxAdapter(
                            child: const PromoBanner(),
                          ),
                          SliverPersistentHeader(
                            delegate: _SliverCategoryBarDelegate(
                              CategoryBar(
                                  onCategorySelected: _onCategorySelected,
                                  hasOffers: hasAnyOffers),
                            ),
                            pinned: true,
                          ),
                          if (meals.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty
                                          ? Icons.search_off
                                          : Icons.restaurant_menu,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'لا توجد نتائج بحث!'
                                          : 'لا توجد وجبات في هذا التصنيف!',
                                      style: const TextStyle(
                                          fontSize: 22, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.all(12.0),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12.0,
                                  mainAxisSpacing: 12.0,
                                  childAspectRatio: 0.68,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final mealDoc = meals[index];
                                    final mealData =
                                        mealDoc.data() as Map<String, dynamic>;
                                    final mealId = mealDoc.id;
                                    final categoryName =
                                        mealData['category'] ?? 'غير مصنف';
                                    final lookupKey =
                                        categoryName.trim().toLowerCase();
                                    final categoryColor =
                                        categoryColors[lookupKey] ??
                                            Colors.grey;
                                    final bool isFavorite =
                                        favoriteMealIds.contains(mealId);
                                    final originalPrice =
                                        mealData['price'] as num?;
                                    final discountPrice =
                                        mealData['discountPrice'] as num?;
                                    final bool hasDiscount =
                                        discountPrice != null &&
                                            originalPrice != null &&
                                            discountPrice < originalPrice;

                                    return Card(
                                      key: ValueKey(mealId),
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    Navigator.of(context)
                                                        .push(PageRouteBuilder(
                                                      opaque: false,
                                                      pageBuilder: (_, __,
                                                              ___) =>
                                                          ImageViewerScreen(
                                                              imageUrl: mealData[
                                                                      'imageUrl'] ??
                                                                  '',
                                                              heroTag: mealId),
                                                    ));
                                                  },
                                                  child: Hero(
                                                    tag: mealId,
                                                    child: CachedNetworkImage(
                                                      imageUrl: mealData[
                                                              'imageUrl'] ??
                                                          '',
                                                      fit: BoxFit.cover,
                                                      placeholder: (context,
                                                              url) =>
                                                          Container(
                                                              color: Colors
                                                                  .grey[200]),
                                                      errorWidget: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 40,
                                                              color:
                                                                  Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                                if (userId != null)
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: CircleAvatar(
                                                      backgroundColor: Colors
                                                          .white
                                                          .withOpacity(0.7),
                                                      radius: 18,
                                                      child: IconButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        icon: Icon(
                                                          isFavorite
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          color: isFavorite
                                                              ? Colors.redAccent
                                                              : Colors.grey,
                                                          size: 22,
                                                        ),
                                                        onPressed: () {
                                                          final favoriteRef =
                                                              FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'users')
                                                                  .doc(userId)
                                                                  .collection(
                                                                      'favorites')
                                                                  .doc(mealId);
                                                          if (isFavorite) {
                                                            favoriteRef
                                                                .delete();
                                                          } else {
                                                            favoriteRef.set({
                                                              'addedAt':
                                                                  Timestamp
                                                                      .now()
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                if (hasDiscount)
                                                  Positioned(
                                                    top: 10,
                                                    left: -30,
                                                    child: Transform.rotate(
                                                      angle: -45 *
                                                          (3.14159265359 / 180),
                                                      child: Container(
                                                        color: Colors.redAccent,
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 40,
                                                                vertical: 4),
                                                        child: const Text('عرض',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
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
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        mealData['name'] ??
                                                            'اسم الوجبة',
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: categoryColor
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Text(
                                                          categoryName,
                                                          style: TextStyle(
                                                              color:
                                                                  categoryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 11),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (hasDiscount)
                                                            Text(
                                                              '${originalPrice ?? 0} ريال',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                          .grey[
                                                                      500],
                                                                  decoration:
                                                                      TextDecoration
                                                                          .lineThrough),
                                                            ),
                                                          Text(
                                                            '${hasDiscount ? discountPrice : originalPrice ?? 0} ريال',
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: hasDiscount
                                                                    ? Colors
                                                                        .redAccent
                                                                    : Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary),
                                                          ),
                                                        ],
                                                      ),
                                                      CircleAvatar(
                                                        radius: 18,
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                        child: IconButton(
                                                          icon: const Icon(
                                                              Icons
                                                                  .add_shopping_cart,
                                                              color:
                                                                  Colors.white),
                                                          onPressed: () {
                                                            final finalPrice =
                                                                hasDiscount
                                                                    ? discountPrice
                                                                    : originalPrice;
                                                            if (finalPrice !=
                                                                null) {
                                                              addToCart(
                                                                  context,
                                                                  mealId,
                                                                  mealData,
                                                                  finalPrice);
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
                                  childCount: meals.length,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
