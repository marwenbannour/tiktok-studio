import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_studio/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('F20: الحدّ الافتراضي 0 (بلا حدّ)', () async {
    expect(await AppStorage.getGenCap(), 0);
    expect(await AppStorage.genCount(), 0);
  });

  test('F20: تسجيل الحدّ (السالب يولّي 0)', () async {
    await AppStorage.setGenCap(100);
    expect(await AppStorage.getGenCap(), 100);
    await AppStorage.setGenCap(-5);
    expect(await AppStorage.getGenCap(), 0);
  });

  test('F20: العدّاد يزيد', () async {
    expect(await AppStorage.incrementGenCount(), 1);
    expect(await AppStorage.incrementGenCount(), 2);
    expect(await AppStorage.genCount(), 2);
  });

  test('F20: شهر جديد يصفّر العدّاد', () async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({'gen_month': '2020-01', 'gen_count': 5});
    expect(await AppStorage.genCount(), 0); // شهر مختلف
    expect(await AppStorage.incrementGenCount(), 1); // يبدا من جديد
    expect((await SharedPreferences.getInstance()).getString('gen_month'), month);
  });
}
