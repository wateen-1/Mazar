/// استثناءات مخصصة لطبقة الشبكة، تُستخدم لتوضيح سبب فشل الاتصال بالخادم.
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException({required this.message, this.statusCode});

  @override
  String toString() => 'NetworkException($statusCode): $message';
}

class NoInternetException implements Exception {
  final String message;
  NoInternetException([this.message = 'لا يوجد اتصال بالإنترنت']);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'حدث خطأ في الخادم، حاول لاحقاً']);

  @override
  String toString() => message;
}

/// استثناء مخصص يُطلق عندما يرفض الخادم طلب تفعيل تجربة مزار تفاعلية
/// برمز الحالة 403 Forbidden، لأن المستخدم يقع خارج النطاق الجغرافي
/// المسموح به (أبعد من 100 متر عن المعلم). يحمل هذا الاستثناء رسالة
/// الخادم التوضيحية (detail) ليُعاد استخدامها لاحقاً في واجهة المستخدم.
class OutOfRangeException implements Exception {
  final String message;
  OutOfRangeException(this.message);

  @override
  String toString() => message;
}
