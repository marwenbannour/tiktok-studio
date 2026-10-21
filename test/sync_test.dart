import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_studio/db/database.dart';
import 'package:tiktok_studio/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ScriptsCompanion row(String title, {int? created, int? views}) =>
      ScriptsCompanion.insert(
        title: title,
        category: 'Dev AI',
        style: 'الشاشة فقط',
        duration: 20,
        content: '{"voice":"$title"}',
        createdAt: created ?? DateTime.now().microsecondsSinceEpoch,
        views: Value(views),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'supabase_url': 'https://proj.supabase.co',
      'supabase_anon': 'anon123',
    });
    // secure storage: نرجّعو session صالحة لأي read
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'read') {
        return jsonEncode({
          'access_token': 'tok',
          'refresh_token': 'rt',
          'user_id': 'u1',
          'email': 'a@b.c',
        });
      }
      return null;
    });
    AppDatabase.instance = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => AppDatabase.instance.close());

  test('push: upsert لكل السكريبتات بالتوكن والـPrefer merge', () async {
    await AppDatabase.instance.add(row('a', created: 1000, views: 50));
    await AppDatabase.instance.add(row('b', created: 2000));

    late http.Request captured;
    final mock = MockClient((req) async {
      captured = req;
      return http.Response('', 201);
    });

    final n = await http.runWithClient(() => Sync.push(), () => mock);
    expect(n, 2);
    expect(captured.method, 'POST');
    expect(captured.url.toString(),
        'https://proj.supabase.co/rest/v1/scripts?on_conflict=user_id,created_at');
    expect(captured.headers['authorization'], 'Bearer tok');
    expect(captured.headers['apikey'], 'anon123');
    expect(captured.headers['prefer'], contains('merge-duplicates'));
    final body = jsonDecode(captured.body) as List;
    expect(body.length, 2);
    final a = body.firstWhere((e) => e['title'] == 'a') as Map;
    expect(a['created_at'], 1000);
    expect(a['views'], 50);
    expect(a['is_favorite'], false); // snake_case
    expect(a.containsKey('user_id'), isFalse); // السيرفر يحطّو (default auth.uid())
  });

  test('pull: يزيد الناقصين ويتخطّى الموجودين (dedup بـcreated_at)', () async {
    await AppDatabase.instance.add(row('موجود', created: 1000)); // ديجا محلّي

    final remote = [
      {
        'created_at': 1000, 'title': 'موجود', 'category': 'Dev AI', 'style': 's',
        'duration': 20, 'content': '{}', 'model': '', 'is_favorite': false,
        'published_at': null, 'views': null, 'likes': null, 'comments': null,
        'series_title': null, 'episode': null,
      },
      {
        'created_at': 3000, 'title': 'جديد', 'category': 'Football', 'style': 's',
        'duration': 30, 'content': '{}', 'model': 'gemma4:31b', 'is_favorite': true,
        'published_at': null, 'views': 99, 'likes': null, 'comments': null,
        'series_title': 'كورة', 'episode': 2,
      },
    ];
    final mock = MockClient(
        (req) async => http.Response.bytes(utf8.encode(jsonEncode(remote)), 200));

    final r = await http.runWithClient(() => Sync.pull(), () => mock);
    expect(r.added, 1);
    expect(r.skipped, 1);
    expect(await AppDatabase.instance.total(), 2);
    final jdid = await AppDatabase.instance.byCreatedAt(3000);
    expect(jdid!.title, 'جديد');
    expect(jdid.isFavorite, true);
    expect(jdid.seriesTitle, 'كورة');
    expect(jdid.episode, 2);
    expect(jdid.views, 99);
  });

  test('push يجدّد التوكن عند 401 ويعاود', () async {
    await AppDatabase.instance.add(row('a', created: 1000));
    var calls = 0;
    final mock = MockClient((req) async {
      calls++;
      // أول نداء للـREST = 401، نداء auth refresh = 200، ثاني REST = 201
      if (req.url.path.contains('/auth/v1/token')) {
        return http.Response(
            jsonEncode({
              'access_token': 'tok2',
              'refresh_token': 'rt2',
              'user': {'id': 'u1', 'email': 'a@b.c'}
            }),
            200);
      }
      return http.Response('', calls == 1 ? 401 : 201);
    });

    final n = await http.runWithClient(() => Sync.push(), () => mock);
    expect(n, 1); // نجح بعد التجديد
  });
}
