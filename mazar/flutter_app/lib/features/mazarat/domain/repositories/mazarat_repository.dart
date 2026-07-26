import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/mazar_entity.dart';

/// عقد مستودع بيانات المزارات التفاعلية، تلتزم به الطبقة الفعلية في data/.
abstract class MazaratRepository {
  /// يجلب المزارات القريبة اعتماداً على إحداثيات المستخدم الحالية من GPS.
  Future<Either<Failure, List<MazarEntity>>> getNearbyMazarat({
    required double latitude,
    required double longitude,
    double radiusInKm = 5,
  });

  /// يفعّل مزاراً معيناً عند وصول المستخدم فعلياً إلى إحداثياته.
  Future<Either<Failure, MazarEntity>> activateMazar({
    required String mazarId,
    required double latitude,
    required double longitude,
  });
}
