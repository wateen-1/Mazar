import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/planner_model.dart';

/// عقد مصدر البيانات البعيد الخاص بميزة المخطط الذكي.
abstract class PlannerRemoteDataSource {
  Future<List<PlannerItemModel>> generatePlan({
    required String visitDate,
    required int numberOfDays,
    required List<String> preferredCategories,
    double? currentLatitude,
    double? currentLongitude,
  });
}

/// التنفيذ الفعلي لمصدر البيانات، يستدعي نقطة النهاية POST /planner على
/// خادم مزار، ويمرر مدة الزيارة (بعدد الأيام) والاهتمامات الثقافية
/// المختارة وإحداثيات موقع المستخدم الاختيارية ضمن جسم الطلب (Body)
/// بصيغة JSON تطابق تماماً نموذج PlannerRequest المعرَّف في الخادم
/// (backend/app/models/schemas.py).
class PlannerRemoteDataSourceImpl implements PlannerRemoteDataSource {
  final ApiClient apiClient;

  PlannerRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<PlannerItemModel>> generatePlan({
    required String visitDate,
    required int numberOfDays,
    required List<String> preferredCategories,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.plannerEndpoint,
        data: {
          'visit_date': visitDate,
          'number_of_days': numberOfDays,
          'preferred_categories': preferredCategories,
          'current_latitude': currentLatitude,
          'current_longitude': currentLongitude,
        },
      );

      final List<dynamic> items = response.data['items'] as List<dynamic>? ?? [];
      return items
          .map((item) => PlannerItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      // خطأ اتصال فعلي (لا توجد استجابة من الخادم إطلاقاً): غالباً بسبب
      // انقطاع الإنترنت، أو تعذّر الوصول إلى عنوان الخادم في ApiConstants،
      // أو انتهاء مهلة الاتصال/الاستقبال.
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw NoInternetException(
          'تعذر الاتصال بخادم مزار، يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً',
        );
      }

      // خطأ تحقق من صحة المدخلات (422 Unprocessable Entity) يرسله FastAPI
      // تلقائياً عند مخالفة القيود المعرَّفة على number_of_days (بين 1 و30)
      // أو أي حقل آخر من حقول PlannerRequest.
      if (statusCode == 422) {
        throw ServerException(
          'تعذر توليد الخطة بهذه الخيارات، يرجى مراجعة مدة الزيارة والمحاولة مجدداً',
        );
      }

      final responseData = error.response?.data;
      final serverDetail = (responseData is Map<String, dynamic>)
          ? responseData['detail']?.toString()
          : null;

      throw ServerException(
        serverDetail ??
            error.message ??
            'تعذر توليد الخطة الذكية حالياً، يرجى المحاولة لاحقاً',
      );
    }
  }
}
