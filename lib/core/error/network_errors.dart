import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/error/failures.dart';

/// Falha de rede/tempo esgotado (sem internet, DNS, servidor fora do ar,
/// renovação de token impossível agora). Não é erro de autorização nem de
/// dado: a sessão local continua válida e a operação pode ser repetida.
bool isNetworkError(Object error) =>
    error is TimeoutException ||
    error is http.ClientException ||
    error is AuthRetryableFetchException ||
    error.runtimeType.toString() == 'SocketException';

/// Traduz uma exceção inesperada em [NetworkFailure] (rede) ou
/// [UnexpectedFailure] (qualquer outra).
Failure failureFromException(Object error) =>
    isNetworkError(error) ? NetworkFailure() : UnexpectedFailure();
