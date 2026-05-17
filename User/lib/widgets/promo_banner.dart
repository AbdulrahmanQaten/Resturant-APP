import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'image_viewer.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({Key? key}) : super(key: key);

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  static const int _initialPage = 5000;
  late PageController _pageController;
  int _currentPage = _initialPage;
  Timer? _timer;
  int _previousBannerCount = 0; // لتتبع عدد البانرات السابق

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int pageCount) {
    _timer?.cancel();
    if (pageCount > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        _currentPage++;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .orderBy('orderIndex')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data!.docs;

        // ---===  الإصلاح النهائي هنا: إعادة ضبط الحالة عند تغير عدد البانرات  ===---
        if (banners.length != _previousBannerCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _timer?.cancel(); // إيقاف المؤقت دائماً عند التغيير

              if (banners.length > 1) {
                // إذا أصبح لدينا أكثر من بانر، اذهب للمنتصف وابدأ المؤقت
                _pageController.jumpToPage(_initialPage);
                _startTimer(banners.length);
              } else {
                // إذا أصبح لدينا بانر واحد أو صفر، اذهب للبداية
                _pageController.jumpToPage(0);
              }
            }
          });
          _previousBannerCount = banners.length;
        }
        // ---===================================================================---

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: banners.length > 1 ? 10000 : banners.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final currentBannerIndex = index % banners.length;
                  final bannerDoc = banners[currentBannerIndex];
                  final bannerData = bannerDoc.data() as Map<String, dynamic>;
                  final imageUrl = bannerData['imageUrl'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    color: Colors.grey),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.4),
                            radius: 18,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Remix.fullscreen_line,
                                  color: Colors.white, size: 20),
                              onPressed: () {
                                _timer?.cancel();
                                Navigator.of(context)
                                    .push(PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) =>
                                      ImageViewerScreen(
                                    imageUrl: imageUrl,
                                    heroTag: 'banner_${bannerDoc.id}',
                                  ),
                                ))
                                    .then((_) {
                                  _startTimer(banners.length);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (banners.length > 1)
                Positioned(
                  bottom: 10.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(banners.length, (index) {
                      final isSelected =
                          (_currentPage % banners.length) == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: isSelected ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
