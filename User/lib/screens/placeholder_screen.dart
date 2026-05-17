import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // استيراد الحزمة الجديدة

class PlaceholderScreen extends StatefulWidget {
  final String title;
  final String pageId;

  const PlaceholderScreen({
    Key? key,
    required this.title,
    required this.pageId,
  }) : super(key: key);

  @override
  State<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends State<PlaceholderScreen> {
  late Future<DocumentSnapshot> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture =
        FirebaseFirestore.instance.collection('pages').doc(widget.pageId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonContent();
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'عذراً، لم يتم العثور على المحتوى.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final pageData = snapshot.data!.data() as Map<String, dynamic>;
          final content = pageData['content'] ?? 'لا يوجد محتوى لهذه الصفحة.';

          // ---===  الحل هنا: استخدام MarkdownBody لعرض المحتوى المنسق  ===---
          return Markdown(
            data: content,
            padding: const EdgeInsets.all(24.0),
            styleSheet: MarkdownStyleSheet(
              p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
              h2: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, height: 2.0),
              // يمكنك إضافة تنسيقات أخرى هنا
            ),
          );
          // ---=============================================================---
        },
      ),
    );
  }

  // --- ويدجت مساعد لبناء الواجهة الهيكلية ---
  Widget _buildSkeletonContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLoader(width: 250, height: 30),
          const SizedBox(height: 24),
          _buildSkeletonLoader(height: 16),
          const SizedBox(height: 12),
          _buildSkeletonLoader(height: 16),
          const SizedBox(height: 12),
          _buildSkeletonLoader(height: 16, width: 180),
          const SizedBox(height: 24),
          _buildSkeletonLoader(height: 16),
          const SizedBox(height: 12),
          _buildSkeletonLoader(height: 16),
          const SizedBox(height: 12),
          _buildSkeletonLoader(height: 16),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader({double? width, double height = 16}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).splashColor,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
