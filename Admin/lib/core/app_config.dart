import 'dart:convert';
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

  // ── مفاتيح ImageKit (مشفرة بـ XOR لمنع الاستخراج السهل) ──
  // ملاحظة: ابنِ التطبيق دائماً بـ --obfuscate لحماية إضافية.
  // لتغيير المفاتيح: استخدم دالة _encode أدناه لإنشاء مصفوفات جديدة.
  static const int _kSalt = 0x5A;

  static const List<int> _kPub = [
    0x2A, 0x2F, 0x38, 0x36, 0x33, 0x39, 0x05, 0x13,
    0x0B, 0x29, 0x6A, 0x0D, 0x6E, 0x10, 0x08, 0x09,
    0x13, 0x15, 0x6A, 0x36, 0x33, 0x20, 0x35, 0x34,
    0x63, 0x38, 0x08, 0x0B, 0x0A, 0x0E, 0x0E, 0x2A,
    0x0A, 0x17, 0x67,
  ]; // public key (XOR encoded)

  static const List<int> _kPriv = [
    0x2A, 0x28, 0x33, 0x2C, 0x3B, 0x2E, 0x3F, 0x05,
    0x62, 0x0B, 0x1D, 0x75, 0x1E, 0x09, 0x2A, 0x63,
    0x69, 0x6A, 0x22, 0x13, 0x30, 0x1D, 0x2A, 0x00,
    0x6C, 0x2B, 0x37, 0x31, 0x03, 0x11, 0x6B, 0x33,
    0x20, 0x75, 0x1F, 0x67,
  ]; // private key (XOR encoded)

  static String get imagekitPublicKey =>
      String.fromCharCodes(_kPub.map((b) => b ^ _kSalt));

  static String get imagekitPrivateKey =>
      String.fromCharCodes(_kPriv.map((b) => b ^ _kSalt));
}
