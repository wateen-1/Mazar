import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// واجهة أساسية عامة تلتزم بها مستودعات البيانات، تعيد إما Failure
/// أو نتيجة ناجحة من النوع T، باستخدام نمط Either من مكتبة dartz.
abstract class BaseRepositoryInterface<T> {
  Future<Either<Failure, T>> execute();
}
