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
}
