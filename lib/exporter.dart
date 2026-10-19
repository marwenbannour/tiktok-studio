import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';

/// مشاركة وتصدير السكريبت (WhatsApp، TikTok، Drive...)
class Exporter {
  static Future<void> shareText(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));

  static Future<void> shareScript(VideoScript s) => shareText(s.fullText(), subject: s.title);

  static Future<void> shareCaption(VideoScript s) => shareText(s.captionText());

  /// يكتب السكريبت في fichier .txt (يتنحّى من الـtemp وقت ما السيستام يحب)
  static Future<File> writeTxt(VideoScript s) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${fileName(s)}');
    return file.writeAsString(s.fullText());
  }

  static Future<void> shareTxt(VideoScript s) async {
    final f = await writeTxt(s);
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], subject: s.title));
  }

  /// اسم fichier نظيف: حروف (مع الشدّة والحركات) وأرقام برك + الوقت
  static String fileName(VideoScript s) {
    final clean = s.title
        .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final name = clean.isEmpty ? 'script' : clean;
    return '${name.length > 40 ? name.substring(0, 40) : name}_${s.createdAt}.txt';
  }
}
