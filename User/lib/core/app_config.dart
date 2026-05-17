import 'package:flutter/material.dart';

/// ============================================================
///  ملف الإعداد المركزي للتطبيق
///  لتخصيص هذا التطبيق لمطعم آخر، عدّل هذا الملف فقط.
/// ============================================================
class AppConfig {
  AppConfig._();

  // ── معلومات المطعم ─────────────────────────────────────────
  static const String restaurantName = 'تاج القيصر';
  static const String restaurantFullName = 'مطعم تاج القيصر';
  static const String currency = 'ريال';
  static const String countryCode = '+967';

  // ── ألوان الثيم الفاتح ────────────────────────────────────
  static const Color primaryColor = Color(0xFF6a2e0e);
  static const Color secondaryColor = Color(0xFFf39c12);

  // ── ألوان الثيم الداكن ────────────────────────────────────
  static const Color primaryColorDark = Color(0xFF8B4513);
  static const Color secondaryColorDark = Color(0xFFFFB74D);
}
