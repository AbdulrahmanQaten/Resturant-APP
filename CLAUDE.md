# CLAUDE.md — وثيقة المشروع الشاملة

> **للمطور أو الفريق القادم:** اقرأ هذا الملف أولاً قبل لمس أي كود.  
> يغطي كل شيء: المعمارية، قرارات التصميم، الأمان، وكيفية التخصيص.

---

## 1. نظرة عامة على المشروع

**تاج القيصر** هو نظام متكامل لإدارة مطعم يتكون من تطبيقَين Flutter مستقلَّين يشتركان في نفس قاعدة بيانات Firebase:

| التطبيق | المجلد | الجمهور |
|---|---|---|
| تطبيق الزبون | `User/` | العملاء — تصفح، طلب، تتبع |
| تطبيق الأدمن | `Admin/` | صاحب المطعم — إدارة كاملة |

**التقنيات الأساسية:**
- **Flutter** (SDK ≥ 3.0.0) — واجهة المستخدم لكلا التطبيقَين
- **Firebase Auth** — تسجيل الدخول
- **Cloud Firestore** — قاعدة البيانات الرئيسية (Real-time)
- **ImageKit.io** — تخزين ورفع الصور (Admin فقط)
- **Provider** — إدارة الحالة (ThemeProvider)
- **Tajawal** — الخط العربي المستخدم في كلا التطبيقَين
- اللغة: **عربي** | الاتجاه: **RTL**

---

## 2. هيكل الملفات الكامل

```
Tajalqaisar/
│
├── firestore.rules              ← قواعد أمان Firebase (مهم جداً)
│
├── Admin/                       ← تطبيق الأدمن
│   └── lib/
│       ├── main.dart            ← نقطة الدخول + إعداد الثيم الكامل
│       ├── core/
│       │   └── app_config.dart  ← ⭐ الملف الأهم للتخصيص
│       ├── providers/
│       │   └── theme_provider.dart
│       ├── services/
│       │   └── imagekit_service.dart  ← خدمة رفع/حذف الصور
│       ├── widgets/
│       │   └── theme_aware_image.dart
│       └── screens/
│           ├── splash_screen.dart
│           ├── admin_login_screen.dart
│           ├── admin_dashboard_screen.dart    ← الرئيسية (قائمة التنقل)
│           ├── admin_meals_screen.dart        ← عرض + حذف الوجبات
│           ├── add_edit_meal_screen.dart      ← إضافة/تعديل وجبة
│           ├── admin_categories_screen.dart   ← التصنيفات (قابلة للترتيب)
│           ├── add_edit_category_screen.dart
│           ├── admin_banners_screen.dart      ← البنرات الإعلانية
│           ├── admin_orders_screen.dart       ← جميع الطلبات
│           ├── admin_order_details_screen.dart
│           ├── admin_analytics_screen.dart    ← تقارير + Excel
│           ├── admin_delivery_zones_screen.dart
│           ├── add_edit_delivery_zone_screen.dart
│           ├── admin_pages_screen.dart        ← صفحات ثابتة (شروط، سياسة)
│           ├── edit_page_screen.dart          ← محرر Markdown
│           ├── admin_settings_screen.dart
│           └── admin_about_screen.dart
│
└── User/                        ← تطبيق الزبون
    └── lib/
        ├── main.dart            ← نقطة الدخول + إعداد الثيم الكامل
        ├── core/
        │   └── app_config.dart  ← ⭐ الملف الأهم للتخصيص (بدون مفاتيح ImageKit)
        ├── providers/
        │   └── theme_provider.dart
        ├── services/
        │   └── cart_service.dart
        ├── widgets/
        │   ├── category_bar.dart       ← شريط التصنيفات + زر تبديل Grid/List
        │   ├── meal_card_grid.dart     ← بطاقة وجبة — عرض شبكي (جديد)
        │   ├── meal_card_list.dart     ← بطاقة وجبة — عرض قائمة (جديد)
        │   ├── promo_banner.dart
        │   ├── search_bar.dart
        │   ├── image_viewer.dart
        │   └── theme_aware_image.dart
        └── screens/
            ├── splash_screen.dart
            ├── auth_gate.dart            ← يوجّه حسب حالة تسجيل الدخول
            ├── login_screen.dart
            ├── register_screen.dart
            ├── forgot_password_screen.dart
            ├── verify_email_screen.dart
            ├── main_screen.dart          ← الشاشة الرئيسية مع Bottom Nav
            ├── home_screen.dart          ← قائمة الطعام + فلتر + بحث
            ├── cart_screen.dart
            ├── checkout_screen.dart      ← تأكيد الطلب + اختيار المنطقة
            ├── orders_screen.dart        ← تاريخ الطلبات + تتبع الحالة
            ├── favorites_screen.dart
            ├── profile_screen.dart
            ├── edit_profile_screen.dart
            ├── addresses_screen.dart
            ├── add_edit_address_screen.dart
            ├── about_screen.dart
            ├── offline_screen.dart       ← يظهر عند انقطاع الإنترنت
            └── placeholder_screen.dart
```

---

## 3. قاعدة بيانات Firestore — الهيكل الكامل

```
Firestore Root
│
├── admins/                    ← المديرون (محمي — لا يُعدَّل إلا من Console)
│   └── {uid}/
│       └── email: string
│
├── users/                     ← بيانات المستخدمين
│   └── {userId}/
│       ├── name: string
│       ├── email: string
│       ├── phone: string      ← بصيغة +967XXXXXXXXX
│       ├── photoUrl: string?
│       ├── createdAt: timestamp
│       │
│       ├── cart/              ← subcollection
│       │   └── {mealId}/
│       │       ├── name, price, imageUrl...
│       │       └── quantity: int
│       │
│       ├── orders/            ← subcollection
│       │   └── {orderId}/
│       │       ├── items: array
│       │       ├── totalPrice: number
│       │       ├── status: string  ← 'pending' | 'preparing' | 'delivering' | 'delivered'
│       │       ├── deliveryZone: string
│       │       ├── address: string
│       │       └── createdAt: timestamp
│       │
│       ├── favorites/         ← subcollection
│       │   └── {mealId}/
│       │       └── (meal data)
│       │
│       └── addresses/         ← subcollection
│           └── {addressId}/
│               └── (address data)
│
├── meals/                     ← قائمة الطعام (قراءة عامة)
│   └── {mealId}/
│       ├── name: string
│       ├── description: string
│       ├── price: number
│       ├── discountPrice: number?
│       ├── category: string   ← ID التصنيف
│       ├── imageUrl: string   ← رابط ImageKit
│       ├── imageFileId: string ← معرّف الصورة في ImageKit (للحذف)
│       ├── isAvailable: bool
│       └── orderIndex: int
│
├── categories/                ← التصنيفات (قراءة عامة)
│   └── {categoryId}/
│       ├── name: string
│       ├── color: string      ← HEX color
│       └── orderIndex: int
│
├── banners/                   ← البنرات الإعلانية (قراءة عامة)
│   └── {bannerId}/
│       ├── imageUrl: string
│       ├── imageFileId: string
│       └── orderIndex: int
│
├── delivery_zones/            ← مناطق التوصيل (قراءة عامة)
│   └── {zoneId}/
│       ├── name: string
│       └── price: number
│
└── pages/                     ← الصفحات المعلوماتية (قراءة عامة للجميع)
    └── {pageId}/              ← مثل: 'about', 'terms', 'privacy'
        ├── title: string
        └── content: string    ← محتوى Markdown
```

---

## 4. الأمان — نقطة محورية

### 4.1 Firestore Security Rules

الملف: `firestore.rules` — **يجب رفعه يدوياً** إلى Firebase Console.

**المبدأ الأساسي:**
```
isAdmin() ← يتحقق من وجود {uid} في collection 'admins'
isOwner() ← يتحقق أن request.auth.uid == userId
```

**لماذا `admins` collection وليس `role` في `users`؟**

> ❌ الخطأ الشائع: تخزين `role: 'admin'` في ملف المستخدم.  
> ✅ المشكلة: المستخدم يملك صلاحية تعديل ملفه الشخصي → يمكنه ترقية نفسه!  
> ✅ الحل: `admins` collection منفصلة بقاعدة `allow read, write: if false` — لا يمكن لأحد الكتابة فيها إلا عبر Firebase Console مباشرة.

**صلاحيات كل entity:**

| Collection | الزبون | الأدمن | الجميع |
|---|---|---|---|
| `meals` | قراءة فقط | قراءة + كتابة | قراءة ✓ |
| `categories` | قراءة فقط | قراءة + كتابة | قراءة ✓ |
| `banners` | قراءة فقط | قراءة + كتابة | قراءة ✓ |
| `delivery_zones` | قراءة فقط | قراءة + كتابة | قراءة ✓ |
| `users/{uid}` | ملفه فقط | قراءة الكل | — |
| `users/{uid}/orders` | إنشاء + قراءة | قراءة + تحديث | — |
| `admins` | ممنوع | ممنوع | — |

**ملاحظة مهمة:** Admin يصل لجميع الطلبات عبر `collectionGroup`:
```javascript
match /{path=**}/orders/{orderId} {
  allow read, update: if isAdmin();
}
```
هذا ضروري لكي تعمل شاشة `admin_orders_screen.dart`.

### 4.2 مفاتيح ImageKit — XOR Obfuscation

المفاتيح **ليست** مخزنة كنص عادي في الكود. بدلاً من ذلك:

```dart
// في Admin/lib/core/app_config.dart
static const int _kSalt = 0x5A;
static const List<int> _kPub  = [ /* أرقام مشفرة */ ];
static const List<int> _kPriv = [ /* أرقام مشفرة */ ];

// فك التشفير عند الاستخدام فقط:
static String get imagekitPublicKey =>
    String.fromCharCodes(_kPub.map((b) => b ^ _kSalt));
```

**لماذا؟** لمنع استخراج المفاتيح بأمر `strings` بسيط على ملف APK.

**تنبيه:** ابنِ التطبيق دائماً بـ:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

---

## 5. نقاط الدخول والتدفق

### Admin App:
```
main.dart → SplashScreen → AdminLoginScreen → AdminDashboardScreen
```

### User App:
```
main.dart → SplashScreen → AuthGate
                              ├── (غير مسجل) → LoginScreen
                              └── (مسجل) → MainScreen (Bottom Nav)
                                              ├── HomeScreen
                                              ├── FavoritesScreen
                                              ├── CartScreen
                                              └── ProfileScreen
```

### تدفق الطلب:
```
HomeScreen → (أضف للسلة) → CartScreen → CheckoutScreen
→ (تأكيد) → كتابة في users/{uid}/orders/{orderId}
→ AdminOrdersScreen (يقرأ بـ collectionGroup)
→ AdminOrderDetailsScreen (تحديث status)
→ OrdersScreen في User App (يعرض الحالة المحدّثة)
```

---

## 6. خدمة ImageKit

**الملف:** `Admin/lib/services/imagekit_service.dart`

جميع عمليات الرفع والحذف مركزية في هذه الخدمة. **لا تكتب كود ImageKit في أي مكان آخر.**

```dart
// رفع صورة
final result = await ImageKitService.uploadImage(xFileImage);
// result = {'url': '...', 'fileId': '...'}
// احفظ كليهما في Firestore

// حذف صورة
await ImageKitService.deleteImage(fileId);
```

**تستخدمها:**
- `add_edit_meal_screen.dart` — عند إضافة/تعديل وجبة
- `admin_banners_screen.dart` — عند إضافة/حذف بنر
- `admin_meals_screen.dart` — عند حذف وجبة

---

## 7. إدارة الثيم

كلا التطبيقَين يدعمان الثيم الفاتح والداكن عبر `ThemeProvider`.

**المفتاح:** كل الألوان مُعرَّفة في `app_config.dart` ومُمرَّرة لـ `MaterialApp` في `main.dart`. لا يوجد لون ثابت (`const Color(...)`) في أي شاشة أخرى — يُستخدم بدلاً منه `Theme.of(context).colorScheme.primary`.

```dart
// app_config.dart
static const Color primaryColor     = Color(0xFF6a2e0e); // الثيم الفاتح
static const Color primaryColorDark = Color(0xFF8B4513); // الثيم الداكن
```

الثيم يُحفظ في `SharedPreferences` عبر `ThemeProvider`.

---

## 8. التخصيص لمطعم جديد

### الملفات التي تتغير فقط (4 ملفات):

```
Admin/lib/core/app_config.dart  ← اسم + ألوان + مفاتيح ImageKit
Admin/lib/main.dart             ← FirebaseOptions
User/lib/core/app_config.dart   ← اسم + ألوان
User/lib/main.dart              ← FirebaseOptions
```

### ما تغيّره في `app_config.dart`:

```dart
static const String restaurantName     = 'اسم المطعم';
static const String restaurantFullName = 'مطعم اسم المطعم';
static const String currency           = 'ريال';   // أو دينار، جنيه...
static const String countryCode        = '+967';   // أو +966، +973...
static const Color  primaryColor       = Color(0xFFXXXXXX);
static const Color  secondaryColor     = Color(0xFFXXXXXX);
```

### لتوليد مصفوفات XOR لمفاتيح ImageKit جديدة:

```dart
// شغّل هذا في https://dartpad.dev
void main() {
  const salt = 0x5A;
  const publicKey  = 'PUBLIC_KEY_HERE';
  const privateKey = 'PRIVATE_KEY_HERE';
  print(_kPub  = ${publicKey.codeUnits.map((b) => '0x${(b ^ salt).toRadixString(16).toUpperCase().padLeft(2, '0')}').toList()});
  print(_kPriv = ${privateKey.codeUnits.map((b) => '0x${(b ^ salt).toRadixString(16).toUpperCase().padLeft(2, '0')}').toList()});
}
```

### الخطوات الكاملة للمطعم الجديد:

للدليل المفصّل، اقرأ: **`customization_guide.md`** (موجود في مجلد المشروع).

**الملخص السريع:**
1. عدّل `app_config.dart` في التطبيقَين
2. أنشئ Firebase Project جديد
3. حدّث `FirebaseOptions` في `main.dart`
4. ارفع `firestore.rules` إلى Firebase Console
5. أنشئ `admins/{uid}` في Firestore لتحديد المدير
6. ابنِ APK بـ `--obfuscate`

---

## 9. الحزم المستخدمة

### Admin App (`Admin/pubspec.yaml`):

| الحزمة | الغرض |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Firebase |
| `image_picker` + `http` | رفع الصور لـ ImageKit |
| `cached_network_image` | تحميل الصور مع cache |
| `fl_chart` | رسوم بيانية في الإحصائيات |
| `excel` + `path_provider` | تصدير تقارير Excel |
| `flutter_colorpicker` | اختيار لون التصنيف |
| `markdown_editable_textinput` | محرر الصفحات المعلوماتية |
| `provider` + `shared_preferences` | إدارة الثيم وحفظه |
| `remixicon` | الأيقونات |
| `intl` | تنسيق التواريخ والأرقام |
| `permission_handler` + `open_file` | حفظ وفتح ملفات Excel |

### User App (`User/pubspec.yaml`):

| الحزمة | الغرض |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Firebase |
| `google_nav_bar` | شريط التنقل السفلي |
| `connectivity_plus` | كشف انقطاع الإنترنت |
| `cached_network_image` | تحميل الصور مع cache |
| `flutter_markdown` | عرض الصفحات المعلوماتية |
| `http` | طلبات HTTP |
| `provider` + `shared_preferences` | إدارة الثيم وحفظه |
| `remixicon` | الأيقونات |
| `intl` | تنسيق التواريخ |

---

## 10. القرارات المعمارية وسببها

| القرار | السبب |
|---|---|
| تطبيقَان منفصلان بدل تطبيق واحد | الأدمن وتطبيق الزبون لهما جماهير مختلفة تماماً. فصلهما يحسن الأمان ويبسط الكود. |
| `app_config.dart` مركزي | لجعل التخصيص لمطعم جديد يتطلب تعديل ملف واحد فقط بدل البحث في 20+ ملف. |
| `admins` collection بدل `role` في `users` | المستخدم يملك صلاحية تعديل ملفه الشخصي → ثغرة أمنية لو كان `role` فيه. |
| XOR obfuscation لمفاتيح ImageKit | منع استخراج المفاتيح بأمر `strings` على ملف APK. |
| `ImageKitService` موحّد | كان كود الرفع/الحذف مكرراً في 3 شاشات. الآن في مكان واحد. |
| `collectionGroup` للطلبات | الطلبات موجودة كـ subcollection تحت كل مستخدم. بدون `collectionGroup` لا يمكن للأدمن رؤية كل الطلبات دفعة واحدة. |
| `imageFileId` محفوظ مع كل صورة | بدونه، حذف الوجبة أو البنر لن يحذف الصورة من ImageKit → تراكم ملفات غير مستخدمة. |

---

## 11. ما لم يُنجز بعد (للفريق القادم)

- [ ] **Push Notifications:** إشعار الزبون عند تغيير حالة الطلب (Firebase Cloud Messaging)
- [ ] **تحقق من رقم الهاتف:** الأرقام تُدخل يدوياً حالياً بدون SMS verification
- [ ] **دعم متعدد الصور للوجبة:** حالياً صورة واحدة فقط لكل وجبة
- [ ] **نظام الكوبونات والخصومات:** البنية التحتية غير موجودة بعد
- [ ] **تقييمات الوجبات:** لا يوجد نظام تقييم حالياً
- [ ] **Unit/Integration Tests:** لا يوجد اختبار أوتوماتيكي حالياً

---

## 12. ملفات مرجعية مهمة

| الملف | أين يقرأ؟ | لماذا مهم؟ |
|---|---|---|
| `firestore.rules` | جذر المشروع | أمان البيانات — يُرفع لـ Firebase Console |
| `Admin/lib/core/app_config.dart` | Admin/lib/core | **ابدأ هنا** عند التخصيص |
| `User/lib/core/app_config.dart` | User/lib/core | نسخة User بدون مفاتيح ImageKit |
| `Admin/lib/services/imagekit_service.dart` | Admin/lib/services | كل كود رفع/حذف الصور |
| `Admin/lib/main.dart` | Admin/lib | إعداد Firebase + الثيم الكامل |
| `User/lib/main.dart` | User/lib | إعداد Firebase + الثيم الكامل |
| `customization_guide.md` | جذر المشروع | دليل مفصّل للتخصيص خطوة بخطوة |

---

## 13. بيئة التطوير

```bash
# تثبيت dependencies للـ Admin
cd Admin && flutter pub get

# تثبيت dependencies للـ User
cd User && flutter pub get

# تشغيل في وضع التطوير
flutter run

# بناء APK للإنتاج (مع تشفير الكود)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

**متطلبات:**
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio أو VS Code مع Flutter extension
- حساب Firebase مع مشروع مُنشأ مسبقاً

---

*آخر تحديث لهذه الوثيقة: مايو 2026 — بواسطة Abdulrahman Qaten*
