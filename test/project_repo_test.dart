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

  test('addVideoClip: يلصق rushes واحد ورا لآخر ويحدّث المدّة', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    // مشروع سكريبت = 20000ms. نزيدو rush 3s ثمّ 4s.
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 3000, db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/b.mp4', durationMs: 4000, db: db);

    final vids = (await ProjectRepo.clips(pid, db: db))
        .where((c) => c.track == 'video')
        .toList()
      ..sort((x, y) => x.startMs.compareTo(y.startMs));
    expect(vids.length, 2);
    expect(vids[0].startMs, 0);
    expect(vids[0].outMs, 3000);
    expect(vids[1].startMs, 3000); // ملصوق ورا الأوّل
    expect(vids[1].outMs, 4000);
    expect(vids[1].sourcePath, '/b.mp4');

    // المدّة تبقى 20000 (أكبر من 3000+4000)
    final p = await ProjectRepo.byId(pid, db: db);
    expect(p!.durationMs, 20000);
  });

  test('deleteClip: يفسخ clip فيديو ويعاود يلصق الباقي', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 3000, db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/b.mp4', durationMs: 4000, db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/c.mp4', durationMs: 5000, db: db);

    // نفسخو الوسط (/b.mp4 اللي يبدا فـ3000)
    final mid = (await ProjectRepo.clips(pid, db: db))
        .firstWhere((c) => c.sourcePath == '/b.mp4');
    await ProjectRepo.deleteClip(projectId: pid, clipId: mid.id, db: db);

    final vids = (await ProjectRepo.clips(pid, db: db))
        .where((c) => c.track == 'video')
        .toList()
      ..sort((x, y) => x.startMs.compareTo(y.startMs));
    expect(vids.map((v) => v.sourcePath), ['/a.mp4', '/c.mp4']);
    expect(vids[0].startMs, 0); // a: 0..3000
    expect(vids[1].startMs, 3000); // c ملصوق ورا a (بلا فراغ)
  });

  test('trimVideoClip: يقصّ المدّة ويعاود يلصق اللي وراه', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 6000, db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/b.mp4', durationMs: 4000, db: db);

    final a = (await ProjectRepo.clips(pid, db: db))
        .firstWhere((c) => c.sourcePath == '/a.mp4');
    await ProjectRepo.trimVideoClip(
        projectId: pid, clipId: a.id, durationMs: 2000, db: db);

    final vids = (await ProjectRepo.clips(pid, db: db))
        .where((c) => c.track == 'video')
        .toList()
      ..sort((x, y) => x.startMs.compareTo(y.startMs));
    expect(ProjectRepo.clipDuration(vids[0]), 2000);
    expect(vids[1].startMs, 2000); // b انزاح ورا a المقصوص
  });

  test('splitVideoClip: يقسم لجوجة ويحافظ على نافذة المصدر', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 6000, db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/b.mp4', durationMs: 4000, db: db);

    final a = (await ProjectRepo.clips(pid, db: db))
        .firstWhere((c) => c.sourcePath == '/a.mp4');
    await ProjectRepo.splitVideoClip(
        projectId: pid, clipId: a.id, atMs: 2000, db: db);

    final vids = (await ProjectRepo.clips(pid, db: db))
        .where((c) => c.track == 'video')
        .toList()
      ..sort((x, y) => x.startMs.compareTo(y.startMs));
    expect(vids.length, 3); // a → a1 + a2، ثمّ b
    // a1: المصدر [0..2000]
    expect(vids[0].inMs, 0);
    expect(vids[0].outMs, 2000);
    expect(vids[0].startMs, 0);
    // a2: المصدر [2000..6000] = باقي /a.mp4
    expect(vids[1].sourcePath, '/a.mp4');
    expect(vids[1].inMs, 2000);
    expect(vids[1].outMs, 6000);
    expect(vids[1].startMs, 2000);
    // b انزاح ورا (2000+4000=6000)
    expect(vids[2].sourcePath, '/b.mp4');
    expect(vids[2].startMs, 6000);
  });

  test('reorderVideoClips: السحب يبدّل الترتيب ويعاود يلصق', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 3000, db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/b.mp4', durationMs: 4000, db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/c.mp4', durationMs: 5000, db: db);

    final byPath = {
      for (final c in await ProjectRepo.clips(pid, db: db))
        if (c.track == 'video') c.sourcePath: c.id
    };
    // نرتّبهم عكسي: c, b, a
    await ProjectRepo.reorderVideoClips(
        projectId: pid,
        orderedIds: [byPath['/c.mp4']!, byPath['/b.mp4']!, byPath['/a.mp4']!],
        db: db);

    final vids = (await ProjectRepo.clips(pid, db: db))
        .where((c) => c.track == 'video')
        .toList()
      ..sort((x, y) => x.startMs.compareTo(y.startMs));
    expect(vids.map((v) => v.sourcePath), ['/c.mp4', '/b.mp4', '/a.mp4']);
    expect(vids[0].startMs, 0); // c: 0..5000
    expect(vids[1].startMs, 5000); // b: 5000..9000
    expect(vids[2].startMs, 9000); // a: 9000..12000
  });

  test('buildExportPlan: clips مرتّبين + overlays موقّتين (نصّ/ترجمة)', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    // سكريبت = 2 segments → 2 subtitle + 1 text. نزيدو فيديو.
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 8000, db: db);

    final plan = await ProjectRepo.buildExportPlan(pid, db: db);

    // clip فيديو واحد
    expect(plan.clips.length, 1);
    expect(plan.clips.first['path'], '/a.mp4');
    expect(plan.clips.first['inMs'], 0);
    expect(plan.clips.first['outMs'], 8000);
    expect(plan.clips.first['startMs'], 0);

    // overlays: 2 subtitle + 1 text = 3، كلّهم بتوقيت
    expect(plan.overlays.length, 3);
    final sub1 = plan.overlays.firstWhere(
        (o) => o['kind'] == 'subtitle' && o['startMs'] == 0);
    expect(sub1['text'], 'كتبت function');
    expect(sub1['endMs'], 5000); // 0..5000
    final text1 = plan.overlays.firstWhere((o) => o['kind'] == 'text');
    expect(text1['text'], 'شدّ بالك');
    expect(text1['startMs'], 0);
    expect(text1['endMs'], 5000);
  });

  test('buildExportPlan: بلا فيديو → clips فارغة', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    final plan = await ProjectRepo.buildExportPlan(pid, db: db);
    expect(plan.clips, isEmpty); // ماكانش rushes → UI يمنع الـexport
    expect(plan.overlays.isNotEmpty, isTrue);
  });

  test('styleOf: قيم افتراضية حسب النوع (نصّ أصفر كبير / ترجمة بيضاء)', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    final clips = await ProjectRepo.clips(pid, db: db);
    final text = clips.firstWhere((c) => c.track == 'text');
    final sub = clips.firstWhere((c) => c.track == 'subtitle');

    final ts = ProjectRepo.styleOf(text);
    expect(ts['color'], '#FFEB3B'); // أصفر
    expect(ts['size'], 64);
    expect(ts['bold'], true);
    expect(ts['align'], 'center');

    final ss = ProjectRepo.styleOf(sub);
    expect(ss['color'], '#FFFFFF'); // أبيض
    expect(ss['size'], 48);
  });

  test('updateStyle → styleOf + buildExportPlan يعكسو التنسيق الجديد', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 8000, db: db);
    final sub = (await ProjectRepo.clips(pid, db: db))
        .firstWhere((c) => c.track == 'subtitle' && c.startMs == 0);

    await ProjectRepo.updateStyle(sub.id, {
      'text': 'ترجمة محرّرة',
      'color': '#00E5FF',
      'size': 72,
      'bold': false,
      'align': 'right',
    }, db: db);

    final reloaded = (await ProjectRepo.clips(pid, db: db)).firstWhere((c) => c.id == sub.id);
    final st = ProjectRepo.styleOf(reloaded);
    expect(st['text'], 'ترجمة محرّرة');
    expect(st['color'], '#00E5FF');
    expect(st['size'], 72);
    expect(st['bold'], false);
    expect(st['align'], 'right');

    // يبان فالـexport plan
    final plan = await ProjectRepo.buildExportPlan(pid, db: db);
    final ov = plan.overlays.firstWhere((o) => o['text'] == 'ترجمة محرّرة');
    expect(ov['color'], '#00E5FF');
    expect(ov['size'], 72);
    expect(ov['align'], 'right');
  });

  test('addVoiceClip: voix off تتسلسل + volume=1.0 افتراضي', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVoiceClip(
        projectId: pid, sourcePath: '/v1.m4a', durationMs: 3000, db: db);
    await ProjectRepo.addVoiceClip(
        projectId: pid, sourcePath: '/v2.m4a', durationMs: 2000, db: db);

    final voices = (await ProjectRepo.clips(pid, db: db))
        .where((c) => c.track == 'voice')
        .toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));
    expect(voices.length, 2);
    expect(voices[0].startMs, 0);
    expect(voices[1].startMs, 3000); // ملحوقة ورا الأولى
    expect(ProjectRepo.volumeOf(voices[0]), 1.0);
  });

  test('setMusic: موسيقى وحدة من 0 + volume افتراضي 0.35', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.setMusic(
        projectId: pid, sourcePath: '/m1.mp3', durationMs: 20000, db: db);
    await ProjectRepo.setMusic(
        projectId: pid, sourcePath: '/m2.mp3', durationMs: 15000, db: db); // تبدّل الأولى

    final music = (await ProjectRepo.clips(pid, db: db))
        .where((c) => c.track == 'music')
        .toList();
    expect(music.length, 1); // وحدة برك
    expect(music.first.sourcePath, '/m2.mp3');
    expect(music.first.startMs, 0);
    expect(ProjectRepo.volumeOf(music.first), ProjectRepo.defaultMusicVolume);
  });

  test('setSpeed: المدّة على الـtimeline = المصدر ÷ السرعة + يعاود يلصق', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 4000, db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/b.mp4', durationMs: 4000, db: db);

    final a = (await ProjectRepo.clips(pid, db: db))
        .firstWhere((c) => c.sourcePath == '/a.mp4');
    await ProjectRepo.setSpeed(projectId: pid, clipId: a.id, speed: 2.0, db: db);

    final vids = (await ProjectRepo.clips(pid, db: db))
        .where((c) => c.track == 'video')
        .toList()
      ..sort((x, y) => x.startMs.compareTo(y.startMs));
    // a: مصدر 4000 بسرعة 2x → 2000 على الـtimeline؛ نافذة المصدر ما تتبدّلش
    expect(vids[0].speed, 2.0);
    expect(ProjectRepo.clipDuration(vids[0]), 4000); // نافذة المصدر
    expect(ProjectRepo.timelineDuration(vids[0]), 2000); // على الـtimeline
    expect(vids[1].startMs, 2000); // b انزاح لـ2000 (مش 4000)
  });

  test('setSpeed: buildExportPlan يمرّر speed + timelineMs', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 6000, db: db);
    final a = (await ProjectRepo.clips(pid, db: db))
        .firstWhere((c) => c.sourcePath == '/a.mp4');
    await ProjectRepo.setSpeed(projectId: pid, clipId: a.id, speed: 0.5, db: db);

    final plan = await ProjectRepo.buildExportPlan(pid, db: db);
    final cm = plan.clips.first;
    expect(cm['speed'], 0.5);
    expect(cm['outMs'], 6000); // المصدر
    expect(cm['timelineMs'], 12000); // 6000 / 0.5
  });

  test('buildExportPlan: يمرّر audio (voice كامل + music منخفّض)', () async {
    final pid = await ProjectRepo.createFromScript(script(), db: db);
    await ProjectRepo.addVideoClip(
        projectId: pid, sourcePath: '/a.mp4', durationMs: 8000, db: db);
    await ProjectRepo.addVoiceClip(
        projectId: pid, sourcePath: '/v.m4a', durationMs: 4000, db: db);
    await ProjectRepo.setMusic(
        projectId: pid, sourcePath: '/m.mp3', durationMs: 8000, volume: 0.2, db: db);

    final plan = await ProjectRepo.buildExportPlan(pid, db: db);
    expect(plan.audio.length, 2);
    final v = plan.audio.firstWhere((a) => a['kind'] == 'voice');
    expect(v['path'], '/v.m4a');
    expect(v['volume'], 1.0);
    final m = plan.audio.firstWhere((a) => a['kind'] == 'music');
    expect(m['volume'], 0.2);
  });
}
