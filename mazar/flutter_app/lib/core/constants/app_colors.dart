import 'package:flutter/material.dart';

/// لوحة ألوان تطبيق مزار - الهوية البصرية الرسمية
/// ==========================================
/// هوية فخمة راقية مستوحاة من روح تطبيق "نسك" الرسمي، مبنية على ثلاث
/// عائلات ألوان:
///   • أساسي (Primary)   : ذهبي إسلامي عميق وراقٍ.
///   • خلفية (Background): درجات هادئة ومريحة من الأبيض العاجي والبيج الفاتح.
///   • إضافي (Accent)    : كحلي فخم للأزرار والنصوص الهامة، وزيتي هادئ للمسات
///                         الثانوية والتفاصيل الدافئة.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // اللون الأساسي: ذهبي إسلامي عميق وراقٍ
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFFB8912F);
  static const Color primaryDark = Color(0xFF8F6F20);
  static const Color primaryLight = Color(0xFFD9B968);

  // ---------------------------------------------------------------------
  // ألوان الخلفية: درجات هادئة من الأبيض العاجي والبيج الفاتح جداً
  // ---------------------------------------------------------------------
  static const Color background = Color(0xFFFBF8F1);
  static const Color backgroundSecondary = Color(0xFFF3ECDC);
  static const Color surface = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // اللون الإضافي الأول: كحلي فخم، يُستخدم للأزرار والعناوين والنصوص الهامة
  // ---------------------------------------------------------------------
  static const Color navy = Color(0xFF122135);
  static const Color navyDark = Color(0xFF0B1522);
  static const Color navyLight = Color(0xFF24405F);

  // ---------------------------------------------------------------------
  // اللون الإضافي الثاني: زيتي هادئ، يُستخدم للمسات الثانوية والتفاصيل الدافئة
  // ---------------------------------------------------------------------
  static const Color olive = Color(0xFF6B6B3A);
  static const Color oliveDark = Color(0xFF4E4E29);
  static const Color oliveLight = Color(0xFF93925F);

  // ---------------------------------------------------------------------
  // نصوص
  // ---------------------------------------------------------------------
  static const Color textPrimary = navy;
  static const Color textSecondary = Color(0xFF6E6A5D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFF3ECDC);

  // ---------------------------------------------------------------------
  // أساسيات محايدة
  // ---------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF14140F);
  static const Color divider = Color(0xFFE4DCC8);

  // ---------------------------------------------------------------------
  // ألوان الحالة (تبقى ثابتة بغض النظر عن الهوية البصرية)
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB8860B);
  static const Color error = Color(0xFFB3261E);
  static const Color crowdLow = Color(0xFF2E7D32);
  static const Color crowdMedium = Color(0xFFC08A1E);
  static const Color crowdHigh = Color(0xFFB3261E);

  // ---------------------------------------------------------------------
  // تدرجات الهوية (Gradients)
  // ---------------------------------------------------------------------
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyDark, navy, navyLight],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryDark, primary, primaryLight],
  );

  // =======================================================================
  // أسماء قديمة محفوظة للتوافق فقط (Legacy Aliases)
  // =======================================================================
  // بعض الشاشات (مثل features/planner و features/crowd وخريطة المزارات)
  // ما زالت تستخدم الأسماء القديمة أدناه. تم إبقاؤها هنا معرَّفة بقيم
  // منسجمة مع الهوية الجديدة حتى تستمر تلك الشاشات بالعمل والتصميم بشكل
  // متّسق دون تعديلها الآن، ريثما يتم ترحيلها لاحقاً لاستخدام الأسماء
  // الجديدة أعلاه مباشرة.
  static const Color primaryGreen = navy;
  static const Color primaryGreenDark = navyDark;
  static const Color primaryGreenLight = navyLight;
  static const Color gold = primary;
  static const Color goldLight = primaryLight;
  static const Color goldDark = primaryDark;
  static const Color offWhite = background;
  static const Color cream = backgroundSecondary;
  static const LinearGradient goldGradient = primaryGradient;
}
