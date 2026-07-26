import 'package:equatable/equatable.dart';

/// النوع الأساسي لجميع حالات الفشل التي قد تحدث في طبقة النطاق (Domain).
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'تحقق من اتصال الإنترنت']);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'تعذر تحديد موقعك الجغرافي']);
}

/// فشل مخصص يحدث عندما يحاول المستخدم تفعيل التجربة التفاعلية لمزار وهو
/// خارج النطاق الجغرافي المسموح به (أبعد من 100 متر عن المعلم)، بحسب رفض
/// الخادم للطلب برمز الحالة 403. تُميَّز هذه الحالة عن أخطاء الخادم العامة
/// لأن واجهة المستخدم تحتاج إلى عرضها بأسلوب مختلف تماماً (رسالة لبقة
/// توضّح للمستخدم سبب الرفض بدلاً من رسالة خطأ عامة).
class LocationOutOfRangeFailure extends Failure {
  const LocationOutOfRangeFailure([
    super.message = 'أنت خارج النطاق الجغرافي المسموح به لتفعيل هذه التجربة',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'حدث خطأ أثناء قراءة البيانات المحلية']);
}
