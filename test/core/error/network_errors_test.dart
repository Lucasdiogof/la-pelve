import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/network_errors.dart';

void main() {
  test('erros de rede e tempo esgotado viram NetworkFailure', () {
    expect(failureFromException(TimeoutException('t')), isA<NetworkFailure>());
    expect(
      failureFromException(http.ClientException('Failed host lookup')),
      isA<NetworkFailure>(),
    );
    expect(
      failureFromException(AuthRetryableFetchException(message: 'offline')),
      isA<NetworkFailure>(),
    );
  });

  test('sessão inválida e erros comuns não são tratados como rede', () {
    expect(failureFromException(StateError('x')), isA<UnexpectedFailure>());
    expect(
      isNetworkError(
        const AuthApiException('x', statusCode: '400', code: 'bad'),
      ),
      isFalse,
    );
  });
}
