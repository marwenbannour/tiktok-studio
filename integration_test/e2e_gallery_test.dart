// تجربة شاملة «تتفرّج عليها»: تبني مشروع كامل عبر ProjectRepo الحقيقي،
// تصدّر، وتحطّ الناتج فالـgalerie (ألبوم «TikTok Studio») باش تفتحو وتشوفو.
//
//   flutter test integration_test/e2e_gallery_test.dart -d 127.0.0.1:5555

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
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
  final s = ByteData(dataLen);
  for (var i = 0; i < n; i++) {
    s.setInt16(i * 2, (sin(2 * pi * freq * i / sr) * 10000).round(), Endian.little);
  }
  b.add(s.buffer.asUint8List());
  await File(path).writeAsBytes(b.toBytes());
  return path;
}

VideoScript _script() => VideoScript.fromJson({
      'title': 'ستوديو التيكتوك — تجربة',
      'category': 'Dev AI',
      'style': 'x',
      'duration': 10,
      'segments': [
        {'from': 0, 'to': 5, 'screen': 'الكود', 'text': 'شدّ بالك 👀', 'voice': 'كتبت function بسيطة'},
        {'from': 5, 'to': 10, 'screen': 'AI', 'text': 'صلّحناه ✅', 'voice': 'في ثانية لقا الغلطة'},
      ],
      'caption': 'c', 'hashtags': ['#dev'], 'createdAt': 1000,
    });

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => AppDatabase.instance = AppDatabase.forTesting(NativeDatabase.memory()));

  testWidgets('E2E galerie: مشروع كامل → export → يتسجّل فالـgalerie', (tester) async {
    final dir = await getTemporaryDirectory();
    final sample = File('${dir.path}/g_sample.mp4');
    await sample.writeAsBytes((await rootBundle.load('assets/sample.mp4')).buffer.asUint8List());
    const clipMs = 600;

    // مشروع من سكريبت + زوز فيديوهات + تحرير كامل
    final pid = await ProjectRepo.createFromScript(_script());
    await ProjectRepo.addVideoClip(projectId: pid, sourcePath: sample.path, durationMs: clipMs);
    await ProjectRepo.addVideoClip(projectId: pid, sourcePath: sample.path, durationMs: clipMs);
    final vids = (await ProjectRepo.clips(pid)).where((c) => c.track == 'video').toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));
    await ProjectRepo.setFilter(projectId: pid, clipId: vids[0].id, filter: 'cinematic');
    await ProjectRepo.setFade(projectId: pid, clipId: vids[0].id, fade: true);
    await ProjectRepo.setSpeed(projectId: pid, clipId: vids[1].id, speed: 2.0);
    await ProjectRepo.setBlur(projectId: pid, clipId: vids[1].id, blur: 12.0);
    await ProjectRepo.setFade(projectId: pid, clipId: vids[1].id, fade: true);
    final sub = (await ProjectRepo.clips(pid)).firstWhere((c) => c.track == 'subtitle');
    await ProjectRepo.updateStyle(projectId: pid, clipId: sub.id, style: {
      'text': ProjectRepo.styleOf(sub)['text'], 'karaoke': true, 'color': '#00E5FF',
    });

    // voix off + موسيقى
    final voice = await writeToneWav('${dir.path}/g_voice.wav', 1800, 330);
    final music = await writeToneWav('${dir.path}/g_music.wav', 4000, 180);
    await ProjectRepo.addVoiceClip(projectId: pid, sourcePath: voice, durationMs: 1800);
    await ProjectRepo.setMusic(projectId: pid, sourcePath: music, durationMs: 4000, volume: 0.3);

    // export
    final plan = await ProjectRepo.buildExportPlan(pid);
    final out = '${dir.path}/g_out_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final r = await VideoEngine.exportComposition(
      clips: plan.clips, overlays: plan.overlays, audio: plan.audio,
      output: out, width: 1080, height: 1920,
    );
    debugPrint('GALLERY_EXPORT ms=${r.ms} output=${r.output}');
    final info = await VideoEngine.probeInfo(out);
    debugPrint('GALLERY_INFO $info');

    // نسخة فمجلّد خارجي قابل للجبد (adb pull) — بلا إذن، باش نتفرّجو عليها على الـPC
    final ext = await getExternalStorageDirectory();
    if (ext != null) {
      final shared = File('${ext.path}/studio_e2e.mp4');
      await File(out).copy(shared.path);
      debugPrint('GALLERY_SHARED ${shared.path}');
    }

    // الـgalerie (MediaStore → /sdcard، قابل للجبد عبر adb)
    try {
      await Gal.putVideo(out, album: 'TikTok Studio');
      debugPrint('GALLERY_SAVED → album «TikTok Studio»');
    } catch (e) {
      debugPrint('GALLERY_SAVE_ERR $e');
    }

    expect(await File(out).exists(), isTrue);
    expect(info['hasVideo'], isTrue);
    expect(info['hasAudio'], isTrue);
  });
}
