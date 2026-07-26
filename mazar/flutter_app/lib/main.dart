import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

/// نقطة الدخول الرئيسية لتطبيق مزار (Mazar)
/// يقوم هذا الملف بتهيئة التخزين المحلي (Hive) وتحميل متغيرات البيئة من
/// ملف .env (رابط الخادم السحابي على Replit ومفتاح خرائط Google) قبل
/// تشغيل التطبيق ضمن ProviderScope الخاص بمكتبة Riverpod لإدارة الحالة.
Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized() هي الاستدعاء الصحيح لربط شجرة
  // الودجات بمحرك Flutter قبل استخدام أي قناة منصّة أصلية (كما تتطلبه Hive
  // والوصول إلى نظام الملفات لقراءة .env هنا)؛ الاستدعاء القديم
  // WidgetsBinding.ensureInitialized() غير موجود أصلاً كدالة ساكنة على
  // WidgetsBinding وكان يسبب خطأ تجميع.
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل ملف .env قبل أي استخدام لـ ApiConstants.baseUrl أو مفتاح خرائط
  // Google، حتى يعتمد التطبيق فعلياً على رابط الخادم السحابي الموضوع في
  // .env بدل الرابط الافتراضي الثابت في الكود. في حال غياب الملف (مثلاً
  // أول تشغيل قبل نسخه من .env.example) يُكمل التطبيق عمله بأمان بالقيم
  // الافتراضية الموجودة في ApiConstants.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // لا يوجد ملف .env بعد؛ نتابع بالقيم الافتراضية بدل تعطل التطبيق بالكامل.
  }

  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: MazarApp(),
    ),
  );
}
