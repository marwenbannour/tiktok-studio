import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup.dart';

/// غلاف I/O للنسخة الاحتياطية: كتابة ملف ومشاركته / قراءة من الحافظة.
/// منفصل على [Backup] (المنطق النقي) باش الأخير يبقى قابل للاختبار بلا plugins.
///
/// الاسترجاع يمشي عبر الحافظة (presse-papiers) باش نتجنّبو file_picker اللي
/// يجرّ تعارض نسخ (win32) مع flutter_secure_storage/share_plus.
class BackupIO {
  static String _two(int n) => n.toString().padLeft(2, '0');

  /// يصدّر كل السكريبتات لملف JSON، يحطّو في الحافظة، ويفتح ورقة المشاركة.
  /// يرجّع عدد السكريبتات اللي تصدّرو.
  static Future<int> exportAndShare() async {
    final json = await Backup.exportJson();
    final count = (jsonDecode(json) as Map)['count'] as int? ?? 0;

    // نسخة في الحافظة (باش المستخدم ينجّم يلصقها كي يسترجع)
    await Clipboard.setData(ClipboardData(text: json));

    final dir = await getTemporaryDirectory();
    final d = DateTime.now();
    final name =
        'studio_backup_${d.year}${_two(d.month)}${_two(d.day)}_${_two(d.hour)}${_two(d.minute)}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(json);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/json', name: name)],
      subject: 'نسخة احتياطية — ستوديو التيكتوك',
    ));
    return count;
  }

  /// يسترجع من نصّ JSON موجود في الحافظة (presse-papiers).
  /// يرجّع (added, skipped)، ولا null كان الحافظة فارغة.
  static Future<({int added, int skipped})?> importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim() ?? '';
    if (raw.isEmpty) return null;
    return Backup.importJson(raw);
  }
}
