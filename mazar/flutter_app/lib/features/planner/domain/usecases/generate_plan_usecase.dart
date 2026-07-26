import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../domain/usecases/base_usecase.dart';
import '../entities/planner_entity.dart';
import '../repositories/planner_repository.dart';

/// حالة الاستخدام المسؤولة عن طلب توليد جدول زيارة ذكي من الخادم.
class GeneratePlanUseCase
    implements UseCase<List<PlannerItemEntity>, PlannerRequestEntity> {
  final PlannerRepository repository;

  GeneratePlanUseCase(this.repository);

  @override
  Future<Either<Failure, List<PlannerItemEntity>>> call(
    PlannerRequestEntity params,
  ) {
    return repository.generatePlan(params);
  }
}
