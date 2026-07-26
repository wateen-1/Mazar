import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/mazarat_remote_datasource.dart';
import '../../data/repositories/mazarat_repository_impl.dart';
import '../../domain/entities/mazar_entity.dart';
import '../../domain/repositories/mazarat_repository.dart';
import '../../domain/usecases/activate_mazar_usecase.dart';
import '../../domain/usecases/get_nearby_mazarat_usecase.dart';

final mazaratRemoteDataSourceProvider = Provider<MazaratRemoteDataSource>((ref) {
  return MazaratRemoteDataSourceImpl(ApiClient());
});

final mazaratRepositoryProvider = Provider<MazaratRepository>((ref) {
  return MazaratRepositoryImpl(ref.watch(mazaratRemoteDataSourceProvider));
});

final getNearbyMazaratUseCaseProvider = Provider<GetNearbyMazaratUseCase>((ref) {
  return GetNearbyMazaratUseCase(ref.watch(mazaratRepositoryProvider));
});

/// حالة استخدام تفعيل التجربة التفاعلية لمزار معيّن، تُستهلك مباشرة من
/// شاشة تفاصيل المزار (MazarDetailScreen) عبر ref.read عند الضغط على زر
/// "تفعيل التجربة التفاعلية في الموقع".
final activateMazarUseCaseProvider = Provider<ActivateMazarUseCase>((ref) {
  return ActivateMazarUseCase(ref.watch(mazaratRepositoryProvider));
});

/// حالة شاشة خريطة المزارات: تحميل، قائمة مزارات، أو رسالة خطأ.
class MazaratState {
  final bool isLoading;
  final List<MazarEntity> mazarat;
  final String? errorMessage;

  const MazaratState({
    this.isLoading = false,
    this.mazarat = const [],
    this.errorMessage,
  });

  MazaratState copyWith({
    bool? isLoading,
    List<MazarEntity>? mazarat,
    String? errorMessage,
  }) {
    return MazaratState(
      isLoading: isLoading ?? this.isLoading,
      mazarat: mazarat ?? this.mazarat,
      errorMessage: errorMessage,
    );
  }
}

class MazaratNotifier extends StateNotifier<MazaratState> {
  final GetNearbyMazaratUseCase useCase;

  MazaratNotifier(this.useCase) : super(const MazaratState());

  Future<void> loadNearbyMazarat(double latitude, double longitude) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await useCase(
      NearbyMazaratParams(latitude: latitude, longitude: longitude),
    );
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (mazarat) => state = state.copyWith(isLoading: false, mazarat: mazarat),
    );
  }
}

final mazaratNotifierProvider =
    StateNotifierProvider<MazaratNotifier, MazaratState>((ref) {
  return MazaratNotifier(ref.watch(getNearbyMazaratUseCaseProvider));
});
