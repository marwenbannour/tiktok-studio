// تست E2E حقيقي مع Claude API (ياكل شوية tokens).
// المفتاح يجي من --dart-define (ولا من «الإعدادات» إذا مازال موجود).
// ⚠️ flutter test يفسخ الـapp من الـemulator في الآخر، والمفتاح المسجّل يمشي معاها.
//
//   flutter test integration_test/live_api_test.dart -d emulator-5554 --dart-define=ANTHROPIC_API_KEY=sk-ant-...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiktok_studio/claude_api.dart';
import 'package:tiktok_studio/main.dart';
import 'package:tiktok_studio/models.dart';
import 'package:tiktok_studio/prompts.dart';
import 'package:tiktok_studio/screens/history_screen.dart';
import 'package:tiktok_studio/screens/result_screen.dart';
import 'package:tiktok_studio/screens/teleprompter_screen.dart';
import 'package:tiktok_studio/storage.dart';

const _defineKey = String.fromEnvironment('ANTHROPIC_API_KEY');
const _noKey = 'ما فماش مفتاح. عطيه بـ--dart-define=ANTHROPIC_API_KEY=sk-ant-... '
    '(flutter test يفسخ الـapp في الآخر، يعني المفتاح اللي في «الإعدادات» يمشي معاها).';

Future<String?> _key() async {
  if (_defineKey.isNotEmpty) return _defineKey;
  final k = await AppStorage.getApiKey();
  return (k == null || k.trim().isEmpty) ? null : k.trim();
}

Finder _in<T>(Finder f) => find.descendant(of: find.byType(T), matching: f);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Claude API الحقيقي يرجّع سكريبت صالح', (tester) async {
    final key = await _key();
    if (key == null) fail(_noKey);
    final model = await AppStorage.getModel();
    debugPrint('LIVE: model = $model');

    final api = ClaudeApi(apiKey: key, model: model);
    final Map<String, dynamic> json;
    try {
      json = await api.askJson(Prompts.script(
        category: 'Dev AI',
        idea: '',
        style: 'تصوير الشاشة والكود فقط، بلا وجه، مع صوتي',
        duration: 15,
      ));
    } on ClaudeException catch (e) {
      fail('Claude API: ${e.message}\nAPI: ${e.apiMessage}');
    }
    final s = VideoScript.fromJson({...json, 'duration': 15});

    debugPrint('LIVE: title = ${s.title} | segments = ${s.segments.length}');
    expect(s.title, isNotEmpty);
    expect(s.segments, isNotEmpty);
    expect(s.segments.first.from, 0);
    expect(s.segments.last.to, 15);
    expect(s.caption, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('UI كاملة مع Claude الحقيقي: حضّر ← نتيجة ← Teleprompter ← محفوظات', (tester) async {
    if (await _key() == null) fail(_noKey);
    if (_defineKey.isNotEmpty) await AppStorage.setApiKey(_defineKey);
    final before = (await AppStorage.searchScripts()).length;

    await tester.pumpWidget(const TikTokStudioApp());
    await tester.pumpAndSettle();

    await _tap(tester, find.text('💻 الشاشة فقط'));
    await _tap(tester, find.text('15s'));
    await tester.enterText(find.byType(TextField).first, 'AI يكتبلي function فيها bug صغير');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await _tap(tester, find.text('حضّرلي الفيديو'));

    // نستنّاو Claude (لين 2 دقايق)، ونوقفو كان طلع message غلطة
    final end = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(end) && find.byType(ResultScreen).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
      final snack = find.byType(SnackBar);
      if (snack.evaluate().isNotEmpty) {
        final msg = tester.widgetList<Text>(_in<SnackBar>(find.byType(Text))).map((t) => t.data).join();
        fail('Claude رجّع غلطة: $msg');
      }
    }
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget, reason: 'السكريبت ما جاش في 2 دقايق');

    // شاشة النتيجة
    expect(find.text('Dev AI – 15 ثانية – 9:16'), findsOneWidget);
    expect(find.text('🎬 السكريبت ثانية بثانية'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^00–\d\ds$')), findsWidgets);

    final saved = await AppStorage.searchScripts();
    expect(saved.length, before + 1);
    final script = saved.first;
    debugPrint('LIVE UI: "${script.title}" | ${script.segments.length} segments | '
        'code: ${script.code.trim().isNotEmpty} | ${script.hashtags.join(' ')}');
    expect(script.segments.length, greaterThanOrEqualTo(2));
    expect(script.segments.last.to, inInclusiveRange(13, 17));

    final list = _in<ResultScreen>(find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('📲 الـCaption'), 300, scrollable: list);
    expect(find.text(script.caption), findsOneWidget);

    // Teleprompter
    await _tap(tester, find.text('Teleprompter'));
    expect(find.byType(TeleprompterScreen), findsOneWidget);
    expect(find.text(script.segments.first.voice), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // المحفوظات
    await tester.tap(_in<NavigationBar>(find.text('المحفوظات')));
    await tester.pumpAndSettle();
    expect(_in<HistoryScreen>(find.text(script.title)), findsWidgets);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
