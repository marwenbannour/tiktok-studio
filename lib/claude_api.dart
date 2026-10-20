import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'storage.dart';

class ClaudeException implements Exception {
  final String message;

  /// الرسالة الأصلية متاع الـAPI (للـdebug، ما تبانش للمستعمل)
  final String? apiMessage;
  ClaudeException(this.message, {this.apiMessage});
  @override
  String toString() => message;
}

/// اتصال بـOllama Cloud API (endpoint: /api/chat)
/// https://docs.ollama.com/cloud/api
///
/// وضعين:
///  - مباشر: المفتاح على التليفون، ننادي ollama.com مباشرة.
///  - سيرفر وسيط (backend): المفتاح مخبّي في السيرفر (Supabase Edge Function)،
///    ننادي [backendUrl] بـheader x-app-token، والسيرفر يعدّي لـOllama.
///    نفس شكل الطلب والجواب باش الكود يبقى واحد.
class ClaudeApi {
  static const _ollamaUrl = 'https://ollama.com/api/chat';

  final String apiKey;
  final String model;
  final String? backendUrl;
  final String? appToken;

  ClaudeApi({
    required this.apiKey,
    required this.model,
    this.backendUrl,
    this.appToken,
  });

  bool get usesBackend => (backendUrl?.trim().isNotEmpty) ?? false;

  /// بالإعدادات المسجّلة: كان فمّا backend نمشيو بيه (بلا مفتاح محلّي)،
  /// وإلّا نلزمو المفتاح المحلّي. يرجّع null كان لا backend لا مفتاح.
  static Future<ClaudeApi?> fromSettings() async {
    final model = await AppStorage.getModel();
    final backend = await AppStorage.getBackendUrl();
    if (backend != null && backend.trim().isNotEmpty) {
      final token = await AppStorage.getAppToken();
      return ClaudeApi(
        apiKey: '',
        model: model,
        backendUrl: backend.trim(),
        appToken: token?.trim(),
      );
    }
    final key = await AppStorage.getApiKey();
    if (key == null || key.trim().isEmpty) return null;
    return ClaudeApi(apiKey: key.trim(), model: model);
  }

  static const noKeyMessage =
      'زيد مفتاح الـAPI (ولا عنوان السيرفر) في «الإعدادات» قبل.';

  Future<String> ask(String prompt, {int maxTokens = 4000, bool json = false}) async {
    final headers = <String, String>{'content-type': 'application/json'};
    if (usesBackend) {
      if ((appToken ?? '').isNotEmpty) headers['x-app-token'] = appToken!;
    } else {
      headers['authorization'] = 'Bearer $apiKey';
    }

    final res = await http
        .post(
          Uri.parse(usesBackend ? backendUrl!.trim() : _ollamaUrl),
          headers: headers,
          body: jsonEncode({
            'model': model,
            'stream': false,
            if (json) 'format': 'json',
            'options': {'num_predict': maxTokens},
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          }),
        )
        .timeout(const Duration(seconds: 120));

    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ClaudeException('جواب غريب من السيرفر (${res.statusCode}).');
    }

    if (res.statusCode != 200) {
      final err = body is Map ? body['error'] : null;
      throw ClaudeException(_friendly(res.statusCode),
          apiMessage: err is String ? err : (err is Map ? '${err['message']}' : null));
    }

    final msg = body is Map ? body['message'] : null;
    final content = msg is Map ? msg['content'] : null;
    return content is String ? content : '';
  }

  /// يطلب جواب JSON وينظّفو
  Future<Map<String, dynamic>> askJson(String prompt, {int maxTokens = 4000}) async {
    final text = await ask(prompt, maxTokens: maxTokens, json: true);
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw ClaudeException('الجواب ما جاش في الشكل الصحيح. عاود جرّب.');
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(clean.substring(start, end + 1)));
    } catch (_) {
      throw ClaudeException('الجواب ما جاش في الشكل الصحيح. عاود جرّب.');
    }
  }

  static String _friendly(int code) {
    switch (code) {
      case 401:
      case 403:
        return 'المفتاح موش صحيح ولا ما عندوش الحق. ثبّت فيه في «الإعدادات».';
      case 400:
        return 'الطلب ما تقبلش. ثبّت في اسم الموديل في «الإعدادات».';
      case 402:
        return 'الرصيد كمل. زيد رصيد في ollama.com.';
      case 404:
        return 'الموديل موش موجود. ثبّت في اسمو في «الإعدادات» (ollama.com/library).';
      case 429:
        return 'برشا طلبات ولا كمل الرصيد. استنّى شوية وعاود.';
      case 502:
      case 503:
      case 529:
        return 'السيرفر مشغول توّا. عاود بعد شوية.';
      default:
        return 'صار مشكل ($code). عاود جرّب.';
    }
  }
}

String errorMessage(Object e) {
  if (e is ClaudeException) return e.message;
  if (e is TimeoutException) return 'طوّل برشا. ثبّت في الكونكسيون وعاود.';
  if (e is SocketException) return 'ما فماش كونكسيون. ثبّت في الإنترنت.';
  return 'صار مشكل. عاود جرّب.';
}
