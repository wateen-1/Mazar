import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/crowd_entity.dart';

/// عقد مستودع بيانات توقع الازدحام، تلتزم به الطبقة الفعلية في مجلد data/.
abstract class CrowdRepository {
  /// يستعلم عن توقع الازدحام لمكان معيّن عبر نقطة النهاية /crowd.
  Future<Either<Failure, CrowdPredictionEntity>> predictCrowd({
    required String locationId,
    DateTime? targetTime,
  });
}
