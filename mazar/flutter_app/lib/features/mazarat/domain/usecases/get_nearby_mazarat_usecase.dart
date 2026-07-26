import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../domain/usecases/base_usecase.dart';
import '../entities/mazar_entity.dart';
import '../repositories/mazarat_repository.dart';

class NearbyMazaratParams {
  final double latitude;
  final double longitude;
  final double radiusInKm;

  const NearbyMazaratParams({
    required this.latitude,
    required this.longitude,
    this.radiusInKm = 5,
  });
}

/// حالة الاستخدام المسؤولة عن جلب المزارات القريبة من موقع المستخدم الحالي.
class GetNearbyMazaratUseCase
    implements UseCase<List<MazarEntity>, NearbyMazaratParams> {
  final MazaratRepository repository;

  GetNearbyMazaratUseCase(this.repository);

  @override
  Future<Either<Failure, List<MazarEntity>>> call(NearbyMazaratParams params) {
    return repository.getNearbyMazarat(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusInKm: params.radiusInKm,
    );
  }
}
