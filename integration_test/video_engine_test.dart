// prototype Lot 2: يتأكّد إنّ محرّك الفيديو (Media3 Transformer) يعمل export
// حقيقي ينتج MP4 صالح مع نصّ محروق. (المدّة على الإيميلاتور موش ممثّلة —
// الإيميلاتور software encode؛ قياس السرعة الحقيقي يلزم جهاز حقيقي.)
//
//   flutter test integration_test/video_engine_test.dart -d emulator-5554

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiktok_studio/video_engine.dart';

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
    final output = '${dir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final r = await VideoEngine.exportComposition(
      clips: [
        {'path': src.path, 'inMs': 0, 'outMs': half, 'startMs': 0},
        {'path': src.path, 'inMs': 0, 'outMs': half, 'startMs': half},
      ],
      overlays: [
        // ترجمة تغطّي الـclip الأوّل، نصّ يعبر الحدّ بين الزوز clips
        {'text': 'ترجمة ١', 'startMs': 0, 'endMs': half, 'kind': 'subtitle'},
        {'text': 'نصّ يعبر', 'startMs': 200, 'endMs': half + 200, 'kind': 'text'},
      ],
      output: output,
      width: 1080,
      height: 1920,
    );

    debugPrint('COMPOSITION_RESULT ms=${r.ms} output=${r.output}');
    final out = File(output);
    expect(await out.exists(), isTrue, reason: 'ملف الـcomposition ما اتعملش');
    expect(await out.length(), greaterThan(1000));
    final head = await out.openRead(0, 12).first;
    expect(String.fromCharCodes(head.sublist(4, 8)), 'ftyp');
    expect(r.ms, greaterThan(0));
  });
}
