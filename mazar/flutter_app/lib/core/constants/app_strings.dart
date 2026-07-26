/// جميع النصوص الثابتة المستخدمة في تطبيق مزار، مجمّعة في مكان واحد
/// لتسهيل الترجمة والتعديل لاحقاً دون البحث داخل ملفات الواجهة.
class AppStrings {
  AppStrings._();

  static const String appName = 'مزار';
  static const String appSlogan = 'على خُطى الحبيب صلى الله عليه وسلم';
  static const String appNameEn = 'Mazar';

  // شاشة البداية
  static const String loading = 'جارِ التحضير لرحلتك الإيمانية...';

  // التنقل
  static const String home = 'الرئيسية';
  static const String planner = 'المخطط الذكي';
  static const String mazarat = 'المزارات';
  static const String crowd = 'الازدحام';
  static const String profile = 'حسابي';

  // المخطط الذكي
  static const String plannerTitle = 'مخطط الرحلة الذكي';
  static const String plannerSubtitle = 'دع الذكاء الاصطناعي يرسم لك جدول زيارتك';

  // المزارات
  static const String mazaratTitle = 'المزارات التفاعلية';
  static const String mazaratSubtitle = 'اكتشف المعالم القريبة منك عبر GPS';

  // الازدحام
  static const String crowdTitle = 'توقع الازدحام';
  static const String crowdSubtitle = 'خطط لزيارتك في الوقت الأنسب';
}
