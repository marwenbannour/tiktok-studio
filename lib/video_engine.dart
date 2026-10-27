import 'package:flutter/services.dart';

/// واجهة محرّك الفيديو (Lot 2) — خلف platform channel (Media3 Transformer).
/// prototype: export فيديو مع نصّ محروق + قياس المدّة.
class VideoEngine {
  static const _ch = MethodChannel('studio/video_engine');

  /// export [input] لـ[output] (MP4)، مع [text] محروق اختياري، بأبعاد [width]×[height].
  /// يرجّع مدّة الـexport بالـms ومسار المخرج.
  static Future<({int ms, String output})> export({
    required String input,
    required String output,
    String text = '',
    int width = 1080,
    int height = 1920,
  }) async {
    final r = await _ch.invokeMapMethod<String, dynamic>('export', {
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
    final r = await _ch.invokeMapMethod<String, dynamic>('exportComposition', {
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
