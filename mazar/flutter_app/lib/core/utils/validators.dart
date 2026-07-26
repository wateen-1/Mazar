/// دوال تحقق مشتركة تُستخدم عبر الطبقات المختلفة من التطبيق.
class Validators {
  Validators._();

  static bool isValidLatitude(double lat) => lat >= -90 && lat <= 90;

  static bool isValidLongitude(double lng) => lng >= -180 && lng <= 180;

  static bool isValidCoordinates(double lat, double lng) =>
      isValidLatitude(lat) && isValidLongitude(lng);

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }
}
