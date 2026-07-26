import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/crowd_entity.dart';
import '../../domain/repositories/crowd_repository.dart';
import '../datasources/crowd_remote_datasource.dart';

/// التنفيذ الفعلي لمستودع بيانات توقع الازدحام، يربط طبقة النطاق بمصدر البيانات.
class CrowdRepositoryImpl implements CrowdRepository {
  final CrowdRemoteDataSource remoteDataSource;

  CrowdRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, CrowdPredictionEntity>> predictCrowd({
    required String locationId,
    DateTime? targetTime,
  }) async {
    try {
      final result = await remoteDataSource.predictCrowd(
        locationId: locationId,
        targetTime: targetTime,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
