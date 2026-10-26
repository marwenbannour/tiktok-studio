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
    final startMs = videos.fold<int>(0, (acc, c) => acc + (c.outMs > 0 ? c.outMs : 0));
    await d.addClip(ClipsCompanion.insert(
      projectId: projectId,
      track: 'video',
      sourcePath: Value(sourcePath),
      startMs: startMs,
      outMs: Value(durationMs),
    ));
    final p = await d.projectById(projectId);
    final newDur = (startMs + durationMs) > (p?.durationMs ?? 0)
        ? (startMs + durationMs)
        : (p?.durationMs ?? 0);
    await d.touchProject(projectId, durationMs: newDur);
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

  static Future<List<Project>> all({AppDatabase? db}) => _resolve(db).allProjects();
  static Future<Project?> byId(int id, {AppDatabase? db}) => _resolve(db).projectById(id);
  static Future<List<Clip>> clips(int id, {AppDatabase? db}) =>
      _resolve(db).projectClips(id);
  static Future<void> remove(int id, {AppDatabase? db}) => _resolve(db).removeProject(id);
}
