import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';

class EditPageScreen extends StatefulWidget {
  final DocumentSnapshot pageDoc;

  const EditPageScreen({Key? key, required this.pageDoc}) : super(key: key);

  @override
  State<EditPageScreen> createState() => _EditPageScreenState();
}

class _EditPageScreenState extends State<EditPageScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String _pageTitle = '';

  @override
  void initState() {
    super.initState();
    final data = widget.pageDoc.data() as Map<String, dynamic>;
    _pageTitle = data['title'] ?? 'تعديل الصفحة';
    _contentController.text = data['content'] ?? '';
  }

  // --- دالة مساعدة لتطبيق التنسيق على النص المحدد ---
  void _applyFormat(String startTag, String endTag) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.isValid) {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$startTag$selectedText$endTag',
      );
      _contentController.text = newText;
      // إعادة تحديد النص بعد التعديل
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(
            offset: selection.start +
                startTag.length +
                selectedText.length +
                endTag.length),
      );
    }
  }

  void _applyListFormat() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.isValid) {
      final selectedLines = selection.textInside(text).split('\n');
      final formattedLines = selectedLines.map((line) => '* $line').join('\n');
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        formattedLines,
      );
      _contentController.text = newText;
    }
  }

  Future<void> _savePage() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى ملء حقل المحتوى.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.pageDoc.reference.update({
        'content': _contentController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حفظ التغييرات بنجاح!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل: $_pageTitle'),
        centerTitle: true,
        actions: [
          if (_isLoading)
            Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ))),
          if (!_isLoading)
            IconButton(icon: const Icon(Remix.save_line), onPressed: _savePage),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ---===  شريط أدوات التنسيق المخصص  ===---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Remix.bold),
                    tooltip: 'عريض',
                    onPressed: () => _applyFormat('**', '**'),
                  ),
                  IconButton(
                    icon: const Icon(Remix.italic),
                    tooltip: 'مائل',
                    onPressed: () => _applyFormat('*', '*'),
                  ),
                  IconButton(
                    icon: const Icon(Remix.h_2),
                    tooltip: 'عنوان فرعي',
                    onPressed: () => _applyFormat('\n**', '**\n'),
                  ),
                  IconButton(
                    icon: const Icon(Remix.list_unordered),
                    tooltip: 'قائمة نقطية',
                    onPressed: _applyListFormat,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ---===  حقل النص الرئيسي  ===---
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'اكتب هنا...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: null, // للسماح بعدد لا نهائي من الأسطر
                expands: true, // لجعل الحقل يملأ المساحة المتاحة
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
