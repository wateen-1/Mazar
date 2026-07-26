import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/planner_entity.dart';
import '../../domain/repositories/planner_repository.dart';
import '../datasources/planner_remote_datasource.dart';

/// التنفيذ الفعلي لمستودع بيانات المخطط الذكي، يربط طبقة النطاق بمصدر
/// البيانات، ويحوّل استثناءات الشبكة/الخادم إلى أنواع Failure مخصصة
/// ومميّزة، حتى تستطيع الواجهة عرض رسائل الخطأ المناسبة (مشكلة اتصال
/// بالإنترنت مقابل خطأ فعلي من الخادم) بلباقة ووضوح للمستخدم.
class PlannerRepositoryImpl implements PlannerRepository {
  final PlannerRemoteDataSource remoteDataSource;

  PlannerRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<PlannerItemEntity>>> generatePlan(
    PlannerRequestEntity request,
  ) async {
    try {
      final items = await remoteDataSource.generatePlan(
        visitDate: request.visitDate.toIso8601String(),
        numberOfDays: request.numberOfDays,
        preferredCategories: request.preferredCategories,
        currentLatitude: request.currentLatitude,
        currentLongitude: request.currentLongitude,
      );
      return Right(items);
    } on NoInternetException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
