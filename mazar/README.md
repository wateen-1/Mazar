# مزار (Mazar)

**على خُطى الحبيب صلى الله عليه وسلم**

تطبيق سياحة دينية ذكي يعتمد على الذكاء الاصطناعي والخرائط. هذا المستودع يحتوي على الهيكل الأساسي الكامل للمشروع: تطبيق Flutter (`flutter_app/`) وخادم Backend بلغة Python/FastAPI (`backend/`).

## البنية العامة

```
khota/
├── flutter_app/     تطبيق الجوال (Flutter + Riverpod + Clean Architecture)
└── backend/         خادم FastAPI جاهز للتشغيل على Replit
```

## flutter_app/ — تطبيق الجوال

يعتمد على نمط Clean Architecture مقسّماً إلى خمس مجلدات رئيسية داخل `lib/`:

- **core/** — كل ما هو مشترك بين التطبيق بأكمله: الألوان والنصوص والثوابت (`constants/`)، الثيم (`theme/`)، عميل الشبكة (`network/`)، معالجة الأخطاء (`errors/`)، أدوات مساعدة (`utils/`)، ودجات مشتركة (`widgets/`)، ونظام التنقل (`routes/`).
- **data/** — النماذج والمصادر البعيدة والمستودعات المشتركة على مستوى التطبيق (غير الخاصة بميزة واحدة).
- **domain/** — الكيانات (Entities) والعقود (Repositories/UseCases) المجردة، مستقلة عن أي تفاصيل تقنية.
- **presentation/** — الشاشات المشتركة (البداية والرئيسية)، الودجات، وموفرات Riverpod العامة.
- **features/** — كل ميزة رئيسية (`planner`، `mazarat`، `crowd`) لها نسختها الخاصة من data/domain/presentation، بحيث تبقى كل ميزة مستقلة وقابلة للتطوير بمعزل عن الأخريات.

### الميزات الثلاث

| الميزة | المسار | الوصف |
|---|---|---|
| المخطط الذكي | `features/planner/` | توليد جدول زيارة ذكي عبر نقطة `/planner` |
| المزارات التفاعلية | `features/mazarat/` | خريطة تفاعلية تعرض المزارات القريبة عبر GPS وGoogle Maps |
| توقع الازدحام | `features/crowd/` | استعلام عن مستوى الازدحام المتوقع في مكان ووقت معينين |

### شاشة البداية (Splash Screen)

`lib/presentation/screens/splash/splash_screen.dart` — خلفية متدرجة بالأخضر الإسلامي العميق، شعار ذهبي (هلال ونجمة ثمانية) مرسوم برمجياً عبر `CustomPainter` (بلا حاجة لصور خارجية)، نمط هندسي إسلامي دوّار خفيف في الخلفية، حركات دخول متتابعة، ثم انتقال تلقائي للشاشة الرئيسية.

### التشغيل

```bash
cd flutter_app
flutter pub get
flutter run
```

ملاحظة حول android/: مجلد `android/` أصبح كاملاً وقابلاً للبناء مباشرة (Android v2 Embedding)، ويحتوي على:
- `app/build.gradle` و`build.gradle` (مستوى المشروع) و`settings.gradle` و`gradle.properties` و`gradle/wrapper/gradle-wrapper.properties` — Gradle 8.3، Android Gradle Plugin 8.1.0، Kotlin 1.9.10.
- `app/src/main/kotlin/com/mazar/app/MainActivity.kt` يمتد من `io.flutter.embedding.android.FlutterActivity` (v2)، مع `flutterEmbedding=2` في `AndroidManifest.xml` — هذا ما يحل خطأ "Build failed due to use of deleted Android v1 embedding".
- `app/src/main/res/` يحتوي على ثيمات شاشة الإطلاق (`LaunchTheme`/`NormalTheme`) وخلفيتها بلون `AppColors.navyDark` لانتقال بصري سلس نحو splash_screen.dart.
- `applicationId`/`namespace` مضبوطان على `com.mazar.app`، و`minSdkVersion 21` (مطلوب من google_maps_flutter وgeolocator).

لا حاجة لتشغيل `flutter create .` بعد الآن إلا لتوليد الأيقونات الفعلية (`mipmap-*`) وملف `local.properties` (يُنشئه Flutter تلقائياً عند أول `flutter pub get` أو فتح المشروع من IDE مرتبط بتثبيت Flutter SDK).

ملاحظة حول ios/: تم تجهيز `ios/Runner/Info.plist` مسبقاً باسم التطبيق الصحيح "مزار" (`CFBundleDisplayName`/`CFBundleName`)، لكن باقي هيكل مجلد `ios/` (مشروع Xcode الفعلي، الأيقونات...) لم يُنشأ بعد. عند تشغيل `flutter create .` لاستكماله، تأكد من الإبقاء على القيم الموجودة في هذا الملف بدل السماح للأداة بالكتابة فوقها بالاسم الافتراضي.

قبل التشغيل الفعلي: أضف مفتاح Google Maps في إعدادات Android/iOS، وحدّث `API_BASE_URL` في `.env` (انسخه من `.env.example`) ليشير إلى رابط الخادم الفعلي على Replit بعد نشره.

## backend/ — خادم FastAPI

جاهز للتشغيل المباشر على Replit (`.replit` و `replit.nix` معدّان مسبقاً).

```
backend/
├── main.py              نقطة الدخول، تهيئة FastAPI وCORS وربط المسارات
├── requirements.txt
├── .replit / replit.nix إعدادات Replit
├── .env.example          انسخه إلى .env وعبّئ القيم
└── app/
    ├── core/config.py    الإعدادات المركزية (تُقرأ من متغيرات البيئة)
    ├── models/schemas.py نماذج Pydantic المشتركة بين كل المسارات
    └── routers/
        ├── planner.py    POST /planner   (مبدئي فارغ)
        ├── mazarat.py    GET /mazarat, POST /mazarat/{id}/activate  (مبدئي فارغ)
        └── crowd.py      GET /crowd      (مبدئي فارغ)
```

### التشغيل محلياً

```bash
cd backend
pip install -r requirements.txt
python3 main.py
```

الخادم يعمل افتراضياً على المنفذ 8000، وتوثيق تفاعلي متاح تلقائياً على `/docs` (Swagger UI).

### النشر على Replit

1. أنشئ Repl جديد من نوع Python واستورد محتويات مجلد `backend/`.
2. انسخ `.env.example` إلى `.env` وعبّئ القيم (مفاتيح Google Maps والذكاء الاصطناعي).
3. اضغط Run — سيُشغَّل `main.py` تلقائياً حسب إعدادات `.replit`.
4. انسخ رابط الـ Repl الناتج وضعه في `ApiConstants.baseUrl` (أو `.env`) داخل تطبيق Flutter.

## الخطوات التالية المقترحة

جميع نقاط النهاية الثلاث حالياً مسارات مبدئية فارغة (تعيد استجابات فارغة/افتراضية) حسب الطلب، لتُبنى عليها لاحقاً منطق الذكاء الاصطناعي الفعلي دون الحاجة لإعادة هيكلة المشروع:

1. ربط `/planner` بنموذج ذكاء اصطناعي لتوليد الجدول الفعلي.
2. ربط `/mazarat` بقاعدة بيانات مزارات حقيقية وحساب مسافات دقيق.
3. ربط `/crowd` بنموذج تنبؤ مدرّب على بيانات ازدحام تاريخية.
4. إضافة قاعدة بيانات فعلية (مثال: PostgreSQL عبر `DATABASE_URL`).
5. تشغيل `flutter create .` لاستكمال بقية مجلدات المنصات (Android/iOS) — ملفا `AndroidManifest.xml` و`Info.plist` معدّان مسبقاً باسم "مزار" — وإضافة أصول الصور الفعلية في `assets/`.
