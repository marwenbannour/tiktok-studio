import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// حسابات Supabase عبر REST (/auth/v1) — بلا package ثقيل، بـhttp برك.
class Auth {
  static Future<({String url, String anon})?> _config() async {
    final url = await AppStorage.getSupabaseUrl();
    final anon = await AppStorage.getSupabaseAnonKey();
    if (url == null || anon == null) return null;
    return (url: url, anon: anon);
  }

  static Future<bool> get isLoggedIn async => (await AppStorage.getSession()) != null;
  static Future<String?> get email async =>
      (await AppStorage.getSession())?['email'] as String?;

  static const _noConfig = 'زيد إعدادات Supabase (URL + anon key) في «الإعدادات» قبل.';

  /// تسجيل حساب جديد. كان confirm email مفعّل، ما يرجّعش session فورًا.
  /// يرجّع true كان ولّى داخل (session موجودة)، false كان لازم تأكيد الإيميل.
  static Future<bool> signUp(String email, String password) async {
    final c = await _config();
    if (c == null) throw AuthException(_noConfig);
    final body = await _post(c, '/auth/v1/signup', {'email': email, 'password': password});
    if (body['access_token'] != null) {
      await _saveSession(body);
      return true;
    }
    return false; // يستنّى تأكيد الإيميل
  }

  static Future<void> signIn(String email, String password) async {
    final c = await _config();
    if (c == null) throw AuthException(_noConfig);
    final body =
        await _post(c, '/auth/v1/token?grant_type=password', {'email': email, 'password': password});
    await _saveSession(body);
  }

  static Future<void> signOut() => AppStorage.setSession(null);

  /// access token صالح (يعمل refresh كان قرب يفوت). null كان ما فماش login.
  static Future<String?> validToken() async {
    final s = await AppStorage.getSession();
    if (s == null) return null;
    return s['access_token'] as String?;
  }

  /// يجدّد الـtoken بالـrefresh token. يرجّع الجديد ولا null (ويسجّل الخروج).
  static Future<String?> refresh() async {
    final c = await _config();
    final s = await AppStorage.getSession();
    final rt = s?['refresh_token'] as String?;
    if (c == null || rt == null) return null;
    try {
      final body = await _post(c, '/auth/v1/token?grant_type=refresh_token', {'refresh_token': rt});
      await _saveSession(body);
      return body['access_token'] as String?;
    } catch (_) {
      await signOut();
      return null;
    }
  }

  static Future<Map<String, dynamic>> _post(
      ({String url, String anon}) c, String path, Map<String, dynamic> payload) async {
    final http.Response res;
    try {
      res = await http
          .post(Uri.parse('${c.url}$path'),
              headers: {'content-type': 'application/json', 'apikey': c.anon},
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw AuthException('طوّل برشا. ثبّت في الكونكسيون وعاود.');
    } catch (_) {
      throw AuthException('ما فماش كونكسيون ولا العنوان غالط.');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      throw AuthException(_friendly(body is Map ? body : {}));
    }
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  static Future<void> _saveSession(Map body) async {
    final user = (body['user'] ?? {}) as Map;
    await AppStorage.setSession({
      'access_token': body['access_token'],
      'refresh_token': body['refresh_token'],
      'user_id': user['id'],
      'email': user['email'],
    });
  }

  static String _friendly(Map body) {
    final msg = (body['msg'] ?? body['error_description'] ?? body['error'] ?? body['message'])
        ?.toString();
    if (msg == null) return 'صار مشكل في الحساب. عاود جرّب.';
    final m = msg.toLowerCase();
    if (m.contains('invalid login')) return 'الإيميل ولا كلمة السرّ غالطين.';
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'الإيميل هذا مسجّل ديجا. ادخل بيه.';
    }
    if (m.contains('password') && m.contains('6')) return 'كلمة السرّ لازم 6 حروف على الأقلّ.';
    if (m.contains('email') && m.contains('confirm')) return 'لازم تأكّد الإيميل متاعك الأول.';
    return msg;
  }
}
