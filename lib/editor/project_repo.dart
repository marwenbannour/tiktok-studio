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

  /// المدّة الظاهرة متاع clip = نافذة المصدر [inMs..outMs].
  static int clipDuration(Clip c) {
    final d = c.outMs - c.inMs;
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
    final startMs = videos.fold<int>(0, (acc, c) => acc + clipDuration(c));
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
      cursor += clipDuration(c);
    }
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
      cursor += clipDuration(v);
    }
    // المدّة = أقصى نهاية بين كل الـclips (فيديو + نصوص/ترجمة)
    var maxEnd = cursor;
    for (final c in clips) {
      if (c.track == 'video') continue;
      final end = c.startMs + clipDuration(c);
      if (end > maxEnd) maxEnd = end;
    }
    await d.touchProject(projectId, durationMs: maxEnd);
  }

  static Future<List<Project>> all({AppDatabase? db}) => _resolve(db).allProjects();
  static Future<Project?> byId(int id, {AppDatabase? db}) => _resolve(db).projectById(id);
  static Future<List<Clip>> clips(int id, {AppDatabase? db}) =>
      _resolve(db).projectClips(id);
  static Future<void> remove(int id, {AppDatabase? db}) => _resolve(db).removeProject(id);
}
