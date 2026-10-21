import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_studio/prompts.dart';

void main() {
  test('hooks: يطلب 3 hooks بالنوع والفكرة وبشكل JSON', () {
    final p = Prompts.hooks('Dev AI', 'AI يصلّح bug');
    expect(p, contains('3 hooks'));
    expect(p, contains('Dev AI'));
    expect(p, contains('AI يصلّح bug'));
    expect(p, contains('{"hooks":'));
  });

  test('hooks: بلا فكرة → يطلب من الموديل يختار زاوية', () {
    final p = Prompts.hooks('Football', '');
    expect(p, contains('إختار إنت زاوية'));
  });

  test('script: كان فمّا hook، يفرضو كـsegment الأول', () {
    final withHook = Prompts.script(
      category: 'Dev AI',
      idea: 'x',
      style: 'الشاشة فقط',
      duration: 20,
      hook: 'شدّ بالك: هالغلطة تقتل كودك',
    );
    expect(withHook, contains('«شدّ بالك: هالغلطة تقتل كودك»'));
    expect(withHook, contains('الـhook (segment الأول'));

    final noHook = Prompts.script(
      category: 'Dev AI',
      idea: 'x',
      style: 'الشاشة فقط',
      duration: 20,
    );
    expect(noHook.contains('الـhook (segment الأول'), isFalse);
  });
}
