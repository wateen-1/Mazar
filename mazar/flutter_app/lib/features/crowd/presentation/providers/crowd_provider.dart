import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/crowd_remote_datasource.dart';
import '../../data/repositories/crowd_repository_impl.dart';
import '../../domain/entities/crowd_entity.dart';
import '../../domain/repositories/crowd_repository.dart';
import '../../domain/usecases/predict_crowd_usecase.dart';

final crowdRemoteDataSourceProvider = Provider<CrowdRemoteDataSource>((ref) {
  return CrowdRemoteDataSourceImpl(ApiClient());
});

final crowdRepositoryProvider = Provider<CrowdRepository>((ref) {
  return CrowdRepositoryImpl(ref.watch(crowdRemoteDataSourceProvider));
});

final predictCrowdUseCaseProvider = Provider<PredictCrowdUseCase>((ref) {
  return PredictCrowdUseCase(ref.watch(crowdRepositoryProvider));
});

/// حالة شاشة توقع الازدحام: تحميل، نتيجة توقع، أو رسالة خطأ.
class CrowdState {
  final bool isLoading;
  final CrowdPredictionEntity? prediction;
  final String? errorMessage;

  const CrowdState({this.isLoading = false, this.prediction, this.errorMessage});

  CrowdState copyWith({
    bool? isLoading,
    CrowdPredictionEntity? prediction,
    String? errorMessage,
  }) {
    return CrowdState(
      isLoading: isLoading ?? this.isLoading,
      prediction: prediction ?? this.prediction,
      errorMessage: errorMessage,
    );
  }
}

class CrowdNotifier extends StateNotifier<CrowdState> {
  final PredictCrowdUseCase useCase;

  CrowdNotifier(this.useCase) : super(const CrowdState());

  Future<void> predict(String locationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await useCase(PredictCrowdParams(locationId: locationId));
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (prediction) => state = state.copyWith(isLoading: false, prediction: prediction),
    );
  }
}

final crowdNotifierProvider = StateNotifierProvider<CrowdNotifier, CrowdState>((ref) {
  return CrowdNotifier(ref.watch(predictCrowdUseCaseProvider));
});

/// موفر عائلي (Family Provider) يجلب توقّع الازدحام لموقع واحد محدد عبر
/// معرّفه (locationId)، ويُستخدم لعرض حالة الازدحام كهالة لونية حول كل
/// علامة (Marker) على خريطة المزارات التفاعلية، وكذلك داخل الكارت
/// السفلي المنبثق عند اختيار معلم معيّن.
///
/// بما أنه FutureProvider.family، يستفيد تلقائياً من التخزين المؤقت
/// (Caching) الخاص بـ Riverpod: يُجلب توقع كل معلم مرة واحدة فقط ويُعاد
/// استخدامه في كل مكان يستمع لنفس المعرّف (على الخريطة وفي الكارت معاً)
/// دون تكرار الطلب للخادم.
final crowdPredictionByLocationProvider =
    FutureProvider.family<CrowdPredictionEntity, String>((ref, locationId) async {
  final useCase = ref.watch(predictCrowdUseCaseProvider);
  final result = await useCase(PredictCrowdParams(locationId: locationId));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (prediction) => prediction,
  );
});
