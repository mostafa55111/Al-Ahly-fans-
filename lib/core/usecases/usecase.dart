import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';

/// واجهة أساسية لجميع Use Cases
/// توفر معيار موحد للعمل مع Use Cases
abstract class UseCase<T, Params> {
  /// استدعاء Use Case
  ///
  /// المعاملات:
  /// - [params]: معاملات Use Case
  ///
  /// القيمة المرجعة:
  /// - [Right]: النتيجة الناجحة
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, T>> call(Params params);
}

/// Use Case بدون معاملات
abstract class UseCaseNoParams<T> {
  /// استدعاء Use Case بدون معاملات
  ///
  /// القيمة المرجعة:
  /// - [Right]: النتيجة الناجحة
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, T>> call();
}
