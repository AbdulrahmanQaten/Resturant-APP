# 📖 دليل تخصيص تطبيق المطعم لأي عميل جديد

> هذا الدليل يوضح الخطوات الكاملة من الصفر حتى الإطلاق.  
> الوقت المتوقع: **30–60 دقيقة** لكل مطعم جديد.

---

## المرحلة 1: تعديل الكود (5 دقائق)

### الملف الوحيد الذي تحتاج تعديله لكل مطعم جديد:

**`Admin/lib/core/app_config.dart`** و **`User/lib/core/app_config.dart`**

```dart
class AppConfig {
  // ───── غيّر هذه القيم فقط ──────────────────────────────────────

  static const String restaurantName     = 'اسم المطعم';       // ← غيّر
  static const String restaurantFullName = 'مطعم اسم المطعم';  // ← غيّر
  static const String currency           = 'ريال';             // ← غيّر (ريال / دينار / جنيه...)
  static const String countryCode        = '+967';             // ← غيّر (+966 / +973 / +20...)

  static const Color primaryColor        = Color(0xFF6a2e0e);  // ← لون المطعم الرئيسي
  static const Color primaryColorDark    = Color(0xFF8B4513);  // ← نسخة أفتح للثيم الداكن
  static const Color secondaryColor      = Color(0xFFf39c12);  // ← اللون الثانوي
  static const Color secondaryColorDark  = Color(0xFFFFB74D);  // ← نسخة أفتح للثيم الداكن

  // ───── مفاتيح ImageKit الخاصة بهذا المطعم ──────────────────────
  // (مشفرة بـ XOR - انظر قسم "كيف تحدّث مفاتيح ImageKit" أدناه)
  static const int _kSalt = 0x5A;
  static const List<int> _kPub  = [ /* مصفوفة XOR للمفتاح العام */ ];
  static const List<int> _kPriv = [ /* مصفوفة XOR للمفتاح الخاص */ ];
}
```

> [!TIP]
> لاختيار الألوان بسرعة: استخدم موقع [coolors.co](https://coolors.co) أو [colorhunt.co](https://colorhunt.co)،  
> ثم حوّل اللون HEX مثل `#6a2e0e` إلى `Color(0xFF6a2e0e)` بإضافة `FF` في البداية.

---

## كيف تحدّث مفاتيح ImageKit للمطعم الجديد؟

1. سجّل حساباً جديداً على [imagekit.io](https://imagekit.io) للمطعم
2. افتح **Settings → API Keys** وانسخ Public Key و Private Key
3. شغّل هذا الكود لمرة واحدة في Dart Console لتشفير المفاتيح:

```dart
// شغّله مرة واحدة في https://dartpad.dev لتوليد المصفوفات
void main() {
  const salt = 0x5A;
  const publicKey  = 'YOUR_PUBLIC_KEY';   // ← ضع مفتاحك العام هنا
  const privateKey = 'YOUR_PRIVATE_KEY';  // ← ضع مفتاحك الخاص هنا

  final encPub  = publicKey.codeUnits.map((b) => b ^ salt).toList();
  final encPriv = privateKey.codeUnits.map((b) => b ^ salt).toList();

  print('_kPub  = $encPub');
  print('_kPriv = $encPriv');
}
```

4. انسخ النتيجة وضعها في `app_config.dart`

---

## المرحلة 2: إنشاء مشروع Firebase جديد (10 دقائق)

> [!IMPORTANT]
> كل مطعم = مشروع Firebase منفصل = بياناته معزولة تماماً عن باقي المطاعم.

1. افتح [Firebase Console](https://console.firebase.google.com)
2. **Add Project** → اختر اسم المشروع (مثل: `restaurant-alkhalij`)
3. فعّل **Google Analytics** (اختياري)
4. أنشئ **تطبيق Android** و **تطبيق Web** للحصول على مفاتيح الاتصال

### تحديث مفاتيح Firebase في الكود:

في ملف **`Admin/lib/main.dart`** و **`User/lib/main.dart`**، عدّل هذا الجزء:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey:            'XXXXXXXXXXXXXXXXXX',   // ← من Firebase Console
    authDomain:        'YOUR-PROJECT.firebaseapp.com',
    projectId:         'YOUR-PROJECT-ID',
    storageBucket:     'YOUR-PROJECT.appspot.com',
    messagingSenderId: '000000000000',
    appId:             '1:000000000000:web:XXXXXXXXXXXXXXXX',
  ),
);
```

> [!NOTE]
> للحصول على هذه القيم: Firebase Console → Project Settings → Your Apps → SDK Setup and Configuration

---

## المرحلة 3: إعداد Firestore (5 دقائق)

### تفعيل Firestore:
1. Firebase Console → **Firestore Database** → **Create database**
2. اختر **Start in production mode**
3. اختر المنطقة الأقرب للمطعم

### رفع Security Rules:
1. **Firestore → Rules**
2. احذف كل شيء والصق محتوى ملف `firestore.rules`
3. اضغط **Publish**

---

## المرحلة 4: تحديد المدير (أهم خطوة!) (5 دقائق)

> [!IMPORTANT]
> هذه الخطوة تحدد من هو الشخص الذي سيدير تطبيق الأدمن.  
> بدونها، لا أحد سيستطيع تعديل البيانات حتى من تطبيق الأدمن!

### الخطوات:

**أولاً:** سجّل دخول في تطبيق الأدمن بحساب البريد الإلكتروني الخاص بصاحب المطعم.

**ثانياً:** اعرف الـ UID الخاص بحسابه:
- Firebase Console → **Authentication** → **Users**
- ستجد جدولاً فيه المستخدمين، انسخ الـ **User UID** من العمود الأول

| Identifier | Provider | User UID |
|---|---|---|
| owner@restaurant.com | Email/Password | `abc123xyz...` ← انسخ هذا |

**ثالثاً:** أضف المدير في Firestore:
1. **Firestore → Data**
2. اضغط **Start collection** → اسمها `admins`
3. في **Document ID**: الصق الـ UID الذي نسخته
4. أضف حقل واحد: `email` = بريد صاحب المطعم
5. **Save**

```
admins/
  abc123xyz.../          ← Document ID = UID الأدمن
    email: "owner@restaurant.com"
```

> [!NOTE]
> **سؤالك:** لماذا لا نستخدم `role: 'admin'` في بيانات المستخدم؟  
> لأن قواعد الأمان تسمح للمستخدم بتعديل ملفه الشخصي، فأي شخص ذكي يمكنه كتابة `role: 'admin'` في ملفه ويصبح مديراً! أما `admins` collection فلا يمكن لأحد الكتابة فيها إلا عبر Firebase Console مباشرة.

---

## المرحلة 5: إعداد Firebase Auth (2 دقيقة)

1. Firebase Console → **Authentication** → **Get Started**
2. **Sign-in method** → **Email/Password** → **Enable** → Save

---

## المرحلة 6: بناء التطبيق للنشر

### بناء APK آمن (مع تشفير الكود):
```bash
# Admin App
cd Admin
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# User App  
cd User
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

> [!TIP]
> `--obfuscate` يشفر أسماء الكلاسات والدوال في ملف APK النهائي، مما يجعل الهندسة العكسية أصعب بكثير. استخدمها دائماً في النسخة النهائية.

---

## ✅ قائمة مراجعة سريعة

| # | الخطوة | ✓ |
|---|---|---|
| 1 | تعديل `restaurantName` في `app_config.dart` | ☐ |
| 2 | تعديل `currency` و `countryCode` | ☐ |
| 3 | تغيير ألوان الثيم (`primaryColor`, `secondaryColor`) | ☐ |
| 4 | تحديث مفاتيح ImageKit (XOR-encoded) | ☐ |
| 5 | إنشاء مشروع Firebase جديد | ☐ |
| 6 | تحديث `FirebaseOptions` في `main.dart` للتطبيقَين | ☐ |
| 7 | تفعيل Firestore ورفع Security Rules | ☐ |
| 8 | تفعيل Firebase Authentication | ☐ |
| 9 | إضافة UID الأدمن في collection `admins` | ☐ |
| 10 | بناء APK بـ `--obfuscate` | ☐ |

---

## 📁 ملفات تتغير لكل مطعم

```
Tajalqaisar/
├── Admin/lib/core/app_config.dart    ← ألوان + اسم + مفاتيح ImageKit
├── Admin/lib/main.dart               ← مفاتيح Firebase
├── User/lib/core/app_config.dart     ← ألوان + اسم
├── User/lib/main.dart                ← مفاتيح Firebase
└── firestore.rules                   ← (نفس الملف لكل المطاعم، انسخ ولصق)
```

**إجمالي الملفات المتغيرة: 4 ملفات فقط** ✅
