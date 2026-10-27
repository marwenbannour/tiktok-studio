// تجربة شاملة end-to-end للـLot 2: مشروع من الصفر عبر ProjectRepo الحقيقي
// (استيراد + نصوص/كاريوكي + voix off + موسيقى + فلتر + سرعة + fade + blur)
// ثمّ export حقيقي، ونفحصو الناتج فعليًا (أبعاد + track فيديو + track صوت).
//
//   flutter test integration_test/e2e_editor_test.dart -d emulator-5554

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiktok_studio/db/database.dart';
import 'package:tiktok_studio/editor/project_repo.dart';
import 'package:tiktok_studio/models.dart';
import 'package:tiktok_studio/video_engine.dart';

Future<String> writeToneWav(String path, int ms, double freq) async {
  const sr = 22050;
  final n = (sr * ms / 1000).round();
  final dataLen = n * 2;
  final b = BytesBuilder();
  void str(String s) => b.add(s.codeUnits);
  void u32(int v) => b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) => b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  str('RIFF'); u32(36 + dataLen); str('WAVE');
  str('fmt '); u32(16); u16(1); u16(1); u32(sr); u32(sr * 2); u16(2); u16(16);
  str('data'); u32(dataLen);
  final samples = ByteData(dataLen);
  for (var i = 0; i < n; i++) {
    samples.setInt16(i * 2, (sin(2 * pi * freq * i / sr) * 10000).round(), Endian.little);
  }
  b.add(samples.buffer.asUint8List());
  await File(path).writeAsBytes(b.toBytes());
  return path;
}

VideoScript _script() => VideoScript.fromJson({
      'title': 'تجربة شاملة',
      'category': 'Dev AI',
      'style': 'x',
      'duration': 10,
      'segments': [
        {'from': 0, 'to': 5, 'screen': 'الكود', 'text': 'شدّ بالك', 'voice': 'كتبت function بسيطة'},
        {'from': 5, 'to': 10, 'screen': 'AI', 'text': 'صلّحناه', 'voice': 'في ثانية لقا الغلطة'},
      ],
      'caption': 'c',
      'hashtags': ['#a'],
      'createdAt': 1000,
    });

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppDatabase.instance = AppDatabase.forTesting(NativeDatabase.memory()));

  testWidgets('E2E: مشروع كامل عبر ProjectRepo → export → فحص الناتج', (tester) async {
    final dir = await getTemporaryDirectory();
    // فيديو مصدر (sample.mp4) + مدّتو
    final sample = File('${dir.path}/e2e_sample.mp4');
    await sample.writeAsBytes(
        (await rootBundle.load('assets/sample.mp4')).buffer.asUint8List());
    // sample.mp4 صغيرة؛ نقصّو 500ms لكل clip (قيمة آمنة مجرّبة فـvideo_engine_test).
    // (ملاحظة: MediaMetadataRetriever يرجّع 0 لمدّة هالـfixture رغم إنّها صالحة
    //  للـTransformer — علاش ما نعتمدوش probeDuration هوني.)
    const clipMs = 500;

    // 1) مشروع من سكريبت (ينشئ subtitle + text clips أوتوماتيك)
    final pid = await ProjectRepo.createFromScript(_script());

    // 2) زوز clips فيديو
    await ProjectRepo.addVideoClip(projectId: pid, sourcePath: sample.path, durationMs: clipMs);
    await ProjectRepo.addVideoClip(projectId: pid, sourcePath: sample.path, durationMs: clipMs);
    final vids = (await ProjectRepo.clips(pid))
        .where((c) => c.track == 'video')
        .toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    // 3) تحرير كامل عبر الـrepo الحقيقي
    await ProjectRepo.setFilter(projectId: pid, clipId: vids[0].id, filter: 'cinematic');
    await ProjectRepo.setFade(projectId: pid, clipId: vids[0].id, fade: true);
    await ProjectRepo.setSpeed(projectId: pid, clipId: vids[1].id, speed: 2.0);
    await ProjectRepo.setBlur(projectId: pid, clipId: vids[1].id, blur: 12.0);
    await ProjectRepo.setFade(projectId: pid, clipId: vids[1].id, fade: true);

    // 4) كاريوكي على ترجمة
    final sub = (await ProjectRepo.clips(pid)).firstWhere((c) => c.track == 'subtitle');
    final st = ProjectRepo.styleOf(sub);
    await ProjectRepo.updateStyle(projectId: pid, clipId: sub.id, style: {
      'text': st['text'],
      'karaoke': true,
    });

    // 5) voix off + موسيقى
    final voice = await writeToneWav('${dir.path}/e2e_voice.wav', 1500, 330);
    final music = await writeToneWav('${dir.path}/e2e_music.wav', 3000, 220);
    await ProjectRepo.addVoiceClip(projectId: pid, sourcePath: voice, durationMs: 1500);
    await ProjectRepo.setMusic(projectId: pid, sourcePath: music, durationMs: 3000, volume: 0.3);

    // 6) export عبر الـplan الحقيقي
    final plan = await ProjectRepo.buildExportPlan(pid);
    expect(plan.clips.length, 2);
    expect(plan.overlays.isNotEmpty, isTrue);
    expect(plan.audio.length, 2); // voice + music
    final out = '${dir.path}/e2e_out_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final r = await VideoEngine.exportComposition(
      clips: plan.clips, overlays: plan.overlays, audio: plan.audio,
      output: out, width: 1080, height: 1920,
    );
    debugPrint('E2E_EXPORT ms=${r.ms} output=${r.output}');

    // 7) فحص الناتج فعليًا
    final f = File(out);
    expect(await f.exists(), isTrue);
    expect(await f.length(), greaterThan(5000));
    final info = await VideoEngine.probeInfo(out);
    debugPrint('E2E_INFO $info');
    expect(info['hasVideo'], isTrue, reason: 'لازم track فيديو');
    expect(info['hasAudio'], isTrue, reason: 'لازم track صوت (voix off + موسيقى)');
    expect((info['durationMs'] as num) > 0, isTrue);
    // الأبعاد الظاهرة (باعتبار الدوران) لازم تكون عمودية 1080×1920
    final w = info['width'] as int;
    final h = info['height'] as int;
    final rot = (info['rotation'] as int?) ?? 0;
    final dispW = (rot == 90 || rot == 270) ? h : w;
    final dispH = (rot == 90 || rot == 270) ? w : h;
    expect(dispW, 1080, reason: 'العرض الظاهر (دوران=$rot، خام=${w}x$h)');
    expect(dispH, 1920, reason: 'الطول الظاهر (دوران=$rot، خام=${w}x$h)');

    // 8) undo: snapshot يرجّع الحالة
    final snap = await ProjectRepo.clips(pid);
    await ProjectRepo.addVideoClip(projectId: pid, sourcePath: sample.path, durationMs: clipMs);
    expect((await ProjectRepo.clips(pid)).length, snap.length + 1);
    await ProjectRepo.restoreClips(pid, snap);
    expect((await ProjectRepo.clips(pid)).length, snap.length);
  });
}
