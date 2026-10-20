// يلتقط screenshots للـPlay Store. يشغّل:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d emulator-5554
// الصور تتسجّل في screenshots/

import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiktok_studio/main.dart';
import 'package:tiktok_studio/models.dart';
import 'package:tiktok_studio/screens/result_screen.dart';
import 'package:tiktok_studio/screens/studio_screen.dart';
import 'package:tiktok_studio/storage.dart';

const _ideas = ['AI يصلّح bug في الكود', 'كيفاش تبدا في البرمجة', 'أدوات AI تخدم بيك'];

final _script = {
  'title': 'AI لقى الـbug في ثانية! 🐛',
  'hook_idea': 'كتبت function فيها غلطة… شوف كيفاش AI لقاها',
  'segments': [
    {'from': 0, 'to': 5, 'screen': 'الكود على الشاشة', 'text': 'الـbug هذا… تلقاه؟',
     'voice': 'كتبت function بسيطة، أما فيها غلطة صغيرة…'},
    {'from': 5, 'to': 12, 'screen': 'AI يحلّل الكود', 'text': 'AI: السطر 3 ❌',
     'voice': 'سألت الـAI، وفي ثانية قاللي الغلطة وين بالضبط'},
    {'from': 12, 'to': 20, 'screen': 'وجهي + الكود مصلّح', 'text': 'اكتب DEV 👨‍💻',
     'voice': 'صلّحناه مع بعضنا. اكتبلي DEV في الكومنتارات تحب شرح أكثر'},
  ],
  'code': 'int somme(int a, int b) {\n  return a - b; // ❌ لازم a + b\n}',
  'code_note': 'الغلطة: استعملنا - عوض +',
  'steps': [
    {'title': 'صوّر الشاشة', 'detail': 'سجّل الكود وإنت تكتبو'},
    {'title': 'المونتاج', 'detail': 'CapCut، زيد زoom على السطر الغالط'},
  ],
  'caption': 'AI صلّحلي الـbug في ثانية ⚡ جرّبتوه؟',
  'hashtags': ['#dev', '#coding', '#ai', '#تونس'],
  'tips': ['ما تحطّش مفتاح سرّي في الكود وإنت تصوّر'],
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final real = http.Client();

  final mock = MockClient((req) async {
    if (req.url.toString().contains('ollama.com')) {
      final prompt = (jsonDecode(req.body)['messages'] as List).first['content'] as String;
      final text = prompt.contains('اقترح 5 أفكار')
          ? jsonEncode({'ideas': _ideas})
          : jsonEncode(_script);
      return http.Response.bytes(
          utf8.encode(jsonEncode({'message': {'role': 'assistant', 'content': text}})), 200,
          headers: {'content-type': 'application/json'});
    }
    // تمرير باقي الطلبات (خطوط Google) للشبكة الحقيقية
    final s = await real.send(req);
    final bytes = await s.stream.toBytes();
    return http.Response.bytes(bytes, s.statusCode,
        headers: s.headers, request: req, reasonPhrase: s.reasonPhrase);
  });

  Future<void> shot(WidgetTester t, String name) async {
    await t.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  Future<void> tapVisible(WidgetTester t, Finder f) async {
    // نلوّج على العنصر: نجرّبو كل Scrollable عمودي (فمّا scrollers أفقية للـchips)
    if (f.evaluate().isEmpty) {
      for (final sc in find.byType(Scrollable).evaluate()) {
        if (f.evaluate().isNotEmpty) break;
        try {
          await t.scrollUntilVisible(f, 200,
              scrollable: find.byWidget(sc.widget), maxScrolls: 30);
        } catch (_) {}
      }
    }
    // نستنّى شويّة كان مازال ما بان (render بطيء على émulateur بارد)
    for (var i = 0; i < 20 && f.evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets('capture Play Store screenshots', (tester) async {
    await http.runWithClient(() async {
      await AppStorage.setApiKey('demo-key');
      await AppStorage.setModel('gemma4:31b');

      await tester.pumpWidget(const TikTokStudioApp());
      await tester.pumpAndSettle(); // splash → home
      await tester.pump(const Duration(seconds: 3)); // نستنّى الخطوط تتحمّل
      await tester.pumpAndSettle();

      await binding.convertFlutterSurfaceToImage();

      // 1) شاشة حضّر (مع فكرة مكتوبة)
      await tester.enterText(
          find.descendant(of: find.byType(StudioScreen), matching: find.byType(TextField)),
          'AI يصلّح bug في الكود متاعي');
      await tester.pumpAndSettle();
      await shot(tester, '1_create');

      // 2) شاشة النتيجة (سكريبت)
      await tapVisible(tester, find.text('حضّرلي الفيديو'));
      for (var i = 0; i < 20 && find.byType(ResultScreen).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pumpAndSettle();
      await shot(tester, '2_result');

      // 6) تسجيل بالكاميرا (Teleprompter → 🎥) — الأذونات تتعطا بالتوازي عبر adb
      await tapVisible(tester, find.text('Teleprompter'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byTooltip('سجّل بالكاميرا'));
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        if (find.byType(CameraPreview).evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();
      await shot(tester, '6_record');

      // نسجّلو فيديو حقيقي: سجّل → 3-2-1 → ~4s → وقّف → يتسجّل فالـgalerie
      final recBtn = find.text('سجّل');
      if (recBtn.evaluate().isNotEmpty) {
        await tester.tap(recBtn);
        // العدّ التنازلي 3 ثواني + تسجيل
        for (var i = 0; i < 24; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        await shot(tester, '7_recording');
        // نكمّلو شويّة تسجيل
        for (var i = 0; i < 14; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        final stopBtn = find.text('وقّف التسجيل');
        if (stopBtn.evaluate().isNotEmpty) {
          await tester.tap(stopBtn);
          // نستنّاو الحفظ فالـgalerie
          for (var i = 0; i < 40; i++) {
            await tester.pump(const Duration(milliseconds: 300));
            if (find.text('تسجّل الفيديو في الـgalerie ✅').evaluate().isNotEmpty) break;
          }
          await shot(tester, '8_saved');
        }
      }

      await tester.pageBack(); // من التسجيل
      await tester.pumpAndSettle();
      await tester.pageBack(); // من Teleprompter → النتيجة
      await tester.pumpAndSettle();

      // 3) المحفوظات
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.descendant(
          of: find.byType(NavigationBar), matching: find.text('المحفوظات')));
      await shot(tester, '3_history');

      // 4) الإعدادات
      await tapVisible(tester, find.descendant(
          of: find.byType(NavigationBar), matching: find.text('الإعدادات')));
      await shot(tester, '4_settings');

      // 5) لوحة الإحصائيات — نزرعو بيانات بإحصائيات
      VideoScript seed(String t, String c, int created) => VideoScript.fromJson({
            'title': t, 'category': c, 'style': 'x', 'duration': 20,
            'segments': [{'from': 0, 'to': 20, 'screen': 's', 'text': 't', 'voice': 'v'}],
            'caption': 'c', 'hashtags': ['#a'], 'createdAt': created,
          });
      final a = await AppStorage.saveScript(seed('أحسن فيديو عن الـAI', 'Dev AI', 1000));
      final b = await AppStorage.saveScript(seed('تكتيك الضغط العالي', 'Football', 2000));
      final cc = await AppStorage.saveScript(seed('معلومة غريبة على الفضاء', 'معلومات وحقائق', 3000));
      await AppStorage.setStats(a.dbId!, 12500, 1800, 230);
      await AppStorage.setStats(b.dbId!, 3400, 420, 55);
      await AppStorage.setStats(cc.dbId!, 7800, 900, 110);
      await AppStorage.setPublished(a.dbId!, 1760000000000);
      await AppStorage.setPublished(b.dbId!, 1760000000000);
      await AppStorage.setPublished(cc.dbId!, 1760000000000);

      await tapVisible(tester, find.descendant(
          of: find.byType(NavigationBar), matching: find.text('المحفوظات')));
      await tapVisible(tester, find.byTooltip('إحصائيات الأداء'));
      await shot(tester, '5_stats');
    }, () => mock);
  });
}
