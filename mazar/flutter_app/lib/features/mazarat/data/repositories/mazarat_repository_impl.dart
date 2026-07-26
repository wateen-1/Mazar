import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/mazar_entity.dart';
import '../../domain/repositories/mazarat_repository.dart';
import '../datasources/mazarat_remote_datasource.dart';

/// التنفيذ الفعلي لمستودع بيانات المزارات، يربط طبقة النطاق بمصدر البيانات.
class MazaratRepositoryImpl implements MazaratRepository {
  final MazaratRemoteDataSource remoteDataSource;

  MazaratRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<MazarEntity>>> getNearbyMazarat({
    required double latitude,
    required double longitude,
    double radiusInKm = 5,
  }) async {
    try {
      final result = await remoteDataSource.getNearbyMazarat(
        latitude: latitude,
        longitude: longitude,
        radiusInKm: radiusInKm,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MazarEntity>> activateMazar({
    required String mazarId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final result = await remoteDataSource.activateMazar(
        mazarId: mazarId,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(result);
    } on OutOfRangeException catch (e) {
      // نحوّل استثناء "خارج النطاق" إلى فشل مخصص (LocationOutOfRangeFailure)
      // بدلاً من ServerFailure العام، حتى تستطيع واجهة المستخدم تمييزه
      // بسهولة عبر فحص نوع الفشل (failure is LocationOutOfRangeFailure)
      // وعرض رسالة لبقة له بدلاً من رسالة خطأ عامة.
      return Left(LocationOutOfRangeFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
