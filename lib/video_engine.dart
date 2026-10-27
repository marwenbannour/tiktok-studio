import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// واجهة محرّك الفيديو (Lot 2) — خلف platform channel (Media3 Transformer).
/// prototype: export فيديو مع نصّ محروق + قياس المدّة.
class VideoEngine {
  static const _ch = MethodChannel('studio/video_engine');

  /// تقدّم الـexport الجاري (0.0–1.0)، null كان ما فمّا حتى export.
  static final ValueNotifier<double?> progress = ValueNotifier<double?>(null);
  static bool _listening = false;

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'exportProgress') {
        final p = call.arguments;
        if (p is num) progress.value = (p / 100).clamp(0.0, 1.0).toDouble();
      }
    });
  }

  /// يلغي الـexport الجاري (الـFuture متاعو يطيح بـPlatformException 'cancelled').
  static Future<void> cancelExport() => _ch.invokeMethod<void>('cancelExport');

  /// الخطأ هذا جا من إلغاء المستعمل؟
  static bool isCancelled(Object e) => e is PlatformException && e.code == 'cancelled';

  static Future<Map<String, dynamic>?> _tracked(String method, Map<String, Object> args) async {
    _listen();
    progress.value = 0;
    try {
      return await _ch.invokeMapMethod<String, dynamic>(method, args);
    } finally {
      progress.value = null;
    }
  }

  /// export [input] لـ[output] (MP4)، مع [text] محروق اختياري، بأبعاد [width]×[height].
  /// يرجّع مدّة الـexport بالـms ومسار المخرج.
  static Future<({int ms, String output})> export({
    required String input,
    required String output,
    String text = '',
    int width = 1080,
    int height = 1920,
  }) async {
    final r = await _tracked('export', {
      'input': input,
      'output': output,
      'text': text,
      'width': width,
      'height': height,
    });
    return (
      ms: (r?['ms'] as num?)?.toInt() ?? 0,
      output: (r?['output'] as String?) ?? output,
    );
  }

  /// V21: export مشروع كامل — يدمج [clips] (فيديوهات) ويحرق [overlays]
  /// (نصوص/ترجمة موقّتة) على الـtimeline العامّ.
  ///
  /// clips: {path, inMs, outMs, startMs}  ·  overlays: {text, startMs, endMs, kind}
  /// (kind: 'subtitle' تحت / 'text' فوق).
  static Future<({int ms, String output})> exportComposition({
    required List<Map<String, Object>> clips,
    required List<Map<String, Object>> overlays,
    List<Map<String, Object>> audio = const [],
    required String output,
    int width = 1080,
    int height = 1920,
  }) async {
    final r = await _tracked('exportComposition', {
      'clips': clips,
      'overlays': overlays,
      'audio': audio,
      'output': output,
      'width': width,
      'height': height,
    });
    return (
      ms: (r?['ms'] as num?)?.toInt() ?? 0,
      output: (r?['output'] as String?) ?? output,
    );
  }

  /// مدّة ملف صوت/فيديو بالـms (MediaMetadataRetriever).
  static Future<int> probeDuration(String path) async {
    final ms = await _ch.invokeMethod<int>('probeDuration', {'path': path});
    return ms ?? 0;
  }

  /// معلومات فيديو: {width, height, durationMs, hasAudio, hasVideo}.
  static Future<Map<String, dynamic>> probeInfo(String path) async {
    final r = await _ch.invokeMapMethod<String, dynamic>('probeInfo', {'path': path});
    return r ?? {};
  }

  /// V12: يفتح منتقي صوت النظام؛ يرجّع مسار نسخة مؤقّتة، ولا null إذا ألغى.
  static Future<String?> pickAudio() =>
      _ch.invokeMethod<String>('pickAudio');
}
