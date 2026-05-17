import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;

  const SearchBarWidget({
    Key? key,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // إضافة مستمع لإعادة بناء الواجهة عند تغيير النص (لإظهار/إخفاء زر الحذف)
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _controller,
        autofocus: false,
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'ابحث عن وجبتك المفضلة...',
          prefixIcon: const Icon(Remix.search_line),
          // إظهار زر الحذف فقط إذا كان هناك نص
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Remix.close_line),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                    // إخفاء لوحة المفاتيح
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xff575656) // للثيم الداكن
              : const Color(0xffeeeeee),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
      ),
    );
  }
}
