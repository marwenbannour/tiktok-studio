import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// V22: نشر الفيديو لـTikTok — مباشر كان منصّب، وإلّا قائمة المشاركة متاع النظام.
class ShareVideo {
  static const _ch = MethodChannel('studio/video_engine');

  /// حزم TikTok (العالمية + بعض المناطق). نجرّبهم بالترتيب.
  static const tiktokPackages = [
    'com.zhiliaoapp.musically', // TikTok عالمي
    'com.ss.android.ugc.trill', // TikTok (مناطق أخرى)
  ];

  /// حزمة TikTok منصّبة؟ (أيّ وحدة).
  static Future<bool> isTikTokInstalled() async {
    for (final p in tiktokPackages) {
      try {
        if (await _ch.invokeMethod<bool>('isAppInstalled', {'package': p}) ?? false) {
          return true;
        }
      } on PlatformException {
        // نكمّلو
      } on MissingPluginException {
        return false;
      }
    }
    return false;
  }

  /// يبعث [path] لـTikTok مباشرة؛ كان ما نجّمش → قائمة المشاركة.
  /// يرجّع true كان تحلّ TikTok مباشرة.
  static Future<bool> toTikTok(String path, {String? subject}) async {
    for (final p in tiktokPackages) {
      try {
        final ok = await _ch.invokeMethod<bool>('shareToApp', {
          'path': path,
          'package': p,
          'mime': 'video/mp4',
        });
        if (ok == true) return true;
      } on PlatformException {
        // نجرّبو اللي بعدو ثمّ الـsheet
      } on MissingPluginException {
        break;
      }
    }
    await sheet(path, subject: subject);
    return false;
  }

  /// قائمة المشاركة متاع النظام (المستعمل يختار TikTok ولا غيرو).
  static Future<void> sheet(String path, {String? subject}) =>
      SharePlus.instance.share(ShareParams(
        files: [XFile(path, mimeType: 'video/mp4')],
        subject: subject,
      ));
}
