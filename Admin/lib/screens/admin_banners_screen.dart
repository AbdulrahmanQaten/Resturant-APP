import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/imagekit_service.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({Key? key}) : super(key: key);

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  bool _isUploading = false;
  List<DocumentSnapshot>? _banners;

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    final uploadResult = await ImageKitService.uploadImage(image);

    if (uploadResult != null) {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('banners').get();
      final newIndex = querySnapshot.docs.length;

      await FirebaseFirestore.instance.collection('banners').add({
        'imageUrl': uploadResult['url'],
        'imageFileId': uploadResult['fileId'],
        'createdAt': FieldValue.serverTimestamp(),
        'orderIndex': newIndex,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم رفع البانر بنجاح!'),
            backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('فشل رفع الصورة.'), backgroundColor: Colors.red));
      }
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
    }
  }


  Future<void> _deleteBanner(DocumentSnapshot bannerDoc) async {
    final data = bannerDoc.data() as Map<String, dynamic>;
    final fileId = data['imageFileId'] as String?;

    await bannerDoc.reference.delete();
    if (fileId != null) {
      await ImageKitService.deleteImage(fileId);
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, DocumentSnapshot bannerDoc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا البانر؟'),
        actions: [
          TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('نعم، حذف', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteBanner(bannerDoc);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تم حذف البانر بنجاح.'),
                      backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrder(List<DocumentSnapshot> banners) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < banners.length; i++) {
      batch.update(banners[i].reference, {'orderIndex': i});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة البانر الإعلاني'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('banners')
            .orderBy('orderIndex')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد بانرات إعلانية حالياً.'));
          }

          _banners = snapshot.data!.docs;

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: _banners!.length,
            itemBuilder: (context, index) {
              final bannerDoc = _banners![index];
              final bannerData = bannerDoc.data() as Map<String, dynamic>;

              return Card(
                key: ValueKey(bannerDoc.id),
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: bannerData['imageUrl'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Remix.delete_bin_line,
                              color: Colors.white, size: 20),
                          onPressed: () =>
                              _showDeleteConfirmationDialog(context, bannerDoc),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: ReorderableDragStartListener(
                        index: index,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          radius: 18,
                          child: const Icon(Remix.drag_move_2_line,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _banners!.removeAt(oldIndex);
                _banners!.insert(newIndex, item);

                _updateOrder(_banners!);
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        label: _isUploading
            ? const Text('جاري الرفع...')
            : const Text('إضافة بانر جديد'),
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Remix.add_line),
      ),
    );
  }
}
