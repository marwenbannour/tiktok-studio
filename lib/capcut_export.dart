import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';

/// جسر لـCapCut: الـapp يجهّز خطة المونتاج + captions (SRT) ويسلّمهم،
/// والمستخدم يعمل المونتاج الاحترافي في CapCut الحقيقي. بلا FFmpeg.
class CapCutExport {
  static String _ts(int sec) =>
      '${two(sec ~/ 3600)}:${two((sec % 3600) ~/ 60)}:${two(sec % 60)},000';

  /// ملف captions بصيغة SRT: نصّ كل segment مؤقّت (from → to).
  /// CapCut وأي محرّر ينجّم يستوردو كـsous-titres.
  static String srt(VideoScript v) {
    final b = StringBuffer();
    for (var i = 0; i < v.segments.length; i++) {
      final s = v.segments[i];
      final txt = s.text.trim().isEmpty ? s.voice.trim() : s.text.trim();
      b.writeln('${i + 1}');
      b.writeln('${_ts(s.from)} --> ${_ts(s.to)}');
      b.writeln(txt);
      b.writeln();
    }
    return b.toString().trimRight();
  }

  /// خطة المونتاج (shot list) — نصّ منظّم تتبعو في CapCut.
  static String plan(VideoScript v) {
    final b = StringBuffer();
    b.writeln('🎬 خطة المونتاج — ${v.title}');
    b.writeln('المدّة: ${v.duration}s · عمودي 9:16');
    b.writeln('');
    b.writeln('— المشاهد (segment بـsegment) —');
    for (final s in v.segments) {
      b.writeln('[${s.range}] 🖥️ ${s.screen}');
      if (s.text.trim().isNotEmpty) b.writeln('   📝 نصّ على الفيديو: ${s.text}');
      b.writeln('   🎙️ الصوت: ${s.voice}');
      b.writeln('');
    }
    if (v.code.trim().isNotEmpty) {
      b.writeln('💻 الكود (صوّرو على الشاشة):');
      b.writeln(v.code);
      b.writeln('');
    }
    b.writeln('✍️ الوصف: ${v.caption}');
    if (v.hashtags.isNotEmpty) b.writeln('#️⃣ ${v.hashtags.join(' ')}');
    b.writeln('');
    b.writeln('— كيفاش تكمّلو في CapCut —');
    b.writeln('1. افتح CapCut → مشروع جديد → استورد الفيديو اللي سجّلتو.');
    b.writeln('2. زيد نصّ على الفيديو كيما كل [وقت] فوق — ولا استورد ملف captions.srt.');
    b.writeln('3. cuts كل 2-3 ثواني + zoom على المهمّ + صوت trending خفيف.');
    b.writeln('4. صدّر 9:16 → انشر على TikTok (الصق الوصف + hashtags).');
    return b.toString();
  }

  // ---- I/O ----
  static Future<void> copyPlan(VideoScript v) =>
      Clipboard.setData(ClipboardData(text: plan(v)));

  static Future<File> _write(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$name');
    return f.writeAsString(content);
  }

  static Future<void> sharePlan(VideoScript v) async {
    final f = await _write('montage_${v.createdAt}.txt', plan(v));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(f.path, name: 'montage.txt')],
      subject: 'خطة المونتاج — ${v.title}',
    ));
  }

  static Future<void> shareSrt(VideoScript v) async {
    final f = await _write('captions_${v.createdAt}.srt', srt(v));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(f.path, name: 'captions.srt')],
      subject: 'captions — ${v.title}',
    ));
  }

  /// يشارك فيديو مسجّل (يطلع ورقة المشاركة → تختار CapCut)
  static Future<void> shareVideo(String path, {String? subject}) =>
      SharePlus.instance.share(ShareParams(
        files: [XFile(path, mimeType: 'video/mp4')],
        subject: subject,
      ));
}
