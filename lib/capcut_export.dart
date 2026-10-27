import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';

/// سطر ترجمة واحد (cue) بتوقيت بالـms.
class SrtCue {
  final int startMs;
  final int endMs;
  final String text;
  const SrtCue(this.startMs, this.endMs, this.text);

  int get durationMs => endMs - startMs;

  @override
  String toString() => 'SrtCue($startMs→$endMs, $text)';
}

/// كيفاش تبعث الفيديو لـCapCut.
enum CapCutSendResult {
  /// تحلّ CapCut مباشرة بالفيديو.
  openedCapCut,

  /// CapCut موش منصّب (ولا رفض الملف) → طلع menu المشاركة.
  openedShareSheet,
}

/// جسر لـCapCut: الـapp يجهّز الترجمة (SRT) وخطة المونتاج، ويبعث الفيديو
/// لـCapCut مباشرة، والمستعمل يكمّل المونتاج الاحترافي في CapCut.
///
/// قواعد الترجمة (معايير مهنية):
///  - الترجمة تتبع **الصوت** (اللي يتقال)، موش النصّ المكتوب على الشاشة؛
///    النصوص على الشاشة تخرج في ملف وحدها ([titlesSrt]).
///  - كل سطر ≤ [maxChars] حرف، مقصوص على الجمل ثم الكلمات.
///  - الوقت يتقسم على السطور حسب طولها، بدقّة الـms.
///  - الملف UTF-8 مع BOM، أسطر CRLF، و RLM قدّام الأسطر العربية
///    باش الكلمات اللاتينية (function, bug…) ما تتقلبش.
class CapCutExport {
  static const capCutPackage = 'com.lemon.lvoverseas';
  static const maxChars = 42;
  static const _minCueMs = 300;
  static const _bom = '\uFEFF';
  static const _rlm = '\u200F';
  static final _arabic = RegExp(r'[\u0600-\u06FF]');
  static const _ch = MethodChannel('studio/video_engine');

  // ---------------------------------------------------------------- timing

  /// 00:00:01,250
  static String timestamp(int ms) {
    if (ms < 0) ms = 0;
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    final r = ms % 1000;
    return '${two(h)}:${two(m)}:${two(s)},${r.toString().padLeft(3, '0')}';
  }

  /// 0:07 (للخطة)
  static String _clock(int sec) => '${sec ~/ 60}:${two(sec % 60)}';

  // ------------------------------------------------------------- splitting

  /// يقصّ نصّ لسطور ≤ [maxChars]: على الجمل والفواصل أوّلاً، بعد على الكلمات.
  /// الكلمة الأطول من [maxChars] تبقى وحدها (ما نقصّوش الكلمات).
  static List<String> splitCaption(String text, {int maxChars = maxChars}) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return const [];

    final phrases = RegExp(r'[^.!?؟،,;:…]+[.!?؟،,;:…]*')
        .allMatches(t)
        .map((m) => m.group(0)!.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (phrases.isEmpty) phrases.add(t);

    final out = <String>[];
    for (final p in phrases) {
      if (p.length <= maxChars) {
        out.add(p);
        continue;
      }
      var line = '';
      for (final w in p.split(' ')) {
        if (line.isEmpty) {
          line = w;
        } else if (line.length + 1 + w.length <= maxChars) {
          line = '$line $w';
        } else {
          out.add(line);
          line = w;
        }
      }
      if (line.isNotEmpty) out.add(line);
    }

    // ندمجو القطع الصغار جدّاً (كلمة ولا زوز) مع اللي قبلهم كان يساع
    final merged = <String>[];
    for (final c in out) {
      if (merged.isNotEmpty &&
          (c.length < 12 || merged.last.length < 12) &&
          merged.last.length + 1 + c.length <= maxChars) {
        merged[merged.length - 1] = '${merged.last} $c';
      } else {
        merged.add(c);
      }
    }
    return merged;
  }

  /// يقسّم [startMs, endMs] على [chunks] حسب عدد الحروف.
  static List<SrtCue> _distribute(int startMs, int endMs, List<String> chunks) {
    final weights = chunks.map((c) => math.max(1, c.replaceAll(' ', '').length)).toList();
    final total = weights.fold<int>(0, (a, b) => a + b);
    final span = endMs - startMs;
    final cues = <SrtCue>[];
    var acc = 0;
    var cursor = startMs;
    for (var i = 0; i < chunks.length; i++) {
      acc += weights[i];
      final end = i == chunks.length - 1 ? endMs : startMs + (span * acc / total).round();
      cues.add(SrtCue(cursor, end, chunks[i]));
      cursor = end;
    }
    return cues;
  }

  // ------------------------------------------------------------------ cues

  /// الترجمة: الصوت (ولا النصّ كان الصوت فارغ)، مقصوص وموقّت بالـms.
  /// الـsegments المتداخلين ولا المقلوبين يتصلّحو (ما فمّاش cues متداخلين).
  static List<SrtCue> subtitleCues(VideoScript v) {
    final cues = <SrtCue>[];
    var lastEnd = 0;
    for (final s in v.segments) {
      final txt = s.voice.trim().isNotEmpty ? s.voice : s.text;
      var start = s.from * 1000;
      final end = s.to * 1000;
      if (start < lastEnd) start = lastEnd;
      if (end - start < _minCueMs) continue;
      final chunks = splitCaption(txt);
      if (chunks.isEmpty) continue;
      cues.addAll(_distribute(start, end, chunks));
      lastEnd = end;
    }
    return cues;
  }

  /// النصوص المكتوبة على الشاشة (titres)، segment بـsegment.
  static List<SrtCue> titleCues(VideoScript v) {
    final cues = <SrtCue>[];
    var lastEnd = 0;
    for (final s in v.segments) {
      final txt = s.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      var start = s.from * 1000;
      final end = s.to * 1000;
      if (start < lastEnd) start = lastEnd;
      if (txt.isEmpty || end - start < _minCueMs) continue;
      cues.add(SrtCue(start, end, txt));
      lastEnd = end;
    }
    return cues;
  }

  /// يحوّل cues لملف SRT (BOM + CRLF + RLM للأسطر العربية).
  static String toSrt(List<SrtCue> cues) {
    final b = StringBuffer(_bom);
    for (var i = 0; i < cues.length; i++) {
      final c = cues[i];
      final line = _arabic.hasMatch(c.text) ? '$_rlm${c.text}' : c.text;
      b
        ..write('${i + 1}\r\n')
        ..write('${timestamp(c.startMs)} --> ${timestamp(c.endMs)}\r\n')
        ..write('$line\r\n');
      if (i < cues.length - 1) b.write('\r\n');
    }
    return b.toString();
  }

  /// ملف الترجمة (الصوت).
  static String srt(VideoScript v) => toSrt(subtitleCues(v));

  /// ملف النصوص على الشاشة.
  static String titlesSrt(VideoScript v) => toSrt(titleCues(v));

  /// الترجمة كنصّ عادي (سطر بسطر) — تتلصق في CapCut على التليفون.
  static String subtitlesPlainText(VideoScript v) =>
      subtitleCues(v).map((c) => c.text).join('\n');

  // ------------------------------------------------------------------ plan

  /// خطة المونتاج (shot list) — تتبعها في CapCut.
  static String plan(VideoScript v) {
    final b = StringBuffer();
    b.writeln('🎬 خطة المونتاج — ${v.title}');
    b.writeln('المدّة: ${v.duration}s · عمودي 9:16 · 1080×1920');
    b.writeln();
    b.writeln('— المشاهد —');
    for (final s in v.segments) {
      b.writeln('[${_clock(s.from)} → ${_clock(s.to)}] 🖥️ ${s.screen}');
      if (s.text.trim().isNotEmpty) b.writeln('   📝 نصّ على الشاشة: ${s.text.trim()}');
      if (s.voice.trim().isNotEmpty) b.writeln('   🎙️ الصوت: ${s.voice.trim()}');
      b.writeln();
    }
    if (v.code.trim().isNotEmpty) {
      b.writeln('💻 الكود (صوّرو على الشاشة):');
      b.writeln(v.code);
      b.writeln();
    }
    b.writeln('✍️ الوصف: ${v.caption}');
    if (v.hashtags.isNotEmpty) b.writeln('#️⃣ ${v.hashtags.join(' ')}');
    b.writeln();
    b.writeln('— المونتاج في CapCut —');
    b.writeln('1. ابعث الفيديو من التطبيق ← يتحلّ CapCut بمشروع جديد.');
    b.writeln('2. الترجمة على التليفون: Texte ← Sous-titres automatiques، وصلّح الكلمات بالنصّ المنسوخ.');
    b.writeln('   على الـPC: Texte ← Importer ← captions.srt (والنصوص على الشاشة: titres.srt).');
    b.writeln('3. قصّ كل 2–3 ثواني، zoom على الكود والمهمّ، صوت خفيف تحت الكلام.');
    b.writeln('4. صدّر 1080p · 30 fps ← انشر على TikTok (الصق الوصف والـhashtags).');
    return b.toString();
  }

  // ------------------------------------------------------------------- I/O

  static Future<File> _write(String name, String content) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/capcut');
    await dir.create(recursive: true);
    return File('${dir.path}/$name').writeAsString(content, flush: true);
  }

  static Future<void> copyPlan(VideoScript v) =>
      Clipboard.setData(ClipboardData(text: plan(v)));

  static Future<void> copySubtitles(VideoScript v) =>
      Clipboard.setData(ClipboardData(text: subtitlesPlainText(v)));

  static Future<void> sharePlan(VideoScript v) async {
    final f = await _write('montage_${v.createdAt}.txt', plan(v));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(f.path, name: 'montage.txt', mimeType: 'text/plain')],
      subject: 'خطة المونتاج — ${v.title}',
    ));
  }

  /// يشارك الزوز ملفات SRT مع بعضهم (الترجمة + النصوص على الشاشة).
  static Future<void> shareSubtitles(VideoScript v) async {
    final files = <XFile>[];
    final subs = await _write('captions_${v.createdAt}.srt', srt(v));
    files.add(XFile(subs.path, name: 'captions.srt', mimeType: 'application/x-subrip'));
    if (titleCues(v).isNotEmpty) {
      final titles = await _write('titres_${v.createdAt}.srt', titlesSrt(v));
      files.add(XFile(titles.path, name: 'titres.srt', mimeType: 'application/x-subrip'));
    }
    await SharePlus.instance.share(ShareParams(
      files: files,
      subject: 'captions — ${v.title}',
    ));
  }

  /// للتوافق مع الكود القديم.
  static Future<void> shareSrt(VideoScript v) => shareSubtitles(v);

  /// CapCut منصّب؟
  static Future<bool> isCapCutInstalled() async {
    try {
      return await _ch.invokeMethod<bool>('isAppInstalled', {'package': capCutPackage}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// يبعث الفيديو لـCapCut مباشرة؛ كان ما نجمش، يطلّع menu المشاركة.
  static Future<CapCutSendResult> sendVideoToCapCut(String path, {String? subject}) async {
    if (!await File(path).exists()) {
      throw FileSystemException('الفيديو موش موجود', path);
    }
    try {
      final ok = await _ch.invokeMethod<bool>('shareToApp', {
        'path': path,
        'package': capCutPackage,
        'mime': 'video/mp4',
      });
      if (ok == true) return CapCutSendResult.openedCapCut;
    } on PlatformException {
      // نكمّلو بالـshare sheet
    } on MissingPluginException {
      // نفس الشي
    }
    await shareVideo(path, subject: subject);
    return CapCutSendResult.openedShareSheet;
  }

  /// يشارك فيديو (menu المشاركة متاع النظام).
  static Future<void> shareVideo(String path, {String? subject}) =>
      SharePlus.instance.share(ShareParams(
        files: [XFile(path, mimeType: 'video/mp4')],
        subject: subject,
      ));
}
