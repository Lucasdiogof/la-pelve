import 'package:fisioterapia_pelvica/core/error/failures.dart';

/// A lightweight, dependency-free stand-in for `Either<Failure, T>`.
///
/// Repositories return `Future<Result<T>>` instead of throwing, so use
/// cases and Cubits always handle the failure path explicitly:
///
/// ```dart
/// final result = await repository.getPatients();
/// switch (result) {
///   case Success(:final data): emit(PatientsLoaded(data));
///   case Error(:final failure): emit(PatientsError(failure.message));
/// }
/// ```
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

class Error<T> extends Result<T> {
  const Error(this.failure);

  final Failure failure;
}
