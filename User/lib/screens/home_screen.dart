import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/category_bar.dart';
import '../widgets/promo_banner.dart';
import '../widgets/search_bar.dart';
import '../widgets/meal_card_grid.dart';
import '../widgets/meal_card_list.dart';

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
  final Widget child;
  const _SliverCategoryBarDelegate(this.child);

  @override
  double get minExtent => 50.0;
  @override
  double get maxExtent => 50.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverCategoryBarDelegate oldDelegate) => true;
}

// ── مفتاح حفظ تفضيل المستخدم ──────────────────────────────────
const String _kLayoutPrefKey = 'meal_layout_is_list';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  bool _isListView = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadLayoutPreference();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── تحميل تفضيل العرض من SharedPreferences ────────────────
  Future<void> _loadLayoutPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kLayoutPrefKey);
    if (saved != null && mounted) {
      setState(() => _isListView = saved);
    }
  }

  // ── تبديل طريقة العرض وحفظها ──────────────────────────────
  Future<void> _toggleLayout() async {
    // fade out → تبديل → fade in
    await _fadeController.reverse();
    setState(() => _isListView = !_isListView);
    _fadeController.forward();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLayoutPrefKey, _isListView);
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  // ── تبديل المفضلة ──────────────────────────────────────────
  void _toggleFavorite(String mealId, bool isFavorite) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(mealId);
    if (isFavorite) {
      favoriteRef.delete();
    } else {
      favoriteRef.set({'addedAt': DateTime.now()});
    }
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
            stream: FirebaseFirestore.instance
                .collection('categories')
                .snapshots(),
            builder: (context, categorySnapshot) {
              if (!categorySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
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
                      if (!mealSnapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      var meals = mealSnapshot.data!.docs;

                      // --- فلترة العروض ---
                      final bool hasAnyOffers = meals.any((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final discountPrice =
                            data['discountPrice'] as num?;
                        return discountPrice != null && discountPrice > 0;
                      });

                      // --- فلترة التصنيف ---
                      if (_selectedCategory == 'العروض') {
                        meals = meals.where((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final discountPrice =
                              data['discountPrice'] as num?;
                          return discountPrice != null &&
                              discountPrice > 0;
                        }).toList();
                      } else if (_selectedCategory != 'الكل') {
                        meals = meals.where((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return data['category'] == _selectedCategory;
                        }).toList();
                      }

                      // --- فلترة البحث ---
                      if (_searchQuery.isNotEmpty) {
                        meals = meals.where((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final name = (data['name'] as String? ?? '')
                              .toLowerCase();
                          return name
                              .contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      // ── بناء الـ CategoryBar مع زر التبديل ──
                      final categoryBarWidget = CategoryBar(
                        onCategorySelected: _onCategorySelected,
                        hasOffers: hasAnyOffers,
                        onLayoutToggle: _toggleLayout,
                        isListView: _isListView,
                      );

                      return CustomScrollView(
                        key: const PageStorageKey<String>(
                            'homeScreenScrollView'),
                        slivers: [
                          // ── شريط البحث ────────────────────
                          SliverToBoxAdapter(
                            child: SearchBarWidget(
                                onSearchChanged: _onSearchChanged),
                          ),

                          // ── البنرات ───────────────────────
                          const SliverToBoxAdapter(
                            child: PromoBanner(),
                          ),

                          // ── شريط التصنيفات + زر التبديل ──
                          SliverPersistentHeader(
                            delegate: _SliverCategoryBarDelegate(
                                categoryBarWidget),
                            pinned: true,
                          ),

                          // ── حالة فارغة ───────────────────
                          if (meals.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty
                                          ? Icons.search_off
                                          : Icons.restaurant_menu,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'لا توجد نتائج بحث!'
                                          : 'لا توجد وجبات في هذا التصنيف!',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          // ── عرض الوجبات: شبكة أو قائمة مع fade ──
                          else if (_isListView)
                            SliverFadeTransition(
                              opacity: _fadeAnimation,
                              sliver: _buildListView(
                                  meals, categoryColors,
                                  favoriteMealIds, userId),
                            )
                          else
                            SliverFadeTransition(
                              opacity: _fadeAnimation,
                              sliver: _buildGridView(
                                  meals, categoryColors,
                                  favoriteMealIds, userId),
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

  // ── عرض شبكي (2 عمود) ─────────────────────────────────────
  Widget _buildGridView(
    List<QueryDocumentSnapshot> meals,
    Map<String, Color> categoryColors,
    Set<String> favoriteMealIds,
    String? userId,
  ) {
    return SliverPadding(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final mealDoc = meals[index];
            final mealData = mealDoc.data() as Map<String, dynamic>;
            final mealId = mealDoc.id;
            final categoryName = mealData['category'] ?? 'غير مصنف';
            final lookupKey = categoryName.trim().toLowerCase();
            final categoryColor =
                categoryColors[lookupKey] ?? Colors.grey;
            final bool isFavorite = favoriteMealIds.contains(mealId);

            return MealCardGrid(
              key: ValueKey(mealId),
              mealId: mealId,
              mealData: mealData,
              isFavorite: isFavorite,
              categoryColor: categoryColor,
              userId: userId,
              onFavoriteToggle: _toggleFavorite,
            );
          },
          childCount: meals.length,
        ),
      ),
    );
  }

  // ── عرض قائمة ─────────────────────────────────────────────
  Widget _buildListView(
    List<QueryDocumentSnapshot> meals,
    Map<String, Color> categoryColors,
    Set<String> favoriteMealIds,
    String? userId,
  ) {
    return SliverPadding(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final mealDoc = meals[index];
            final mealData = mealDoc.data() as Map<String, dynamic>;
            final mealId = mealDoc.id;
            final categoryName = mealData['category'] ?? 'غير مصنف';
            final lookupKey = categoryName.trim().toLowerCase();
            final categoryColor =
                categoryColors[lookupKey] ?? Colors.grey;
            final bool isFavorite = favoriteMealIds.contains(mealId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MealCardList(
                key: ValueKey(mealId),
                mealId: mealId,
                mealData: mealData,
                isFavorite: isFavorite,
                categoryColor: categoryColor,
                userId: userId,
                onFavoriteToggle: _toggleFavorite,
              ),
            );
          },
          childCount: meals.length,
        ),
      ),
    );
  }
}
