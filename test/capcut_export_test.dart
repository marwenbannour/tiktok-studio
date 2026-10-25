import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_studio/capcut_export.dart';
import 'package:tiktok_studio/models.dart';

void main() {
  final v = VideoScript.fromJson({
    'title': 'AI لقى الـbug',
    'category': 'Dev AI',
    'style': 'الشاشة فقط',
    'duration': 20,
    'segments': [
      {'from': 0, 'to': 3, 'screen': 'الكود', 'text': 'شدّ بالك 🐛', 'voice': 'كتبت function'},
      {'from': 3, 'to': 20, 'screen': 'AI', 'text': '', 'voice': 'صلّحناه مع بعضنا'},
    ],
    'code': 'print(1)',
    'caption': 'جرّبتوه؟',
    'hashtags': ['#dev', '#تونس'],
    'createdAt': 1000,
  });

  test('srt: توقيتات صحيحة ونصّ كل segment (ولا الصوت كان النصّ فارغ)', () {
    final s = CapCutExport.srt(v);
    expect(s, contains('00:00:00,000 --> 00:00:03,000'));
    expect(s, contains('شدّ بالك 🐛'));
    expect(s, contains('00:00:03,000 --> 00:00:20,000'));
    expect(s, contains('صلّحناه مع بعضنا')); // النصّ فارغ → ياخذ الصوت
    expect(s.trimRight().endsWith('\n'), isFalse);
  });

  test('plan: فيها المشاهد والكود والوصف والهاشتاغات وخطوات CapCut', () {
    final p = CapCutExport.plan(v);
    expect(p, contains('🎬 خطة المونتاج — AI لقى الـbug'));
    expect(p, contains('[00–03s]'));
    expect(p, contains('📝 نصّ على الفيديو: شدّ بالك 🐛'));
    expect(p, contains('🎙️ الصوت: كتبت function'));
    expect(p, contains('print(1)'));
    expect(p, contains('✍️ الوصف: جرّبتوه؟'));
    expect(p, contains('#dev #تونس'));
    expect(p, contains('CapCut'));
  });
}
