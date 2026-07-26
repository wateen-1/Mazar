import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../domain/usecases/base_usecase.dart';
import '../entities/crowd_entity.dart';
import '../repositories/crowd_repository.dart';

class PredictCrowdParams {
  final String locationId;
  final DateTime? targetTime;

  const PredictCrowdParams({required this.locationId, this.targetTime});
}

/// حالة الاستخدام المسؤولة عن طلب توقع الازدحام لمكان معيّن.
class PredictCrowdUseCase implements UseCase<CrowdPredictionEntity, PredictCrowdParams> {
  final CrowdRepository repository;

  PredictCrowdUseCase(this.repository);

  @override
  Future<Either<Failure, CrowdPredictionEntity>> call(PredictCrowdParams params) {
    return repository.predictCrowd(
      locationId: params.locationId,
      targetTime: params.targetTime,
    );
  }
}
