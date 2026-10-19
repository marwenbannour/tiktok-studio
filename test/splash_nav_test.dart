import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_studio/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // flutter_secure_storage: نرجّعو null لكل حاجة
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  testWidgets('شاشة الإطلاق تنتقل للـhome وما تعلّقش (pumpAndSettle)', (tester) async {
    await tester.pumpWidget(const TikTokStudioApp());
    // أول حاجة: الـsplash
    expect(find.text('فكرة · سكريبت · فيديو'), findsOneWidget);

    // لازم pumpAndSettle يكمّل (موش يعلّق) ونوصلو للـHomeShell
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('أهلا 👋'), findsOneWidget);
    expect(find.text('نوع المحتوى'), findsOneWidget);
    // ما بقيناش في الـsplash (البادج متاع الـsplash تفسخ)
    expect(find.text('تونس 🇹🇳'), findsNothing);
  });
}
