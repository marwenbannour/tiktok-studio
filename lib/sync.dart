import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import 'auth.dart';
import 'db/database.dart';
import 'storage.dart';

class SyncException implements Exception {
  final String message;
  SyncException(this.message);
  @override
  String toString() => message;
}

/// مزامنة الـhistorique مع Supabase (جدول public.scripts، RLS لكل مستخدم).
/// المفتاح الطبيعي (user_id, created_at) → بلا تكرار من عدّة أجهزة.
class Sync {
  static Future<({String url, String anon})?> _cfg() async {
    final url = await AppStorage.getSupabaseUrl();
    final anon = await AppStorage.getSupabaseAnonKey();
    if (url == null || anon == null) return null;
    return (url: url, anon: anon);
  }

  static Map<String, dynamic> _localToRemote(Script s) => {
        'created_at': s.createdAt,
        'title': s.title,
        'category': s.category,
        'style': s.style,
        'duration': s.duration,
        'content': s.content,
        'model': s.model,
        'is_favorite': s.isFavorite,
        'published_at': s.publishedAt,
        'views': s.views,
        'likes': s.likes,
        'comments': s.comments,
        'series_title': s.seriesTitle,
        'episode': s.episode,
      };

  static ScriptsCompanion _remoteToCompanion(Map<String, dynamic> m) =>
      ScriptsCompanion.insert(
        title: m['title'] as String,
        category: m['category'] as String,
        style: m['style'] as String,
        duration: (m['duration'] as num).toInt(),
        content: m['content'] as String,
        model: Value(m['model'] as String? ?? ''),
        isFavorite: Value(m['is_favorite'] as bool? ?? false),
        publishedAt: Value((m['published_at'] as num?)?.toInt()),
        createdAt: (m['created_at'] as num).toInt(),
        views: Value((m['views'] as num?)?.toInt()),
        likes: Value((m['likes'] as num?)?.toInt()),
        comments: Value((m['comments'] as num?)?.toInt()),
        seriesTitle: Value(m['series_title'] as String?),
        episode: Value((m['episode'] as num?)?.toInt()),
      );

  /// ينفّذ طلب http بالتوكن، ويجدّدو مرّة وحدة عند 401
  static Future<http.Response> _authed(
      Future<http.Response> Function(String token) run) async {
    final token = await Auth.validToken();
    if (token == null) throw SyncException('لازم تدخل للحساب الأول.');
    var res = await run(token);
    if (res.statusCode == 401) {
      final nt = await Auth.refresh();
      if (nt == null) throw SyncException('انتهت الجلسة. ادخل مرّة أخرى.');
      res = await run(nt);
    }
    return res;
  }

  /// يرفع كل السكريبتات المحلّية (upsert). يرجّع العدد.
  static Future<int> push({AppDatabase? db}) async {
    final c = await _cfg();
    if (c == null) throw SyncException('زيد إعدادات Supabase في «الإعدادات».');
    final d = db ?? AppDatabase.instance;
    final rows = await d.search();
    if (rows.isEmpty) return 0;
    final payload = rows.map(_localToRemote).toList();
    final res = await _authed((t) => http
        .post(
          Uri.parse('${c.url}/rest/v1/scripts?on_conflict=user_id,created_at'),
          headers: {
            'content-type': 'application/json',
            'apikey': c.anon,
            'authorization': 'Bearer $t',
            'prefer': 'resolution=merge-duplicates,return=minimal',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60)));
    if (res.statusCode >= 400) throw SyncException(_err(res));
    return rows.length;
  }

  /// يجيب سكريبتات المستخدم ويزيد الناقصين محلّيًا (dedup بـcreated_at).
  static Future<({int added, int skipped})> pull({AppDatabase? db}) async {
    final c = await _cfg();
    if (c == null) throw SyncException('زيد إعدادات Supabase في «الإعدادات».');
    final d = db ?? AppDatabase.instance;
    final res = await _authed((t) => http.get(
          Uri.parse('${c.url}/rest/v1/scripts?select=*&order=created_at.desc'),
          headers: {'apikey': c.anon, 'authorization': 'Bearer $t'},
        ).timeout(const Duration(seconds: 60)));
    if (res.statusCode >= 400) throw SyncException(_err(res));
    final list = jsonDecode(utf8.decode(res.bodyBytes));
    if (list is! List) throw SyncException('جواب غير متوقّع من السيرفر.');
    var added = 0, skipped = 0;
    for (final item in list) {
      if (item is! Map) continue;
      final m = item.cast<String, dynamic>();
      final created = (m['created_at'] as num?)?.toInt();
      if (created != null && await d.byCreatedAt(created) != null) {
        skipped++;
        continue;
      }
      await d.add(_remoteToCompanion(m));
      added++;
    }
    return (added: added, skipped: skipped);
  }

  /// مزامنة كاملة: push (المحلّي → السحابة) ثمّ pull (السحابة → المحلّي).
  static Future<({int pushed, int added})> syncAll({AppDatabase? db}) async {
    final pushed = await push(db: db);
    final pulled = await pull(db: db);
    return (pushed: pushed, added: pulled.added);
  }

  static String _err(http.Response res) {
    try {
      final b = jsonDecode(utf8.decode(res.bodyBytes));
      final msg = b is Map ? (b['message'] ?? b['hint'] ?? b['error']) : null;
      if (msg != null) return 'المزامنة فشلت: $msg';
    } catch (_) {}
    return 'المزامنة فشلت (${res.statusCode}).';
  }
}
