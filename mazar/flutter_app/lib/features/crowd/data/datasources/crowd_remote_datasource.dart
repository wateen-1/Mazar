import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/crowd_model.dart';

/// عقد مصدر البيانات البعيد الخاص بميزة توقع الازدحام.
abstract class CrowdRemoteDataSource {
  Future<CrowdPredictionModel> predictCrowd({
    required String locationId,
    DateTime? targetTime,
  });
}

/// التنفيذ الفعلي لمصدر البيانات، يستدعي نقطة النهاية GET /crowd.
class CrowdRemoteDataSourceImpl implements CrowdRemoteDataSource {
  final ApiClient apiClient;

  CrowdRemoteDataSourceImpl(this.apiClient);

  @override
  Future<CrowdPredictionModel> predictCrowd({
    required String locationId,
    DateTime? targetTime,
  }) async {
    final response = await apiClient.get(
      ApiConstants.crowdEndpoint,
      queryParameters: {
        'location_id': locationId,
        if (targetTime != null) 'target_time': targetTime.toIso8601String(),
      },
    );

    return CrowdPredictionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
