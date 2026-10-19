import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_studio/db/database.dart';

void main() {
  late AppDatabase db;

  ScriptsCompanion row(String title, String cat,
          {int dur = 20, int? created, String content = '', String? series, int? ep}) =>
      ScriptsCompanion.insert(
        title: title,
        category: cat,
        style: 'الشاشة فقط',
        duration: dur,
        content: content.isEmpty ? '{"voice":"$title"}' : content,
        createdAt: created ?? DateTime.now().microsecondsSinceEpoch,
        seriesTitle: Value(series),
        episode: Value(ep),
      );

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('F16: حفظ بلا حدّ (أكثر من 30)', () async {
    for (var i = 0; i < 50; i++) {
      await db.add(row('سكريبت $i', 'Dev AI', created: 1000 + i));
    }
    expect(await db.total(), 50);
    final all = await db.search();
    expect(all.length, 50);
    // ترتيب حسب التاريخ (الأحدث أول) — F23
    expect(all.first.createdAt, 1049);
    expect(all.last.createdAt, 1000);
  });

  test('F21: البحث في العنوان والمحتوى', () async {
    await db.add(row('سرّ الضغط العالي', 'Football'));
    await db.add(row('AI يصلّح bug', 'Dev AI', content: '{"voice":"الكود فيه غلطة"}'));
    await db.add(row('تكتيك 4-3-3', 'Football'));

    expect((await db.search(query: 'ضغط')).length, 1);
    expect((await db.search(query: 'bug')).length, 1); // في العنوان
    expect((await db.search(query: 'غلطة')).length, 1); // في المحتوى
    expect((await db.search(query: 'تكتيك')).first.title, 'تكتيك 4-3-3');
    expect((await db.search(query: 'ماكاش')).length, 0);
  });

  test('F21: البحث سريع لـ1000 سكريبت (<200ms)', () async {
    await db.batch((b) {
      for (var i = 0; i < 1000; i++) {
        b.insert(db.scripts, row('سكريبت رقم $i عن البرمجة', i.isEven ? 'Dev AI' : 'Football', created: i));
      }
    });
    final sw = Stopwatch()..start();
    final r = await db.search(query: 'البرمجة');
    sw.stop();
    expect(r.length, 1000);
    expect(sw.elapsedMilliseconds, lessThan(200), reason: 'استغرق ${sw.elapsedMilliseconds}ms');
  });

  test('F23: فلترة حسب النوع', () async {
    await db.add(row('a', 'Dev AI'));
    await db.add(row('b', 'Football'));
    await db.add(row('c', 'Dev AI'));
    expect((await db.search(category: 'Dev AI')).length, 2);
    expect((await db.search(category: 'Football')).length, 1);
    // بحث + فلترة مع بعضهم
    expect((await db.search(query: 'a', category: 'Football')).length, 0);
  });

  test('F22: المفضّلة', () async {
    final id1 = await db.add(row('a', 'Dev AI'));
    await db.add(row('b', 'Dev AI'));
    expect((await db.search(favoritesOnly: true)).length, 0);
    await db.setFavorite(id1, true);
    final favs = await db.search(favoritesOnly: true);
    expect(favs.length, 1);
    expect(favs.first.id, id1);
    await db.setFavorite(id1, false);
    expect((await db.search(favoritesOnly: true)).length, 0);
  });

  test('F24: تعليم كتنشر + تاريخ', () async {
    final id = await db.add(row('a', 'Dev AI'));
    expect((await db.byId(id))!.publishedAt, isNull);
    await db.setPublished(id, 1760000000000);
    expect((await db.byId(id))!.publishedAt, 1760000000000);
    await db.setPublished(id, null);
    expect((await db.byId(id))!.publishedAt, isNull);
  });

  test('V2: الإحصائيات + أحسن نوع (bestCategory)', () async {
    final a = await db.add(row('a', 'Dev AI'));
    final b = await db.add(row('b', 'Football'));
    final c = await db.add(row('c', 'Football'));
    expect(await db.bestCategory(), isNull); // ما فماش إحصائيات بعد

    await db.setStats(a, 100, 10, 5);
    await db.setStats(b, 1000, 50, 20);
    await db.setStats(c, 2000, 80, 30);

    final best = await db.bestCategory();
    expect(best!.category, 'Football'); // متوسّط 1500 > 100
    expect(best.avgViews, 1500);
    expect(best.count, 2);

    expect((await db.byId(a))!.views, 100);
    expect((await db.byId(c))!.likes, 80);

    // مسح الإحصائيات
    await db.setStats(a, null, null, null);
    expect((await db.byId(a))!.views, isNull);
  });

  test('V2: السلاسل (épisodes)', () async {
    await db.add(row('عادي', 'Dev AI')); // بلا سلسلة
    expect(await db.seriesTitles(), isEmpty);
    expect(await db.nextEpisode('رحلتي'), 1); // سلسلة جديدة → الحلقة 1

    await db.add(row('ح1', 'Dev AI', series: 'رحلتي', ep: 1));
    await db.add(row('ح2', 'Dev AI', series: 'رحلتي', ep: 2));
    await db.add(row('أخرى', 'Football', series: 'كورة', ep: 1));

    expect((await db.seriesTitles())..sort(), ['رحلتي', 'كورة']);
    expect(await db.nextEpisode('رحلتي'), 3); // 2 حلقات → الجاية 3
    expect(await db.nextEpisode('كورة'), 2);

    final eps = await db.seriesEpisodes('رحلتي');
    expect(eps.map((e) => e.episode), [1, 2]); // مرتّبين
    expect(eps.first.title, 'ح1');
  });

  test('تعديل المحتوى + فسخ + byCreatedAt', () async {
    final id = await db.add(row('قديم', 'Dev AI', created: 555));
    await db.updateContent(id, 'جديد', '{"voice":"محتوى جديد"}');
    expect((await db.byId(id))!.title, 'جديد');
    expect((await db.byCreatedAt(555))!.title, 'جديد');
    await db.remove(id);
    expect(await db.byId(id), isNull);
    expect(await db.total(), 0);
  });
}
