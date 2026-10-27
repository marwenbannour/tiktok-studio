import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_studio/share_video.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('studio/video_engine');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(ch, null));

  test('isTikTokInstalled: يلوّج على حزم TikTok', () async {
    final asked = <String>[];
    messenger.setMockMethodCallHandler(ch, (call) async {
      if (call.method == 'isAppInstalled') {
        final p = (call.arguments as Map)['package'] as String;
        asked.add(p);
        return p == 'com.ss.android.ugc.trill'; // الثانية منصّبة
      }
      return null;
    });
    expect(await ShareVideo.isTikTokInstalled(), isTrue);
    expect(asked.first, 'com.zhiliaoapp.musically'); // يبدا بالعالمية
  });

  test('toTikTok: يبعث مباشرة كان shareToApp نجح (ما يوصلش للـsheet)', () async {
    MethodCall? sent;
    messenger.setMockMethodCallHandler(ch, (call) async {
      if (call.method == 'shareToApp') {
        sent = call;
        return true; // تحلّ TikTok مباشرة
      }
      return null;
    });
    final opened = await ShareVideo.toTikTok('/x.mp4');
    expect(opened, isTrue);
    expect((sent!.arguments as Map)['package'], 'com.zhiliaoapp.musically');
    expect((sent!.arguments as Map)['mime'], 'video/mp4');
  });
}
