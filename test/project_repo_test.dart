import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_studio/db/database.dart';
import 'package:tiktok_studio/editor/project_repo.dart';
import 'package:tiktok_studio/models.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  VideoScript script() => VideoScript.fromJson({
        'title': 'مشروع تجربة',
        'category': 'Dev AI',
        'style': 'x',
        'duration': 20,
        'segments': [
          {'from': 0, 'to': 5, 'screen': 'الكود', 'text': 'شدّ بالك', 'voice': 'كتبت function'},
          {'from': 5, 'to': 20, 'screen': 'AI', 'text': '', 'voice': 'صلّحناه'},
        ],
        'caption': 'c',
        'hashtags': ['#a'],
        'createdAt': 1000,
      });

  test('createFromScript: projet 9:16 + assemblage auto حسب segments', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    final p = await ProjectRepo.byId(pid, db: db);
    expect(p!.title, 'مشروع تجربة');
    expect(p.durationMs, 20000);
    expect(p.width, 1080);
    expect(p.height, 1920);
    expect(p.fps, 30);

    final clips = await ProjectRepo.clips(pid, db: db);
    // segment1: subtitle + text ؛ segment2: subtitle فقط (text فارغ) = 3
    expect(clips.length, 3);
    final subs = clips.where((c) => c.track == 'subtitle').toList();
    final texts = clips.where((c) => c.track == 'text').toList();
    expect(subs.length, 2);
    expect(texts.length, 1);

    final sub1 = subs.firstWhere((c) => c.startMs == 0);
    expect(sub1.outMs, 5000);
    expect(jsonDecode(sub1.props)['text'], 'كتبت function');
    final sub2 = subs.firstWhere((c) => c.startMs == 5000);
    expect(sub2.outMs, 15000);
    expect(texts.first.startMs, 0);
    expect(jsonDecode(texts.first.props)['text'], 'شدّ بالك');
  });

  test('remove: يمسح المشروع والـclips', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    expect((await ProjectRepo.clips(pid, db: db)).isNotEmpty, isTrue);
    await ProjectRepo.remove(pid, db: db);
    expect(await ProjectRepo.byId(pid, db: db), isNull);
    expect(await ProjectRepo.clips(pid, db: db), isEmpty);
  });

  test('autoAssemble: يعاود يبني الـclips (idempotent)', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.autoAssemble(pid, script(), db: db); // مرّة ثانية
    expect((await ProjectRepo.clips(pid, db: db)).length, 3); // ما يتضاعفوش
  });
}
