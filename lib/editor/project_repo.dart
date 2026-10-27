import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import '../models.dart';

/// منطق مشاريع الفيديو (Lot 2): إنشاء + assemblage auto من سكريبت.
class ProjectRepo {
  static AppDatabase get _db => AppDatabase.instance;

  static AppDatabase _resolve(AppDatabase? db) => db ?? _db;

  /// ينشئ projet من سكريبت ويعمل assemblage auto (نصوص + sous-titres).
  static Future<int> createFromScript(VideoScript script, {AppDatabase? db}) async {
    final d = _resolve(db);
    final pid = await d.createProject(ProjectsCompanion.insert(
      scriptId: Value(script.dbId),
      title: script.title,
      durationMs: Value(script.duration * 1000),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await autoAssemble(pid, script, db: d);
    return pid;
  }

  /// V03: يوزّع النصوص (text incrusté) والـsous-titres على الـtimeline
  /// حسب توقيت كل segment.
  static Future<void> autoAssemble(int projectId, VideoScript script,
      {AppDatabase? db}) async {
    final d = _resolve(db);
    final out = <ClipsCompanion>[];
    for (final s in script.segments) {
      final startMs = s.from * 1000;
      final durMs = (s.to - s.from) * 1000;
      // sous-titre = نصّ الصوت (ما يقولو)
      if (s.voice.trim().isNotEmpty) {
        out.add(ClipsCompanion.insert(
          projectId: projectId,
          track: 'subtitle',
          startMs: startMs,
          outMs: Value(durMs),
          zOrder: const Value(10),
          props: Value(jsonEncode({'text': s.voice.trim()})),
        ));
      }
      // texte incrusté = النصّ على الشاشة
      if (s.text.trim().isNotEmpty) {
        out.add(ClipsCompanion.insert(
          projectId: projectId,
          track: 'text',
          startMs: startMs,
          outMs: Value(durMs),
          zOrder: const Value(20),
          props: Value(jsonEncode({'text': s.text.trim()})),
        ));
      }
    }
    await d.replaceClips(projectId, out);
  }

  /// طول نافذة المصدر [inMs..outMs] (بلا اعتبار السرعة).
  static int clipDuration(Clip c) {
    final d = c.outMs - c.inMs;
    return d > 0 ? d : 0;
  }

  /// المدّة على الـtimeline = نافذة المصدر ÷ السرعة (V14).
  /// (speed=2 → نصف الوقت؛ speed=0.5 → ضعف الوقت). للـclips غير الفيديو speed=1.
  static int timelineDuration(Clip c) {
    final sp = c.speed <= 0 ? 1.0 : c.speed;
    final d = (clipDuration(c) / sp).round();
    return d > 0 ? d : 0;
  }

  /// V02: يزيد clip فيديو في آخر مسار الفيديو، ويحدّث مدّة المشروع.
  /// (منطق DB نقي — قابل للاختبار؛ نسخ الملف في [importMedia] منفصل.)
  static Future<void> addVideoClip({
    required int projectId,
    required String sourcePath,
    required int durationMs,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    final videos = (await d.projectClips(projectId)).where((c) => c.track == 'video');
    final startMs = videos.fold<int>(0, (acc, c) => acc + timelineDuration(c));
    await d.addClip(ClipsCompanion.insert(
      projectId: projectId,
      track: 'video',
      sourcePath: Value(sourcePath),
      startMs: startMs,
      outMs: Value(durationMs), // inMs=0 → المدّة = durationMs
    ));
    await _resequenceVideo(projectId, d);
  }

  /// ينسخ ملف media لمجلّد خاصّ بالمشروع، ويرجّع المسار الجديد. (I/O)
  static Future<String> importMedia(int projectId, String sourcePath) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/projects/$projectId');
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = '${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split('/').last}';
    final dest = File('${dir.path}/$name');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  /// V05: يحذف clip ويعاود يرتّب مسار الفيديو + يحدّث المدّة.
  static Future<void> deleteClip({
    required int projectId,
    required int clipId,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    await d.removeClip(clipId);
    await _resequenceVideo(projectId, d);
  }

  /// V05: يقصّ clip فيديو للمدّة الظاهرة [durationMs] (ضمن نافذة المصدر).
  static Future<void> trimVideoClip({
    required int projectId,
    required int clipId,
    required int durationMs,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    final c = (await d.projectClips(projectId)).firstWhere((x) => x.id == clipId);
    final safe = durationMs < 200 ? 200 : durationMs; // أدنى 0.2s
    await d.updateClip(clipId, ClipsCompanion(outMs: Value(c.inMs + safe)));
    await _resequenceVideo(projectId, d);
  }

  /// V05: يقسم clip فيديو عند [atMs] (إزاحة من بداية الـclip) لجوجة.
  static Future<void> splitVideoClip({
    required int projectId,
    required int clipId,
    required int atMs,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    final c = (await d.projectClips(projectId)).firstWhere((x) => x.id == clipId);
    final dur = clipDuration(c);
    if (atMs <= 100 || atMs >= dur - 100) return; // ماكانش قسمة معقولة
    final cut = c.inMs + atMs;
    // الجزء الأوّل = الـclip الأصلي (ينتهي عند القطع)
    await d.updateClip(clipId, ClipsCompanion(outMs: Value(cut)));
    // الجزء الثاني = clip جديد يكمّل نافذة المصدر
    await d.addClip(ClipsCompanion.insert(
      projectId: projectId,
      track: 'video',
      sourcePath: Value(c.sourcePath),
      startMs: c.startMs + atMs,
      inMs: Value(cut),
      outMs: Value(c.outMs),
      speed: Value(c.speed),
      zOrder: Value(c.zOrder),
      props: Value(c.props),
    ));
    await _resequenceVideo(projectId, d);
  }

  /// V05: يعيد ترتيب clips الفيديو حسب تسلسل [orderedIds] (drag & drop).
  static Future<void> reorderVideoClips({
    required int projectId,
    required List<int> orderedIds,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    final byId = {for (final c in await d.projectClips(projectId)) c.id: c};
    var cursor = 0;
    for (final id in orderedIds) {
      final c = byId[id];
      if (c == null || c.track != 'video') continue;
      await d.updateClip(id, ClipsCompanion(startMs: Value(cursor)));
      cursor += timelineDuration(c);
    }
    await _resequenceVideo(projectId, d);
  }

  /// V17: الفلاتر اللونية المتوفّرة (الاسم التقني → يتبعث للمحرّك).
  static const videoFilters = ['none', 'warm', 'cool', 'cinematic', 'bw'];

  /// فلتر clip فيديو (props['filter'])، افتراضي 'none'.
  static String filterOf(Clip c) {
    try {
      final f = jsonDecode(c.props)['filter'];
      if (f is String && videoFilters.contains(f)) return f;
    } catch (_) {}
    return 'none';
  }

  /// يدمج مفاتيح فـprops JSON متاع clip (يحافظ على الباقي) + autosave.
  static Future<void> _mergeProps(
      AppDatabase d, int projectId, int clipId, Map<String, Object?> patch) async {
    final c = (await d.projectClips(projectId)).firstWhere((x) => x.id == clipId);
    Map<String, dynamic> p = {};
    try {
      p = jsonDecode(c.props) as Map<String, dynamic>;
    } catch (_) {}
    patch.forEach((k, v) => p[k] = v);
    await d.updateClip(clipId, ClipsCompanion(props: Value(jsonEncode(p))));
    await d.touchProject(projectId); // V20: autosave → آخر تعديل
  }

  /// V17: يحطّ فلتر لوني على clip فيديو (يحافظ على باقي props).
  static Future<void> setFilter({
    required int projectId,
    required int clipId,
    required String filter,
    AppDatabase? db,
  }) =>
      _mergeProps(_resolve(db), projectId, clipId,
          {'filter': videoFilters.contains(filter) ? filter : 'none'});

  /// V16: انتقالة dip-to-black على clip فيديو (fade-in/out للكحلة).
  static bool fadeOf(Clip c) {
    try {
      return jsonDecode(c.props)['fade'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setFade({
    required int projectId,
    required int clipId,
    required bool fade,
    AppDatabase? db,
  }) =>
      _mergeProps(_resolve(db), projectId, clipId, {'fade': fade});

  /// V18: شدّة الطمس (Gaussian blur sigma) لـclip فيديو. 0 = بلا طمس.
  static const blurPresets = [0.0, 5.0, 12.0, 20.0]; // بلا/خفيف/متوسّط/قوي

  static double blurOf(Clip c) {
    try {
      final b = jsonDecode(c.props)['blur'];
      if (b is num && b > 0) return b.toDouble();
    } catch (_) {}
    return 0.0;
  }

  static Future<void> setBlur({
    required int projectId,
    required int clipId,
    required double blur,
    AppDatabase? db,
  }) =>
      _mergeProps(_resolve(db), projectId, clipId, {'blur': blur < 0 ? 0.0 : blur});

  /// V14: يبدّل سرعة clip فيديو (0.25..4)، ويعاود يرتّب (المدّة تتبدّل).
  static Future<void> setSpeed({
    required int projectId,
    required int clipId,
    required double speed,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    final s = speed.clamp(0.25, 4.0);
    await d.updateClip(clipId, ClipsCompanion(speed: Value(s)));
    await _resequenceVideo(projectId, d);
  }

  /// يخلّي clips الفيديو ملصوقين بالترتيب (بلا فراغات) ويحدّث مدّة المشروع.
  static Future<void> _resequenceVideo(int projectId, AppDatabase d) async {
    final clips = await d.projectClips(projectId);
    final videos = clips.where((c) => c.track == 'video').toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));
    var cursor = 0;
    for (final v in videos) {
      if (v.startMs != cursor) {
        await d.updateClip(v.id, ClipsCompanion(startMs: Value(cursor)));
      }
      cursor += timelineDuration(v);
    }
    // المدّة = أقصى نهاية بين كل الـclips (فيديو + نصوص/ترجمة)
    var maxEnd = cursor;
    for (final c in clips) {
      if (c.track == 'video') continue;
      final end = c.startMs + timelineDuration(c);
      if (end > maxEnd) maxEnd = end;
    }
    await d.touchProject(projectId, durationMs: maxEnd);
  }

  /// حجم صوت الموسيقى الافتراضي تحت الـvoix off.
  static const double defaultMusicVolume = 0.35;

  /// V21/V11/V12: يبني payload الـexport من clips المشروع — نقي وقابل للاختبار.
  /// clips (فيديو) + overlays (نصّ/ترجمة موقّتين) + audio (voix off + موسيقى).
  static Future<
      ({
        List<Map<String, Object>> clips,
        List<Map<String, Object>> overlays,
        List<Map<String, Object>> audio,
      })> buildExportPlan(int projectId, {AppDatabase? db}) async {
    final all = await _resolve(db).projectClips(projectId);

    final clips = <Map<String, Object>>[];
    for (final c in all.where((c) => c.track == 'video' && c.sourcePath != null).toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs))) {
      clips.add({
        'path': c.sourcePath!,
        'inMs': c.inMs,
        'outMs': c.outMs > 0 ? c.outMs : c.inMs,
        'startMs': c.startMs,
        'speed': c.speed <= 0 ? 1.0 : c.speed,
        'timelineMs': timelineDuration(c), // المدّة على الـtimeline (بعد السرعة)
        'filter': filterOf(c), // V17: فلتر لوني
        'fade': fadeOf(c), // V16: dip-to-black
        'blur': blurOf(c), // V18: شدّة الطمس
      });
    }

    final overlays = <Map<String, Object>>[];
    for (final c in all.where((c) => c.track == 'text' || c.track == 'subtitle')) {
      final style = styleOf(c);
      final txt = (style['text'] as String).trim();
      if (txt.isEmpty) continue;
      overlays.add({
        'text': txt,
        'startMs': c.startMs,
        'endMs': c.startMs + timelineDuration(c),
        'kind': c.track, // 'text' فوق / 'subtitle' تحت
        'color': style['color'] as Object,
        'size': style['size'] as Object,
        'bold': style['bold'] as Object,
        'align': style['align'] as Object,
        if (style['bg'] != null) 'bg': style['bg'] as Object,
      });
    }

    final audio = <Map<String, Object>>[];
    for (final c in all.where((c) =>
        (c.track == 'voice' || c.track == 'music') && c.sourcePath != null)) {
      audio.add({
        'path': c.sourcePath!,
        'inMs': c.inMs,
        'outMs': c.outMs > 0 ? c.outMs : c.inMs,
        'startMs': c.startMs,
        'kind': c.track, // 'voice' | 'music'
        'volume': volumeOf(c),
      });
    }
    return (clips: clips, overlays: overlays, audio: audio);
  }

  /// حجم صوت clip (props['volume'])، مع افتراضي: voix off 1.0، موسيقى 0.35.
  static double volumeOf(Clip c) {
    try {
      final v = jsonDecode(c.props)['volume'];
      if (v is num) return v.toDouble();
    } catch (_) {}
    return c.track == 'music' ? defaultMusicVolume : 1.0;
  }

  /// V08: تنسيق النصّ لـclip (نصّ/ترجمة) مع قيم افتراضية حسب النوع.
  /// props JSON: {text, color(#RRGGBB), size(px), bold, align(center/right/left), bg}
  static Map<String, Object?> styleOf(Clip c) {
    Map<String, dynamic> p = {};
    try {
      p = jsonDecode(c.props) as Map<String, dynamic>;
    } catch (_) {}
    final isText = c.track == 'text';
    return {
      'text': (p['text'] as String?) ?? '',
      'color': (p['color'] as String?) ?? (isText ? '#FFEB3B' : '#FFFFFF'),
      'size': (p['size'] as num?)?.toInt() ?? (isText ? 64 : 48),
      'bold': (p['bold'] as bool?) ?? true,
      'align': (p['align'] as String?) ?? 'center',
      'bg': p['bg'] as String?, // null = بلا خلفية
    };
  }

  /// يحدّث تنسيق/نصّ clip (يكتب props JSON).
  static Future<void> updateStyle({
    required int projectId,
    required int clipId,
    required Map<String, Object?> style,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    final clean = <String, Object?>{};
    style.forEach((k, v) {
      if (v != null) clean[k] = v;
    });
    await d.updateClip(clipId, ClipsCompanion(props: Value(jsonEncode(clean))));
    await d.touchProject(projectId); // V20: autosave
  }

  /// V11: يزيد clip voix off — يُلحَق ورا آخر تسجيل صوت (متسلسل).
  static Future<void> addVoiceClip({
    required int projectId,
    required String sourcePath,
    required int durationMs,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    final voices = (await d.projectClips(projectId)).where((c) => c.track == 'voice');
    final startMs = voices.fold<int>(0, (acc, c) => acc + clipDuration(c));
    await d.addClip(ClipsCompanion.insert(
      projectId: projectId,
      track: 'voice',
      sourcePath: Value(sourcePath),
      startMs: startMs,
      outMs: Value(durationMs),
      props: Value(jsonEncode({'volume': 1.0})),
    ));
    await touchDuration(projectId, db: d);
  }

  /// V12: يحطّ clip موسيقى خلفية يبدا من 0 (يبدّل الموجودة — موسيقى وحدة).
  static Future<void> setMusic({
    required int projectId,
    required String sourcePath,
    required int durationMs,
    double volume = defaultMusicVolume,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    for (final m in (await d.projectClips(projectId)).where((c) => c.track == 'music')) {
      await d.removeClip(m.id);
    }
    await d.addClip(ClipsCompanion.insert(
      projectId: projectId,
      track: 'music',
      sourcePath: Value(sourcePath),
      startMs: 0,
      outMs: Value(durationMs),
      props: Value(jsonEncode({'volume': volume})),
    ));
    await touchDuration(projectId, db: d);
  }

  /// يحدّث حجم صوت clip (voix off / موسيقى).
  static Future<void> setVolume({
    required int projectId,
    required int clipId,
    required double volume,
    AppDatabase? db,
  }) async {
    final d = _resolve(db);
    await d.updateClip(clipId, ClipsCompanion(props: Value(jsonEncode({'volume': volume}))));
    await d.touchProject(projectId); // V20: autosave
  }

  /// يعيد حساب مدّة المشروع من أقصى نهاية clip.
  static Future<void> touchDuration(int projectId, {AppDatabase? db}) async {
    final d = _resolve(db);
    var maxEnd = 0;
    for (final c in await d.projectClips(projectId)) {
      final end = c.startMs + timelineDuration(c);
      if (end > maxEnd) maxEnd = end;
    }
    await d.touchProject(projectId, durationMs: maxEnd);
  }

  /// يسجّل مسار آخر export فالمشروع.
  static Future<void> markExported(int projectId, String path, {AppDatabase? db}) =>
      _resolve(db).touchProject(projectId, exportedPath: path);

  static Future<List<Project>> all({AppDatabase? db}) => _resolve(db).allProjects();
  static Future<Project?> byId(int id, {AppDatabase? db}) => _resolve(db).projectById(id);
  static Future<List<Clip>> clips(int id, {AppDatabase? db}) =>
      _resolve(db).projectClips(id);
  static Future<void> remove(int id, {AppDatabase? db}) => _resolve(db).removeProject(id);
}
