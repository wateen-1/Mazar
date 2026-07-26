import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/planner_entity.dart';

/// عقد مستودع بيانات المخطط الذكي، تلتزم به الطبقة الفعلية في مجلد data/.
abstract class PlannerRepository {
  /// يرسل تفضيلات المستخدم إلى نقطة النهاية /planner ويعيد جدولاً ذكياً.
  Future<Either<Failure, List<PlannerItemEntity>>> generatePlan(
    PlannerRequestEntity request,
  );
}
