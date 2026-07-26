import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// عقد أساسي تلتزم به جميع حالات الاستخدام (Use Cases) في تطبيق مزار.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// يُستخدم لحالات الاستخدام التي لا تحتاج إلى أي معاملات مدخلة.
class NoParams {
  const NoParams();
}
