import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_studio/backup.dart';
import 'package:tiktok_studio/db/database.dart';

void main() {
  late AppDatabase db;

  ScriptsCompanion row(String title, String cat,
          {int? created, int? views, String? series, int? ep, bool fav = false}) =>
      ScriptsCompanion.insert(
        title: title,
        category: cat,
        style: 'الشاشة فقط',
        duration: 20,
        content: '{"voice":"$title"}',
        createdAt: created ?? DateTime.now().microsecondsSinceEpoch,
        isFavorite: Value(fav),
        views: Value(views),
        seriesTitle: Value(series),
        episode: Value(ep),
      );

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('export يبني JSON صالح بكل السكريبتات', () async {
    await db.add(row('a', 'Dev AI', created: 1000, views: 500, fav: true));
    await db.add(row('b', 'Football', created: 2000, series: 'كورة', ep: 1));

    final json = await Backup.exportJson(db: db);
    final map = jsonDecode(json) as Map<String, dynamic>;

    expect(map['app'], 'studio_tiktok');
    expect(map['version'], 1);
    expect(map['count'], 2);
    final scripts = map['scripts'] as List;
    expect(scripts.length, 2);
    // ما فماش id في التصدير
    expect((scripts.first as Map).containsKey('id'), isFalse);
    // الحقول محفوظة
    final a = scripts.firstWhere((e) => e['title'] == 'a') as Map;
    expect(a['views'], 500);
    expect(a['isFavorite'], true);
    final b = scripts.firstWhere((e) => e['title'] == 'b') as Map;
    expect(b['seriesTitle'], 'كورة');
    expect(b['episode'], 1);
  });

  test('round-trip: export من قاعدة → import في قاعدة فارغة', () async {
    await db.add(row('a', 'Dev AI', created: 1000, views: 500, fav: true));
    await db.add(row('b', 'Football', created: 2000, series: 'كورة', ep: 1));
    final json = await Backup.exportJson(db: db);

    final db2 = AppDatabase.forTesting(NativeDatabase.memory());
    final r = await Backup.importJson(json, db: db2);
    expect(r.added, 2);
    expect(r.skipped, 0);

    final all = await db2.search();
    expect(all.length, 2);
    final a = await db2.byCreatedAt(1000);
    expect(a!.title, 'a');
    expect(a.views, 500);
    expect(a.isFavorite, true);
    final b = await db2.byCreatedAt(2000);
    expect(b!.seriesTitle, 'كورة');
    expect(b.episode, 1);
    await db2.close();
  });

  test('import يتخطّى اللي موجودين (نفس createdAt) — بلا تكرار', () async {
    await db.add(row('a', 'Dev AI', created: 1000));
    final json = await Backup.exportJson(db: db);

    // نزيدو سكريبت جديد في الملف ونعاودو import على نفس القاعدة
    await db.add(row('c', 'Faits', created: 3000));
    final json2 = await Backup.exportJson(db: db); // فيه a(1000) + c(3000)

    final r = await Backup.importJson(json2, db: db); // a موجود، c موجود
    expect(r.added, 0);
    expect(r.skipped, 2);
    expect(await db.total(), 2); // ما تضاعفوش

    // import ملف قديم (فيه a برك) ما يبدّل والو
    final r2 = await Backup.importJson(json, db: db);
    expect(r2.added, 0);
    expect(await db.total(), 2);
  });

  test('import يرمي FormatException على ملف موش صالح', () async {
    await expectLater(Backup.importJson('{}', db: db), throwsFormatException);
    await expectLater(
        Backup.importJson('{"app":"autre","scripts":[]}', db: db), throwsFormatException);
    await expectLater(Backup.importJson('pas du json', db: db), throwsFormatException);
  });
}
