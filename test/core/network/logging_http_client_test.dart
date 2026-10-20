import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:la_pelve/core/network/logging_http_client.dart';

void main() {
  late List<String> logs;
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    logs = [];
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
  });

  tearDown(() => debugPrint = originalDebugPrint);

  LoggingHttpClient clientReturning(String body, {int status = 200}) =>
      LoggingHttpClient(MockClient((_) async => http.Response(body, status)));

  test('returns the response body intact after logging it', () async {
    final client = clientReturning('{"ok":true}');
    final response = await client.get(Uri.parse('https://x.test/rest/v1/foo'));
    expect(response.statusCode, 200);
    expect(response.body, '{"ok":true}');
    expect(logs.join('\n'), contains('{"ok":true}'));
  });

  test('omits request and response bodies for sensitive tables', () async {
    final client = clientReturning('segredo-resposta');
    await client.post(
      Uri.parse('https://x.test/rest/v1/patients'),
      body: 'segredo-pedido',
    );
    final all = logs.join('\n');
    expect(all, contains('omitido: dados clínicos'));
    expect(all, isNot(contains('segredo-pedido')));
    expect(all, isNot(contains('segredo-resposta')));
  });

  test('does not hide bodies of non sensitive tables', () async {
    final client = clientReturning('resp');
    await client.post(
      Uri.parse('https://x.test/rest/v1/appointments'),
      body: 'pedido-visivel',
    );
    final all = logs.join('\n');
    expect(all, contains('pedido-visivel'));
    expect(all, isNot(contains('omitido')));
  });

  test('truncates long bodies to 2000 chars with the total', () async {
    final long = 'a' * 2500;
    final client = clientReturning(long);
    final response = await client.get(Uri.parse('https://x.test/rest/v1/foo'));
    expect(response.body.length, 2500);
    final all = logs.join('\n');
    expect(all, contains('(2500 chars total)'));
    expect(all, isNot(contains('a' * 2001)));
  });

  test('preserves status code and headers', () async {
    final client = LoggingHttpClient(
      MockClient((_) async => http.Response('', 404, headers: {'x-test': '1'})),
    );
    final response = await client.get(Uri.parse('https://x.test/foo'));
    expect(response.statusCode, 404);
    expect(response.headers['x-test'], '1');
  });

  test('preserves utf8 bodies', () async {
    final client = LoggingHttpClient(
      MockClient((_) async => http.Response.bytes(utf8.encode('ação'), 200)),
    );
    final response = await client.get(Uri.parse('https://x.test/foo'));
    expect(utf8.decode(response.bodyBytes), 'ação');
  });

  test('logs and rethrows errors from the inner client', () async {
    final client = LoggingHttpClient(
      MockClient((_) async => throw http.ClientException('boom')),
    );
    await expectLater(
      client.get(Uri.parse('https://x.test/foo')),
      throwsA(isA<http.ClientException>()),
    );
    expect(logs.join('\n'), contains('failed after'));
  });
}
