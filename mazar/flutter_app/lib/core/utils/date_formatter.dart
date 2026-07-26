import 'package:intl/intl.dart';

/// دوال مساعدة لتنسيق التواريخ والأوقات باللغة العربية عبر التطبيق.
class DateFormatter {
  DateFormatter._();

  static String formatArabicDate(DateTime date) {
    return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
  }

  /// ينسّق الوقت بصيغة 12 ساعة عربية (مثال: "3:05 م")، دون الاعتماد على
  /// بيانات اللغة الخاصة بحزمة intl لهذا التنسيق تحديداً (والتي تتطلب
  /// استدعاء initializeDateFormatting قبل استخدامها لأي لغة غير 'en')،
  /// حتى تعمل هذه الدالة بأمان من أول استدعاء لها دون أي تهيئة إضافية.
  static String formatTime(DateTime date) {
    final hour24 = date.hour;
    final isPm = hour24 >= 12;
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = isPm ? 'م' : 'ص';
    return '$hour12:$minute $period';
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
