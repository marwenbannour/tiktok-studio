import 'package:flutter_test/flutter_test.dart';

import 'package:tiktok_studio/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const TikTokStudioApp());
    expect(find.byType(TikTokStudioApp), findsOneWidget);
  });
}
