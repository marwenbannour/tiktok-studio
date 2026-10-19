// تست E2E: يمشي في الـapp الكل على التليفون/الـemulator.
// الـstorage حقيقي، أما Claude API مبدّل بـMockClient (بلاش فلوس، ونتيجة ثابتة).
//
//   flutter test integration_test/app_e2e_test.dart -d emulator-5554

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_studio/exporter.dart';
import 'package:tiktok_studio/main.dart';
import 'package:tiktok_studio/models.dart';
import 'package:tiktok_studio/reminders.dart';
import 'package:tiktok_studio/screens/history_screen.dart';
import 'package:tiktok_studio/screens/plans_screen.dart';
import 'package:tiktok_studio/screens/segment_editor.dart';
import 'package:tiktok_studio/storage.dart';
import 'package:tiktok_studio/screens/result_screen.dart';
import 'package:tiktok_studio/screens/settings_screen.dart';
import 'package:tiktok_studio/screens/studio_screen.dart';
import 'package:tiktok_studio/screens/teleprompter_screen.dart';

const _fakeKey = 'sk-ant-e2e-test-key';

const _ideas = [
  'تكتيك 4-3-3 في 20 ثانية',
  'أغرب قانون في الكورة',
  'كيفاش تقرا ماتش كيما مدرّب',
];

final _script = {
  'title': 'سرّ الضغط العالي',
  'hook_idea': 'علاش الفرق الكبار يضغطو من الفوق؟',
  'segments': [
    {'from': 0, 'to': 10, 'screen': 'لوحة تكتيك', 'text': 'الضغط العالي؟', 'voice': 'تعرف علاش برشلونة تضغط؟'},
    {'from': 10, 'to': 20, 'screen': 'رسم أسهم', 'text': '3 ثواني', 'voice': 'القاعدة متاع 3 ثواني'},
    {'from': 20, 'to': 30, 'screen': 'وجهي', 'text': 'اكتب PRESS', 'voice': 'اكتبلي PRESS في الكومنتارات'},
  ],
  'code': '',
  'code_note': '',
  'steps': [
    {'title': 'صوّر اللوحة', 'detail': 'من الفوق، ضوء طبيعي'},
    {'title': 'المونتاج', 'detail': 'CapCut، cuts كل 2 ثواني'},
  ],
  'caption': 'الضغط العالي مشروح في 30 ثانية ⚽',
  'hashtags': ['#football', '#tactics', '#تونس'],
  'tips': ['ما تستعملش لقطات ماتشات عندها حقوق'],
};

const _rewritten = {'screen': 'شاشة جديدة', 'text': 'نص جديد', 'voice': 'صوت جديد من Claude'};

/// يرجّع جواب كيما Ollama API: {"message":{"role":"assistant","content":...}}
http.Response _claudeReply(String text, {int status = 200}) => http.Response.bytes(
      utf8.encode(jsonEncode({
        'message': {'role': 'assistant', 'content': text}
      })),
      status,
      headers: {'content-type': 'application/json'},
    );

/// Claude مزيّف: يسجّل الطلبات ويجاوب حسب الـprompt.
class FakeClaude {
  final requests = <http.Request>[];
  http.Response Function(String prompt)? override;

  Map<String, dynamic> body(int i) => jsonDecode(requests[i].body) as Map<String, dynamic>;
  String prompt(int i) => (body(i)['messages'] as List).first['content'] as String;

  late final client = MockClient((req) async {
    requests.add(req);
    final p = (jsonDecode(req.body)['messages'] as List).first['content'] as String;
    if (override != null) return override!(p);
    if (p.contains('اقترح 5 أفكار')) return _claudeReply(jsonEncode({'ideas': _ideas}));
    if (p.contains('عاود اكتب segment')) return _claudeReply(jsonEncode(_rewritten));
    // نلفّو الـJSON بـ```json باش نتأكدو إنّ الـapp تنظّفو
    return _claudeReply('```json\n${jsonEncode(_script)}\n```');
  });
}

Future<void> _resetStorage() async {
  await const FlutterSecureStorage().deleteAll();
  (await SharedPreferences.getInstance()).clear();
}

Future<void> _launch(WidgetTester tester) async {
  await tester.pumpWidget(const TikTokStudioApp());
  await tester.pumpAndSettle();
}

Finder _in<T>(Finder f) => find.descendant(of: find.byType(T), matching: f);

Future<void> _goTab(WidgetTester tester, String label) async {
  await tester.tap(_in<NavigationBar>(find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// يستنّى لين يبان الـwidget (للحاجات اللي فيها platform channels)
Future<void> _waitFor(WidgetTester tester, Finder f, {int seconds = 10}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (f.evaluate().isNotEmpty) return;
  }
  expect(f, findsWidgets, reason: 'ما بانش في $seconds ثواني');
}

Future<void> _clearSnackBars(WidgetTester tester) async {
  tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).clearSnackBars();
  await tester.pumpAndSettle();
}

/// يحضّر سكريبت (بالـmock) ويحلّ شاشة النتيجة
Future<void> _generate(WidgetTester tester) async {
  await _tap(tester, find.text('حضّرلي الفيديو'));
  await _waitFor(tester, find.byType(ResultScreen));
  await tester.pumpAndSettle();
}

Finder _sheetField(String label) =>
    find.descendant(of: find.byType(SegmentEditor), matching: find.widgetWithText(TextField, label));

String _fieldText(WidgetTester tester, String label) =>
    tester.widget<TextField>(_sheetField(label)).controller!.text;

Future<void> _saveKey(WidgetTester tester, String key) async {
  await _goTab(tester, 'الإعدادات');
  await tester.enterText(_in<SettingsScreen>(find.byType(TextField)).first, key);
  await _tap(tester, find.text('سجّل المفتاح'));
  await _waitFor(tester, find.text('تسجّل المفتاح ✅'));
  await _clearSnackBars(tester);
  await _goTab(tester, 'حضّر');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // ما نحمّلوش الخطوط من النت وقت التست (باش ما تمرّش عبر الـMockClient وتعلّق)
  GoogleFonts.config.allowRuntimeFetching = false;

  late FakeClaude claude;

  // التست يفسخ الـstorage: نحفظو المفتاح والمحفوظات متاعك قبل، ونرجّعوهم بعد.
  String? savedKey;
  Map<String, Object> savedPrefs = {};

  setUpAll(() async {
    savedKey = await const FlutterSecureStorage().read(key: 'anthropic_api_key');
    final p = await SharedPreferences.getInstance();
    savedPrefs = {for (final k in p.getKeys()) k: p.get(k)!};
  });

  tearDownAll(() async {
    await _resetStorage();
    if (savedKey != null) {
      await const FlutterSecureStorage().write(key: 'anthropic_api_key', value: savedKey);
    }
    final p = await SharedPreferences.getInstance();
    for (final e in savedPrefs.entries) {
      final v = e.value;
      if (v is String) await p.setString(e.key, v);
      if (v is bool) await p.setBool(e.key, v);
      if (v is int) await p.setInt(e.key, v);
      if (v is double) await p.setDouble(e.key, v);
      if (v is List) await p.setStringList(e.key, v.cast<String>());
    }
  });

  setUp(() async {
    await _resetStorage();
    claude = FakeClaude();
  });

  testWidgets('بلا مفتاح: يطلب المفتاح وما يبعث حتى طلب', (tester) async {
    await http.runWithClient(() async {
      await _launch(tester);

      await _tap(tester, find.text('حضّرلي الفيديو'));
      await _waitFor(tester, find.text('زيد مفتاح الـAPI في «الإعدادات» قبل.'));

      await _clearSnackBars(tester);
      await _tap(tester, find.text('اقترحلي أفكار'));
      await _waitFor(tester, find.text('زيد مفتاح الـAPI في «الإعدادات» قبل.'));

      expect(claude.requests, isEmpty);
      expect(find.byType(ResultScreen), findsNothing);
    }, () => claude.client);
  });

  testWidgets('الرحلة الكاملة: مفتاح ← أفكار ← سكريبت ← Teleprompter ← محفوظات', (tester) async {
    await http.runWithClient(() async {
      await _launch(tester);

      // ---- الإعدادات: المفتاح + الموديل ----
      await _goTab(tester, 'الإعدادات');
      await tester.enterText(_in<SettingsScreen>(find.byType(TextField)).first, '  $_fakeKey  ');
      await _tap(tester, find.text('سجّل المفتاح'));
      await _waitFor(tester, find.text('تسجّل المفتاح ✅'));
      expect(await const FlutterSecureStorage().read(key: 'anthropic_api_key'), _fakeKey);
      await _clearSnackBars(tester);

      await _tap(tester, find.text('gpt-oss:20b'));
      expect((await SharedPreferences.getInstance()).getString('model'), 'gpt-oss:20b');

      // ---- حضّر: الاختيارات ----
      await _goTab(tester, 'حضّر');
      await _tap(tester, find.text('⚽ Football'));
      await _tap(tester, find.text('🎥 بوجهي'));
      await _tap(tester, find.text('30s'));

      // ---- اقترحلي أفكار ----
      await _tap(tester, find.text('اقترحلي أفكار'));
      await _waitFor(tester, find.text(_ideas[1]));
      for (final idea in _ideas) {
        expect(find.text(idea), findsOneWidget);
      }
      expect(claude.requests, hasLength(1));
      expect(claude.prompt(0), contains('موضوع: Football'));
      expect(claude.body(0)['options']['num_predict'], 1000);

      await _tap(tester, find.text(_ideas[1]));
      final ideaField = tester.widget<TextField>(_in<StudioScreen>(find.byType(TextField)));
      expect(ideaField.controller!.text, _ideas[1]);
      expect(find.text(_ideas[0]), findsNothing); // القائمة تسكّرت

      // ---- حضّرلي الفيديو ----
      await _tap(tester, find.text('حضّرلي الفيديو'));
      await _waitFor(tester, find.byType(ResultScreen));
      await tester.pumpAndSettle();

      // الطلب اللي مشى لـClaude
      expect(claude.requests, hasLength(2));
      final req = claude.requests[1];
      expect(req.url.toString(), 'https://ollama.com/api/chat');
      expect(req.method, 'POST');
      expect(req.headers['authorization'], 'Bearer $_fakeKey');
      expect(claude.body(1)['stream'], false);
      expect(claude.body(1)['format'], 'json');
      expect(claude.body(1)['model'], 'gpt-oss:20b');
      final prompt = claude.prompt(1);
      expect(prompt, contains('- النوع: Football'));
      expect(prompt, contains('- الفكرة: ${_ideas[1]}'));
      expect(prompt, contains('- طريقة الظهور: نظهر بوجهي ونحكي للكاميرا'));
      expect(prompt, contains('- المدّة: 30 ثانية'));

      // ---- شاشة النتيجة ----
      expect(_in<AppBar>(find.text('سرّ الضغط العالي')), findsOneWidget);
      expect(find.text('Football – 30 ثانية – 9:16'), findsOneWidget);
      expect(find.text('علاش الفرق الكبار يضغطو من الفوق؟'), findsOneWidget);
      expect(find.text('00–10s'), findsOneWidget);
      expect(find.text('تعرف علاش برشلونة تضغط؟'), findsOneWidget);
      expect(find.text('💻 الكود'), findsNothing); // code فارغ

      final resultList = _in<ResultScreen>(find.byType(Scrollable)).first;
      for (final t in ['20–30s', 'المونتاج', 'الضغط العالي مشروح في 30 ثانية ⚽', '#tactics',
          '• ما تستعملش لقطات ماتشات عندها حقوق']) {
        await tester.scrollUntilVisible(find.text(t), 200, scrollable: resultList);
        expect(find.text(t), findsOneWidget);
      }

      // انسخ الكل ← الـclipboard (بعض الـemulators يمنعو قراية الـclipboard كي الـapp موش focused)
      await _tap(tester, find.byTooltip('انسخ الكل'));
      expect(find.text('تنسخ ✅'), findsOneWidget);
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      if (clip?.text != null) {
        expect(clip!.text, contains('سرّ الضغط العالي'));
        expect(clip.text, contains('[10–20s]'));
        expect(clip.text, contains('#football #tactics #تونس'));
      }
      await _clearSnackBars(tester);

      // ---- Teleprompter ----
      await _tap(tester, find.text('Teleprompter'));
      expect(find.byType(TeleprompterScreen), findsOneWidget);
      expect(find.text('اكتبلي PRESS في الكومنتارات'), findsOneWidget);

      await _tap(tester, find.byTooltip('أسرع'));
      expect(find.text('×1.4'), findsOneWidget);

      final prompter = _in<TeleprompterScreen>(find.byType(Scrollable)).first;
      double offset() => tester.state<ScrollableState>(prompter).position.pixels;
      expect(offset(), 0);

      await tester.tap(find.text('ابدأ'));
      await tester.pump(const Duration(seconds: 1)); // ما نستعملوش pumpAndSettle: يسكرولي ديما
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('وقّف'), findsOneWidget);
      expect(offset(), greaterThan(0));

      await tester.tap(find.text('وقّف'));
      await tester.pumpAndSettle();
      expect(find.text('ابدأ'), findsOneWidget);

      await _tap(tester, find.byTooltip('من الأوّل'));
      expect(offset(), 0);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsNothing);

      // ---- المحفوظات ----
      await _goTab(tester, 'المحفوظات');
      await _waitFor(tester, _in<HistoryScreen>(find.text('سرّ الضغط العالي')));
      expect(find.text('Football – 30s'), findsOneWidget);

      await _tap(tester, _in<HistoryScreen>(find.text('سرّ الضغط العالي')));
      expect(find.byType(ResultScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await _tap(tester, find.byTooltip('فسخ'));
      await _waitFor(tester, find.text('ما عندك حتى سكريبت. حضّر أول فيديو من «حضّر» 🎬'));
      expect(_in<HistoryScreen>(find.byType(ListTile)), findsNothing);
    }, () => claude.client);
  });

  testWidgets('المفتاح والموديل يقعدو محفوظين بعد ما الـapp تتعاود', (tester) async {
    await http.runWithClient(() async {
      await _launch(tester);
      await _saveKey(tester, _fakeKey);
      await _goTab(tester, 'الإعدادات');
      await _tap(tester, find.text('gpt-oss:20b'));

      // نعاودو نحلّو الـapp من الصفر
      await tester.pumpWidget(const SizedBox());
      await _launch(tester);
      await _goTab(tester, 'الإعدادات');
      await _waitFor(tester, find.text(_fakeKey));

      final picked = find.ancestor(of: find.text('gpt-oss:20b'), matching: find.byType(ListTile));
      expect(find.descendant(of: picked, matching: find.byIcon(Icons.check_circle)), findsOneWidget);

      // ممسوح ← المفتاح يتفسخ
      await tester.enterText(_in<SettingsScreen>(find.byType(TextField)).first, '');
      await _tap(tester, find.text('سجّل المفتاح'));
      await _waitFor(tester, find.text('تفسخ المفتاح.'));
      expect(await const FlutterSecureStorage().read(key: 'anthropic_api_key'), isNull);
    }, () => claude.client);
  });

  testWidgets('تبديل segment: بيدّك، بـClaude، ولا تبطّل', (tester) async {
    await http.runWithClient(() async {
      await _launch(tester);
      await _saveKey(tester, _fakeKey);
      await _generate(tester);
      expect(find.text('👆 اضغط على segment باش تبدّلو ولا Claude يعاود يكتبو'), findsOneWidget);

      // ---- بيدّك: الـhook ----
      await _tap(tester, find.text('تعرف علاش برشلونة تضغط؟'));
      expect(find.text('✏️ بدّل 00–10s (الـhook)'), findsOneWidget);
      expect(find.text('hook أقوى يوقّف السكرول'), findsOneWidget);
      expect(_fieldText(tester, '🎤 الصوت'), 'تعرف علاش برشلونة تضغط؟');
      await tester.enterText(_sheetField('🎤 الصوت'), 'صوت بيدّي');
      await _tap(tester, find.text('سجّل التبديل'));
      expect(find.byType(SegmentEditor), findsNothing);
      await _waitFor(tester, find.text('تسجّل التبديل ✅'));
      expect(find.text('صوت بيدّي'), findsOneWidget);
      expect(find.text('تعرف علاش برشلونة تضغط؟'), findsNothing);
      expect((await AppStorage.loadHistory()).first.segments[0].voice, 'صوت بيدّي');
      await _clearSnackBars(tester);

      // ---- بطّل: ما يتبدّل شي ----
      await _tap(tester, find.text('القاعدة متاع 3 ثواني'));
      expect(find.text('✏️ بدّل 10–20s'), findsOneWidget);
      expect(find.text('hook أقوى يوقّف السكرول'), findsNothing);
      await tester.enterText(_sheetField('🎤 الصوت'), 'ما يلزمش يتسجّل');
      await _tap(tester, find.text('بطّل'));
      expect(find.text('القاعدة متاع 3 ثواني'), findsOneWidget);
      expect(find.text('ما يلزمش يتسجّل'), findsNothing);

      // ---- بـClaude ----
      await _tap(tester, find.text('القاعدة متاع 3 ثواني'));
      await _tap(tester, find.text('أقصر وأوضح'));
      final ask = find.descendant(
          of: find.byType(SegmentEditor), matching: find.widgetWithText(TextField, 'شنوّة تحب تبدّل؟ (اختياري)'));
      expect(tester.widget<TextField>(ask).controller!.text, 'أقصر وأوضح');
      await _tap(tester, find.text('عاود اكتبو'));
      final end = DateTime.now().add(const Duration(seconds: 10));
      while (_fieldText(tester, '🎤 الصوت') != 'صوت جديد من Claude' && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_fieldText(tester, '🎤 الصوت'), 'صوت جديد من Claude');
      expect(_fieldText(tester, '🎬 على الشاشة'), 'شاشة جديدة');
      expect(_fieldText(tester, '✍️ النص على الفيديو'), 'نص جديد');

      // الطلب: فيه السياق (مع التبديل اللي عملناه بيدّنا) والطلب
      expect(claude.requests, hasLength(2));
      final prompt = claude.prompt(1);
      expect(prompt, contains('عاود اكتب segment'));
      expect(prompt, contains('👉 [10–20s] القاعدة متاع 3 ثواني'));
      expect(prompt, contains('[00–10s] صوت بيدّي'));
      expect(prompt, contains('الطلب: أقصر وأوضح'));
      expect(claude.body(1)['options']['num_predict'], 800);

      await _tap(tester, find.text('سجّل التبديل'));
      await _waitFor(tester, find.text('صوت جديد من Claude'));
      expect(find.text('نص جديد'), findsOneWidget);
      final saved = (await AppStorage.loadHistory()).first;
      expect(saved.segments[1].voice, 'صوت جديد من Claude');
      expect(saved.segments[1].from, 10);
      expect(saved.segments[1].to, 20);
      expect(saved.segments[0].voice, 'صوت بيدّي');
      expect(saved.segments[2].voice, 'اكتبلي PRESS في الكومنتارات');
      await _clearSnackBars(tester);

      // الـTeleprompter ياخو النسخة المبدّلة، وفيه زرّ الكاميرا
      await _tap(tester, find.text('Teleprompter'));
      expect(find.text('صوت جديد من Claude'), findsOneWidget);
      expect(find.byTooltip('سجّل بالكاميرا'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // ---- غلطة من Claude تبان في الـsheet ----
      claude.override = (_) => _claudeReply('', status: 529);
      await _tap(tester, find.text('اكتبلي PRESS في الكومنتارات'));
      await _tap(tester, find.text('عاود اكتبو'));
      await _waitFor(tester, find.text('السيرفر مشغول توّا. عاود بعد شوية.'));
      expect(_fieldText(tester, '🎤 الصوت'), 'اكتبلي PRESS في الكومنتارات');
      await _tap(tester, find.text('بطّل'));

      // المحفوظات فيها التبديل
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _goTab(tester, 'المحفوظات');
      await _tap(tester, _in<HistoryScreen>(find.text('سرّ الضغط العالي')));
      expect(find.text('صوت جديد من Claude'), findsOneWidget);
      expect(find.text('صوت بيدّي'), findsOneWidget);
    }, () => claude.client);
  });

  testWidgets('البرنامج: من النتيجة، الحالة، تبديل، فسخ', (tester) async {
    await http.runWithClient(() async {
      await _launch(tester);
      await _goTab(tester, 'البرنامج');
      expect(find.textContaining('ما برمجت حتى فيديو'), findsOneWidget);
      await _goTab(tester, 'حضّر');

      await _saveKey(tester, _fakeKey);
      await _generate(tester);

      // ---- زيد للبرنامج من شاشة النتيجة ----
      await _tap(tester, find.byTooltip('زيد للبرنامج'));
      expect(find.text('📅 برمج فيديو'), findsOneWidget);
      expect(find.text('🔗 مربوط بسكريبت من المحفوظات'), findsOneWidget);
      final title = find.widgetWithText(TextField, 'العنوان ولا الفكرة');
      expect(tester.widget<TextField>(title).controller!.text, 'سرّ الضغط العالي');
      await _tap(tester, find.text('🔔 فكّرني وقت النشر')); // بلاش popup متاع الإذن في التست
      await _tap(tester, find.text('سجّل'));
      await _waitFor(tester, find.textContaining('تزاد للبرنامج'));
      await _clearSnackBars(tester);

      final plans = await AppStorage.loadPlans();
      expect(plans, hasLength(1));
      final scriptId = (await AppStorage.loadHistory()).first.createdAt;
      expect(plans.first.scriptId, scriptId);
      expect(plans.first.reminder, isFalse);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(plans.first.date, DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18));

      await tester.pageBack();
      await tester.pumpAndSettle();

      // ---- شاشة البرنامج ----
      await _goTab(tester, 'البرنامج');
      await _waitFor(tester, _in<PlansScreen>(find.text('سرّ الضغط العالي')));
      expect(find.text('💡 فكرة'), findsOneWidget);
      expect(find.text(' 🔗'), findsOneWidget);
      expect(find.text(' 🔔'), findsNothing);
      expect(find.text('هالجمعة'), findsOneWidget);

      // الحالة تدور
      await _tap(tester, find.text('💡 فكرة'));
      await _waitFor(tester, find.text('🎬 تصوّر'));
      await _tap(tester, find.text('🎬 تصوّر'));
      await _waitFor(tester, find.text('✅ تنشر'));
      expect((await AppStorage.loadPlans()).first.status, PlanStatus.posted);

      // مربوط ← يحلّ السكريبت
      await _tap(tester, _in<PlansScreen>(find.text('سرّ الضغط العالي')));
      expect(find.byType(ResultScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // ---- plan جديد بالـFAB ----
      await _tap(tester, find.text('برمج فيديو'));
      expect(find.text('📅 برمج فيديو'), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'سجّل');
      expect(tester.widget<FilledButton>(save).onPressed, isNull, reason: 'بلا عنوان ما يتسجّلش');
      await tester.enterText(find.widgetWithText(TextField, 'العنوان ولا الفكرة'), 'فيديو تجريبي');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('🔔 فكّرني وقت النشر'));
      await _tap(tester, save);
      await _waitFor(tester, _in<PlansScreen>(find.text('فيديو تجريبي')));
      expect(await AppStorage.loadPlans(), hasLength(2));

      // ---- بدّل ----
      final menus = _in<PlansScreen>(find.byTooltip('خيارات'));
      final tiles = _in<PlansScreen>(find.byType(ListTile));
      final idx = tester.widgetList<ListTile>(tiles).toList()
          .indexWhere((t) => (t.title as Text).data == 'فيديو تجريبي');
      await _tap(tester, menus.at(idx));
      await _tap(tester, find.text('✏️ بدّل'));
      await tester.enterText(find.widgetWithText(TextField, 'العنوان ولا الفكرة'), 'فيديو مبدّل');
      await tester.pumpAndSettle();
      await _tap(tester, find.widgetWithText(FilledButton, 'سجّل'));
      await _waitFor(tester, _in<PlansScreen>(find.text('فيديو مبدّل')));
      expect(find.text('فيديو تجريبي'), findsNothing);

      // ---- فسخ الكل ----
      while (_in<PlansScreen>(find.byTooltip('خيارات')).evaluate().isNotEmpty) {
        await _tap(tester, _in<PlansScreen>(find.byTooltip('خيارات')).first);
        await _tap(tester, find.text('🗑️ فسخ'));
      }
      expect(find.textContaining('ما برمجت حتى فيديو'), findsOneWidget);
      expect(await AppStorage.loadPlans(), isEmpty);
    }, () => claude.client);
  });

  testWidgets('التذكير: يتبرمج، ويتفسخ كي يتنشر ولا يفوت وقتو', (tester) async {
    final p = PlannedVideo(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'تست التذكير',
      date: DateTime.now().add(const Duration(hours: 2)),
    );
    expect(await Reminders.sync(p, askPermission: false), isTrue);
    expect(await Reminders.pendingIds(), contains(p.notificationId));

    expect(await Reminders.sync(p.copyWith(status: PlanStatus.posted), askPermission: false), isFalse);
    expect(await Reminders.pendingIds(), isNot(contains(p.notificationId)));

    await Reminders.sync(p, askPermission: false);
    expect(await Reminders.sync(p.copyWith(reminder: false), askPermission: false), isFalse);
    expect(await Reminders.pendingIds(), isNot(contains(p.notificationId)));

    final past = p.copyWith(date: DateTime.now().subtract(const Duration(minutes: 1)));
    expect(await Reminders.sync(past, askPermission: false), isFalse);
    expect(await Reminders.pendingIds(), isNot(contains(p.notificationId)));
  });

  testWidgets('التصدير: fichier .txt فيه السكريبت كامل', (tester) async {
    final s = VideoScript.fromJson({..._script, 'category': 'Football', 'duration': 30, 'createdAt': 1760700000000});
    final f = await Exporter.writeTxt(s);
    expect(f.existsSync(), isTrue);
    expect(f.path, endsWith('سرّ_الضغط_العالي_1760700000000.txt'));
    final content = await f.readAsString();
    expect(content, s.fullText());
    expect(content, contains('[00–10s]'));
    expect(content, contains('#football #tactics #تونس'));
    await f.delete();
  });

  group('أخطاء الـAPI تبان بالدارجة', () {
    final cases = <String, (http.Response Function(String), String)>{
      '401': ((_) => _claudeReply('', status: 401),
          'المفتاح موش صحيح ولا ما عندوش الحق. ثبّت فيه في «الإعدادات».'),
      '429': ((_) => _claudeReply('', status: 429), 'برشا طلبات ولا كمل الرصيد. استنّى شوية وعاود.'),
      '529': ((_) => _claudeReply('', status: 529), 'السيرفر مشغول توّا. عاود بعد شوية.'),
      'JSON مكسّر': ((_) => _claudeReply('سامحني، ما نجمتش'), 'الجواب ما جاش في الشكل الصحيح. عاود جرّب.'),
      'segments فارغة': ((_) => _claudeReply(jsonEncode({'title': 'x', 'segments': []})), 'الجواب جا ناقص. عاود جرّب.'),
      'HTML موش JSON': ((_) => http.Response('<html>502</html>', 502), 'جواب غريب من السيرفر (502).'),
    };

    for (final c in cases.entries) {
      testWidgets(c.key, (tester) async {
        claude.override = c.value.$1;
        await http.runWithClient(() async {
          await _launch(tester);
          await _saveKey(tester, _fakeKey);

          await _tap(tester, find.text('حضّرلي الفيديو'));
          await _waitFor(tester, find.text(c.value.$2));

          expect(claude.requests, hasLength(1));
          expect(find.byType(ResultScreen), findsNothing);
          expect(find.text('حضّرلي الفيديو'), findsOneWidget); // الزرّ رجع خدّام
          expect((await SharedPreferences.getInstance()).getString('history_v1'), isNull);
        }, () => claude.client);
      });
    }
  });
}
