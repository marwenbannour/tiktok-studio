import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_studio/capcut_export.dart';
import 'package:tiktok_studio/models.dart';

VideoScript _script(List<Map<String, Object>> segments) => VideoScript.fromJson({
      'title': 'AI لقى الـbug',
      'category': 'Dev AI',
      'style': 'الشاشة فقط',
      'duration': 20,
      'segments': segments,
      'code': 'print(1)',
      'caption': 'جرّبتوه؟',
      'hashtags': ['#dev', '#تونس'],
      'createdAt': 1000,
    });

void main() {
  final v = _script([
    {'from': 0, 'to': 3, 'screen': 'الكود', 'text': 'شدّ بالك 🐛', 'voice': 'كتبت function'},
    {
      'from': 3,
      'to': 20,
      'screen': 'AI',
      'text': '',
      'voice': 'الـAI لقى الغلطة في ثانيتين، وبعد صلّحناه مع بعضنا خطوة بخطوة. '
          'جرّبو إنتوما وقولولي في الكومنتارات شنوّة صارلكم!',
    },
  ]);

  group('timestamp', () {
    test('بدقّة الـms', () {
      expect(CapCutExport.timestamp(0), '00:00:00,000');
      expect(CapCutExport.timestamp(1250), '00:00:01,250');
      expect(CapCutExport.timestamp(3723004), '01:02:03,004');
      expect(CapCutExport.timestamp(-5), '00:00:00,000');
    });
  });

  group('splitCaption', () {
    test('كل سطر ≤ maxChars وما تضيع حتى كلمة', () {
      const t = 'هذي جملة طويلة برشا فيها كلام ياسر باش نثبّتو إنّو القصّ يخدم '
          'على الكلمات وما يقصّش كلمة في النصّ أبداً مهما كان';
      final parts = CapCutExport.splitCaption(t);
      expect(parts.length, greaterThan(1));
      for (final p in parts) {
        expect(p.length, lessThanOrEqualTo(CapCutExport.maxChars));
      }
      expect(parts.join(' '), t);
    });

    test('يقصّ على الجمل والفواصل العربية', () {
      final parts = CapCutExport.splitCaption('أوّل جملة كاملة هنا، وثاني جملة كاملة غادي؟ وثالثة.');
      expect(parts.first, endsWith('،'));
    });

    test('نصّ فارغ → ما فمّا شي', () {
      expect(CapCutExport.splitCaption('   '), isEmpty);
    });
  });

  group('subtitleCues', () {
    test('تتبع الصوت موش النصّ على الشاشة', () {
      final cues = CapCutExport.subtitleCues(v);
      expect(cues.first.text, 'كتبت function');
      expect(cues.any((c) => c.text.contains('شدّ بالك')), isFalse);
    });

    test('مرتّبة، بلا تداخل، وتغطّي كل segment لآخرو', () {
      final cues = CapCutExport.subtitleCues(v);
      expect(cues.first.startMs, 0);
      expect(cues.last.endMs, 20000);
      for (var i = 1; i < cues.length; i++) {
        expect(cues[i].startMs, greaterThanOrEqualTo(cues[i - 1].endMs));
        expect(cues[i].durationMs, greaterThan(0));
      }
    });

    test('segments متداخلين ولا مقلوبين ما يعطيوش cues متداخلين', () {
      final bad = _script([
        {'from': 0, 'to': 5, 'screen': '', 'text': '', 'voice': 'أوّل'},
        {'from': 3, 'to': 8, 'screen': '', 'text': '', 'voice': 'ثاني'},
        {'from': 9, 'to': 7, 'screen': '', 'text': '', 'voice': 'مقلوب'},
      ]);
      final cues = CapCutExport.subtitleCues(bad);
      expect(cues.map((c) => c.text), ['أوّل', 'ثاني']);
      expect(cues[1].startMs, 5000);
    });
  });

  test('titleCues: النصوص على الشاشة برك', () {
    final t = CapCutExport.titleCues(v);
    expect(t.length, 1);
    expect(t.first.text, 'شدّ بالك 🐛');
    expect(t.first.endMs, 3000);
  });

  group('toSrt', () {
    test('BOM + CRLF + RLM للعربي + ترقيم', () {
      final s = CapCutExport.srt(v);
      expect(s.startsWith('\uFEFF1\r\n00:00:00,000 --> '), isTrue);
      expect(s, contains('\r\n\u200Fكتبت function\r\n'));
      expect(s.contains(RegExp(r'[^\r]\n')), isFalse); // كل الأسطر CRLF
      expect(s.endsWith('\r\n\r\n'), isFalse);
    });

    test('سطر لاتيني برك ما ياخوش RLM', () {
      final s = CapCutExport.toSrt(const [SrtCue(0, 1000, 'Hello')]);
      expect(s, contains('\r\nHello\r\n'));
    });
  });

  test('plan: المشاهد بالتوقيت، الكود، الوصف، والخطوات في CapCut', () {
    final p = CapCutExport.plan(v);
    expect(p, contains('🎬 خطة المونتاج — AI لقى الـbug'));
    expect(p, contains('[0:00 → 0:03]'));
    expect(p, contains('📝 نصّ على الشاشة: شدّ بالك 🐛'));
    expect(p, contains('🎙️ الصوت: كتبت function'));
    expect(p, contains('print(1)'));
    expect(p, contains('✍️ الوصف: جرّبتوه؟'));
    expect(p, contains('#dev #تونس'));
    expect(p, contains('captions.srt'));
  });
}
