import 'package:flutter/material.dart';

class ThemeAwareImage extends StatelessWidget {
  final String imagePath;
  final double height;

  const ThemeAwareImage({
    Key? key,
    required this.imagePath,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // تحديد ما إذا كان الوضع داكنًا أو فاتحًا
    if (Theme.of(context).brightness == Brightness.dark) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.8), // في الوضع الداكن
          BlendMode.srcIn, // المزج مع اللون المضاف
        ),
        child: Image.asset(
          imagePath,
          height: height,
        ),
      );
    } else {
      return Image.asset(
        imagePath,
        height: height,
      );
    }
  }
}
