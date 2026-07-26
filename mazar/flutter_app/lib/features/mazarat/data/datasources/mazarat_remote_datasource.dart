import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/mazar_model.dart';

/// عقد مصدر البيانات البعيد الخاص بميزة المزارات التفاعلية.
abstract class MazaratRemoteDataSource {
  Future<List<MazarModel>> getNearbyMazarat({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  });

  Future<MazarModel> activateMazar({
    required String mazarId,
    required double latitude,
    required double longitude,
  });
}

/// التنفيذ الفعلي لمصدر البيانات، يستدعي نقطتي النهاية GET/POST الخاصتين بـ /mazarat.
class MazaratRemoteDataSourceImpl implements MazaratRemoteDataSource {
  final ApiClient apiClient;

  MazaratRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<MazarModel>> getNearbyMazarat({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    final response = await apiClient.get(
      ApiConstants.mazaratEndpoint,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusInKm,
      },
    );

    final List<dynamic> items = response.data['mazarat'] as List<dynamic>? ?? [];
    return items
        .map((item) => MazarModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MazarModel> activateMazar({
    required String mazarId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.mazaratEndpoint}/$mazarId/activate',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return MazarModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      final serverDetail = (responseData is Map<String, dynamic>)
          ? responseData['detail'] as String?
          : null;

      // الخادم يرد بـ 403 Forbidden تحديداً عندما يكون المستخدم خارج نطاق
      // الـ 100 متر المسموح به حول المعلم؛ نميّز هذه الحالة بوضوح عبر
      // استثناء مخصص حتى تستطيع واجهة المستخدم عرضها بأسلوب لبق ومختلف
      // عن أخطاء الشبكة أو الخادم العامة.
      if (statusCode == 403) {
        throw OutOfRangeException(
          serverDetail ??
              'يجب أن تكون ضمن نطاق 100 متر من المعلم لتفعيل هذه التجربة',
        );
      }

      if (statusCode == 404) {
        throw ServerException('لم يتم العثور على هذا المزار في قاعدة البيانات');
      }

      throw ServerException(
        serverDetail ?? error.message ?? 'تعذر الاتصال بالخادم، يرجى المحاولة لاحقاً',
      );
    }
  }
}
