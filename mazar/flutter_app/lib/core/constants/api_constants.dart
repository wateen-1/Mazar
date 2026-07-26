import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ثوابت الاتصال بالخادم الخلفي (Backend) الخاص بتطبيق مزار.
class ApiConstants {
  ApiConstants._();

  /// عنوان الخادم الأساسي (يعمل على Replit).
  ///
  /// يُقرأ أولاً من متغير البيئة API_BASE_URL في ملف .env (الذي يُحمَّل في
  /// main.dart قبل تشغيل التطبيق)، حتى يعتمد التطبيق فعلياً على رابط
  /// النشر السحابي الحقيقي على Replit دون الحاجة لتعديل الكود المصدري.
  /// في حال غياب الملف أو المتغير (مثال: أول تشغيل قبل نسخ .env.example
  /// إلى .env)، يُستخدم الرابط الوهمي التالي كقيمة احتياطية آمنة فقط
  /// لمنع تعطّل التطبيق، ويجب استبداله برابط مشروعك الفعلي على Replit.
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://mazar-backend.username.repl.co';

  /// مفتاح Google Maps API، يُقرأ من متغير البيئة GOOGLE_MAPS_API_KEY في
  /// ملف .env. يُستخدم حالياً كمرجع مركزي داخل كود Dart لأي استدعاء مستقبلي
  /// لواجهات Google البرمجية المباشرة (مثل Geocoding عبر HTTP)؛ أما تفعيل
  /// عرض خرائط Google نفسها فيعتمد على المفاتيح المُدخلة في
  /// android/app/src/main/AndroidManifest.xml (com.google.android.geo.API_KEY)
  /// وios/Runner/Info.plist (GMSApiKey) بشكل منفصل، حسب متطلبات حزمة
  /// google_maps_flutter لكل منصة.
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static const String plannerEndpoint = '/planner';
  static const String mazaratEndpoint = '/mazarat';
  static const String crowdEndpoint = '/crowd';
  static const String healthEndpoint = '/health';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
