import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';

void main() {
  group('Result', () {
    test('Success carries the given data', () {
      const result = Success<int>(42);
      expect(result.data, 42);
    });

    test('Error carries the given failure', () {
      final failure = ServerFailure();
      final result = Error<int>(failure);
      expect(result.failure, failure);
    });

    test('pattern matching distinguishes Success from Error', () {
      const Result<int> result = Success(1);
      final matched = switch (result) {
        Success(:final data) => 'success:$data',
        Error() => 'error',
      };
      expect(matched, 'success:1');
    });
  });

  group('Failure', () {
    test('failures with the same message are equal', () {
      expect(ServerFailure('x'), ServerFailure('x'));
    });

    test('AuthFailure equality considers isInvalidCredentials', () {
      final a = AuthFailure('x', true);
      final b = AuthFailure('x', false);
      expect(a == b, isFalse);
    });

    test('default messages are set', () {
      expect(NetworkFailure().message, isNotEmpty);
      expect(CacheFailure().message, isNotEmpty);
      expect(UnexpectedFailure().message, isNotEmpty);
    });
  });
}
