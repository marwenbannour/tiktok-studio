import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tiktok_studio/claude_api.dart';

void main() {
  http.Response ok(String content) => http.Response(
        jsonEncode({
          'message': {'role': 'assistant', 'content': content}
        }),
        200,
        headers: {'content-type': 'application/json'},
      );

  test('وضع backend: ينادي السيرفر الوسيط بـx-app-token بلا Bearer', () async {
    late http.Request captured;
    final mock = MockClient((req) async {
      captured = req;
      return ok('سلام');
    });
    final api = ClaudeApi(
      apiKey: '',
      model: 'gemma4:31b',
      backendUrl: 'https://proj.supabase.co/functions/v1/generate',
      appToken: 'secret123',
    );

    final r = await http.runWithClient(() => api.ask('مرحبا'), () => mock);

    expect(r, 'سلام');
    expect(captured.url.toString(),
        'https://proj.supabase.co/functions/v1/generate');
    expect(captured.headers['x-app-token'], 'secret123');
    expect(captured.headers.containsKey('authorization'), isFalse);
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], 'gemma4:31b');
    expect((body['messages'] as List).first['content'], 'مرحبا');
  });

  test('وضع مباشر: ينادي ollama.com بـBearer بلا x-app-token', () async {
    late http.Request captured;
    final mock = MockClient((req) async {
      captured = req;
      return ok('ok');
    });
    final api = ClaudeApi(apiKey: 'KEY123', model: 'gemma4:31b');

    await http.runWithClient(() => api.ask('x', json: true), () => mock);

    expect(captured.url.toString(), 'https://ollama.com/api/chat');
    expect(captured.headers['authorization'], 'Bearer KEY123');
    expect(captured.headers.containsKey('x-app-token'), isFalse);
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['format'], 'json');
  });

  test('usesBackend: حسب وجود backendUrl', () {
    expect(ClaudeApi(apiKey: 'k', model: 'm').usesBackend, isFalse);
    expect(ClaudeApi(apiKey: '', model: 'm', backendUrl: 'https://x').usesBackend,
        isTrue);
    expect(ClaudeApi(apiKey: '', model: 'm', backendUrl: '   ').usesBackend,
        isFalse);
  });

  test('backend يرجّع خطأ → ClaudeException', () async {
    final mock = MockClient(
        (req) async => http.Response(jsonEncode({'error': 'bad token'}), 401));
    final api = ClaudeApi(
        apiKey: '', model: 'm', backendUrl: 'https://x', appToken: 'wrong');

    await expectLater(
      http.runWithClient(() => api.ask('x'), () => mock),
      throwsA(isA<ClaudeException>()),
    );
  });
}
