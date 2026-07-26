import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/planner_remote_datasource.dart';
import '../../data/repositories/planner_repository_impl.dart';
import '../../domain/entities/planner_entity.dart';
import '../../domain/repositories/planner_repository.dart';
import '../../domain/usecases/generate_plan_usecase.dart';

final plannerRemoteDataSourceProvider = Provider<PlannerRemoteDataSource>((ref) {
  return PlannerRemoteDataSourceImpl(ApiClient());
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepositoryImpl(ref.watch(plannerRemoteDataSourceProvider));
});

final generatePlanUseCaseProvider = Provider<GeneratePlanUseCase>((ref) {
  return GeneratePlanUseCase(ref.watch(plannerRepositoryProvider));
});

/// حالة شاشة المخطط الذكي: تحميل، قائمة عناصر، أو رسالة خطأ.
class PlannerState {
  final bool isLoading;
  final List<PlannerItemEntity> items;
  final String? errorMessage;

  const PlannerState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
  });

  PlannerState copyWith({
    bool? isLoading,
    List<PlannerItemEntity>? items,
    String? errorMessage,
  }) {
    return PlannerState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  final GeneratePlanUseCase useCase;

  PlannerNotifier(this.useCase) : super(const PlannerState());

  Future<void> generatePlan(PlannerRequestEntity request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await useCase(request);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (items) => state = state.copyWith(isLoading: false, items: items),
    );
  }

  /// يعيد حالة المخطط الذكي إلى نقطة البداية (نموذج الإدخال فارغاً بلا
  /// نتائج أو أخطاء سابقة)، وتُستخدم عند اختيار "خطة جديدة" من شاشة
  /// الجدول الزمني، أو "تعديل خيارات الرحلة" من شاشة الخطأ أو النتيجة
  /// الفارغة.
  void reset() {
    state = const PlannerState();
  }
}

final plannerNotifierProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  return PlannerNotifier(ref.watch(generatePlanUseCaseProvider));
});
