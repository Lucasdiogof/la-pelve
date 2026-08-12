import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _sensitiveTables = [
  'patients',
  'evolution_entries',
  'attachments',
  'profiles',
];

class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  bool _isSensitive(Uri url) =>
      _sensitiveTables.any((table) => url.path.contains(table));

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    final sensitive = _isSensitive(request.url);
    final body = request is http.Request && request.body.isNotEmpty
        ? request.body
        : null;
    debugPrint(
      '[http] → ${request.method} ${request.url}'
      '${body == null ? '' : '\n  body: ${sensitive ? '(omitido: dados clínicos)' : _truncate(body)}'}',
    );
    try {
      final response = await _inner.send(request);
      final bytes = await response.stream.toBytes();
      debugPrint(
        '[http] ← ${response.statusCode} ${request.method} ${request.url} '
        '(${stopwatch.elapsedMilliseconds}ms)'
        '${bytes.isEmpty ? '' : '\n  body: ${sensitive ? '(omitido: dados clínicos)' : _truncate(utf8.decode(bytes, allowMalformed: true))}'}',
      );
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e, st) {
      debugPrint(
        '[http] ✗ ${request.method} ${request.url} failed after '
        '${stopwatch.elapsedMilliseconds}ms: $e\n$st',
      );
      rethrow;
    }
  }

  String _truncate(String value, [int maxLength = 2000]) =>
      value.length <= maxLength
      ? value
      : '${value.substring(0, maxLength)}… (${value.length} chars total)';
}
