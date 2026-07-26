import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../domain/usecases/base_usecase.dart';
import '../entities/mazar_entity.dart';
import '../repositories/mazarat_repository.dart';

/// المعاملات المطلوبة لطلب تفعيل التجربة التفاعلية لمزار معيّن: معرّف
/// المزار، وإحداثيات موقع المستخدم الحالية (يجب أن تكون حديثة ودقيقة،
/// لأن الخادم يتحقق منها فعلياً مقابل موقع المعلم قبل السماح بالتفعيل).
class ActivateMazarParams {
  final String mazarId;
  final double latitude;
  final double longitude;

  const ActivateMazarParams({
    required this.mazarId,
    required this.latitude,
    required this.longitude,
  });
}

/// حالة الاستخدام المسؤولة عن طلب تفعيل التجربة التفاعلية لمزار معيّن عبر
/// نقطة النهاية POST /mazarat/{mazar_id}/activate. تعيد إما بيانات المزار
/// كاملة عند النجاح، أو Failure (وتحديداً LocationOutOfRangeFailure عندما
/// يكون المستخدم خارج نطاق 100 متر المسموح به) عند الفشل.
class ActivateMazarUseCase implements UseCase<MazarEntity, ActivateMazarParams> {
  final MazaratRepository repository;

  ActivateMazarUseCase(this.repository);

  @override
  Future<Either<Failure, MazarEntity>> call(ActivateMazarParams params) {
    return repository.activateMazar(
      mazarId: params.mazarId,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}
