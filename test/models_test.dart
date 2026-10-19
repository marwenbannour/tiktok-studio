import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_studio/exporter.dart';
import 'package:tiktok_studio/models.dart';
import 'package:tiktok_studio/prompts.dart';
import 'package:tiktok_studio/screens/plan_editor.dart';

VideoScript _script({String title = 'سرّ الضغط العالي'}) => VideoScript.fromJson({
      'title': title,
      'segments': [
        {'from': 0, 'to': 5, 'screen': 's0', 'text': 't0', 'voice': 'v0'},
        {'from': 5, 'to': 15, 'screen': 's1', 'text': 't1', 'voice': 'v1'},
      ],
      'caption': 'cap',
      'hashtags': ['#a', '#b'],
      'category': 'Football',
      'duration': 15,
      'createdAt': 1760700000000,
    });

void main() {
  group('VideoScript.withSegment', () {
    test('يبدّل segment واحد ويخلّي الباقي', () {
      final s = _script();
      final n = s.withSegment(1, s.segments[1].copyWith(voice: 'جديد'));
      expect(n.segments[1].voice, 'جديد');
      expect(n.segments[1].from, 5);
      expect(n.segments[1].to, 15);
      expect(n.segments[1].screen, 's1');
      expect(n.segments[0].voice, 'v0');
      expect(s.segments[1].voice, 'v1', reason: 'الأصلي ما يتبدّلش');
      expect(n.createdAt, s.createdAt);
      expect(n.toJson()['caption'], 'cap');
    });
  });

  group('Prompts.rewriteSegment', () {
    test('فيه السياق، الـsegment المطلوب والطلب', () {
      final p = Prompts.rewriteSegment(_script(), 1, 'أقصر');
      expect(p, contains('👉 [05–15s] v1'));
      expect(p, contains('[00–05s] v0'));
      expect(p, contains('الطلب: أقصر'));
      expect(p, contains('نفس المدّة (10 ثواني)'));
      expect(p, isNot(contains('هذا الـhook')));
    });

    test('الـsegment الأوّل = hook، وطلب فارغ يولّي افتراضي', () {
      final p = Prompts.rewriteSegment(_script(), 0, '');
      expect(p, contains('هذا الـhook'));
      expect(p, contains('الطلب: خلّيه أقوى وأوضح'));
    });
  });

  group('PlannedVideo', () {
    test('JSON يمشي ويرجع', () {
      final p = PlannedVideo(
        id: 1760700000123,
        title: 'x',
        date: DateTime(2026, 10, 20, 18, 30),
        status: PlanStatus.filmed,
        reminder: false,
        scriptId: 42,
      );
      final r = PlannedVideo.fromJson(p.toJson());
      expect(r.id, p.id);
      expect(r.title, 'x');
      expect(r.date, p.date);
      expect(r.status, PlanStatus.filmed);
      expect(r.reminder, isFalse);
      expect(r.scriptId, 42);
    });

    test('قيم ناقصة ولا غالطة ما تطيّحش', () {
      final r = PlannedVideo.fromJson({'id': 1, 'title': 't', 'date': 0, 'status': '???'});
      expect(r.status, PlanStatus.idea);
      expect(r.reminder, isTrue);
      expect(r.scriptId, isNull);
    });

    test('الحالة تدور: فكرة ← تصوّر ← تنشر ← فكرة', () {
      expect(PlanStatus.idea.next, PlanStatus.filmed);
      expect(PlanStatus.filmed.next, PlanStatus.posted);
      expect(PlanStatus.posted.next, PlanStatus.idea);
    });

    test('notificationId يدخل في int 32 bits', () {
      final p = PlannedVideo(id: 1760700000123, title: 't', date: DateTime(2026));
      expect(p.notificationId, inInclusiveRange(0, 0x7fffffff));
      expect(p.notificationId, PlannedVideo(id: p.id, title: 'y', date: DateTime(2027)).notificationId);
    });
  });

  group('التواريخ', () {
    test('defaultPlanDate: غدوة على 18:00، حتى في آخر الشهر', () {
      expect(defaultPlanDate(DateTime(2026, 10, 17, 9)), DateTime(2026, 10, 18, 18));
      expect(defaultPlanDate(DateTime(2026, 10, 31, 23, 59)), DateTime(2026, 11, 1, 18));
      expect(defaultPlanDate(DateTime(2026, 12, 31)), DateTime(2027, 1, 1, 18));
    });

    test('formatDay / formatTime', () {
      // 19/10/2026 نهار إثنين
      expect(formatDay(DateTime(2026, 10, 19)), 'الإثنين 19/10');
      expect(formatDay(DateTime(2026, 10, 25)), 'الأحد 25/10');
      expect(formatTime(DateTime(2026, 1, 1, 7, 5)), '07:05');
    });
  });

  group('Exporter.fileName', () {
    test('حروف وأرقام برك، ويخلّي العربي', () {
      expect(Exporter.fileName(_script(title: 'سرّ الضغط العالي ⚽!')),
          'سرّ_الضغط_العالي_1760700000000.txt');
    });

    test('عنوان بلا حروف ← script', () {
      expect(Exporter.fileName(_script(title: '⚽🔥!!')), 'script_1760700000000.txt');
    });

    test('عنوان طويل يتقصّ', () {
      final name = Exporter.fileName(_script(title: 'a' * 100));
      expect(name, '${'a' * 40}_1760700000000.txt');
    });
  });
}
