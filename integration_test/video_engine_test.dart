// prototype Lot 2: يتأكّد إنّ محرّك الفيديو (Media3 Transformer) يعمل export
// حقيقي ينتج MP4 صالح مع نصّ محروق. (المدّة على الإيميلاتور موش ممثّلة —
// الإيميلاتور software encode؛ قياس السرعة الحقيقي يلزم جهاز حقيقي.)
//
//   flutter test integration_test/video_engine_test.dart -d emulator-5554

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiktok_studio/video_engine.dart';

/// يكتب ملف WAV (نغمة sine) صالح باش يخدم كـfixture صوت (الـsample.mp4 بلا صوت).
Future<String> writeToneWav(String path, int ms) async {
  const sampleRate = 22050;
  const freq = 440.0;
  final n = (sampleRate * ms / 1000).round();
  final dataLen = n * 2; // 16-bit mono
  final b = BytesBuilder();
  void str(String s) => b.add(s.codeUnits);
  void u32(int v) => b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) => b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  str('RIFF'); u32(36 + dataLen); str('WAVE');
  str('fmt '); u32(16); u16(1); u16(1); u32(sampleRate);
  u32(sampleRate * 2); u16(2); u16(16);
  str('data'); u32(dataLen);
  final samples = ByteData(dataLen);
  for (var i = 0; i < n; i++) {
    final v = (sin(2 * pi * freq * i / sampleRate) * 12000).round();
    samples.setInt16(i * 2, v, Endian.little);
  }
  b.add(samples.buffer.asUint8List());
  final f = File(path);
  await f.writeAsBytes(b.toBytes());
  return f.path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Media3 export: MP4 صالح مع نصّ محروق', (tester) async {
    final dir = await getTemporaryDirectory();
    final input = File('${dir.path}/sample.mp4');
    final bytes = await rootBundle.load('assets/sample.mp4');
    await input.writeAsBytes(bytes.buffer.asUint8List());
    final output = '${dir.path}/out_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final r = await VideoEngine.export(
      input: input.path,
      output: output,
      text: 'ستوديو التيكتوك 🎬',
      width: 1080,
      height: 1920,
    );

    debugPrint('EXPORT_RESULT ms=${r.ms} output=${r.output}');

    final out = File(output);
    expect(await out.exists(), isTrue, reason: 'ملف الـexport ما اتعملش');
    expect(await out.length(), greaterThan(1000));

    // رأس MP4 صالح (ftyp)
    final head = await out.openRead(0, 12).first;
    expect(String.fromCharCodes(head.sublist(4, 8)), 'ftyp');
    expect(r.ms, greaterThan(0));
  });

  testWidgets('Media3 exportComposition: دمج clipين + نصوص موقّتة', (tester) async {
    final dir = await getTemporaryDirectory();
    final bytes = await rootBundle.load('assets/sample.mp4');
    final src = File('${dir.path}/sample_c.mp4');
    await src.writeAsBytes(bytes.buffer.asUint8List());

    // نكتشفو مدّة الـsample باش نبنيو clipين ضمنها
    // (sample قصير؛ ناخذو نصفين منّو)
    const half = 500; // ~0.5s لكل clip (آمن حتى لو sample قصير)
    final wav = await writeToneWav('${dir.path}/tone.wav', 2000); // 2s صوت fixture
    final output = '${dir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final r = await VideoEngine.exportComposition(
      clips: [
        // V14: سرعة 2x؛ V17: فلتر سينمائي؛ V16: dip-to-black
        {'path': src.path, 'inMs': 0, 'outMs': half, 'startMs': 0,
         'speed': 2.0, 'timelineMs': half ~/ 2, 'filter': 'cinematic', 'fade': true},
        // الثاني: أبيض وأسود + انتقالة + طمس (V18)
        {'path': src.path, 'inMs': 0, 'outMs': half, 'startMs': half ~/ 2,
         'speed': 1.0, 'timelineMs': half, 'filter': 'bw', 'fade': true, 'blur': 12.0},
      ],
      overlays: [
        // ترجمة كاريوكي (V10): الكلمات تتقسّم وتتميّز وحدة وحدة
        {'text': 'واحد زوز ثلاثة', 'startMs': 0, 'endMs': half, 'kind': 'subtitle',
         'color': '#FFFFFF', 'size': 52, 'bold': true, 'align': 'center',
         'bg': '#99000000', 'karaoke': true},
        // نصّ أصفر يعبر الحدّ بين الزوز clips
        {'text': 'نصّ يعبر', 'startMs': 200, 'endMs': half + 200, 'kind': 'text',
         'color': '#FFEB3B', 'size': 64, 'bold': true, 'align': 'right'},
      ],
      audio: [
        // voix off (نغمة WAV، كامل الحجم) من بداية
        {'path': wav, 'inMs': 0, 'outMs': half, 'startMs': 0,
         'kind': 'voice', 'volume': 1.0},
        // موسيقى خلفية بحجم منخفّض (تختبر ChannelMixingAudioProcessor)
        {'path': wav, 'inMs': 0, 'outMs': half * 2, 'startMs': 0,
         'kind': 'music', 'volume': 0.3},
      ],
      output: output,
      width: 1080,
      height: 1920,
    );

    debugPrint('COMPOSITION_RESULT ms=${r.ms} output=${r.output}');
    final out = File(output);
    expect(await out.exists(), isTrue, reason: 'ملف الـcomposition ما اتعملش');
    expect(await out.length(), greaterThan(1000));
    final outBytes = await out.readAsBytes();
    expect(String.fromCharCodes(outBytes.sublist(4, 8)), 'ftyp');
    // لازم يكون فمّا track صوت ممزوج (voix off + موسيقى) → atom 'mp4a'
    expect(_containsTag(outBytes, 'mp4a'), isTrue, reason: 'ماكانش track صوت فالمخرج');
    expect(r.ms, greaterThan(0));
  });
}

/// يلوّج على tag (4 bytes ASCII) داخل bytes الملف.
bool _containsTag(Uint8List bytes, String tag) {
  final t = tag.codeUnits;
  for (var i = 0; i + t.length <= bytes.length; i++) {
    var ok = true;
    for (var j = 0; j < t.length; j++) {
      if (bytes[i + j] != t[j]) { ok = false; break; }
    }
    if (ok) return true;
  }
  return false;
}
