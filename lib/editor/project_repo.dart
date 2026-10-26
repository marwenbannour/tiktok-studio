import 'dart:convert';

import 'package:drift/drift.dart';

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

  static Future<List<Project>> all({AppDatabase? db}) => _resolve(db).allProjects();
  static Future<Project?> byId(int id, {AppDatabase? db}) => _resolve(db).projectById(id);
  static Future<List<Clip>> clips(int id, {AppDatabase? db}) =>
      _resolve(db).projectClips(id);
  static Future<void> remove(int id, {AppDatabase? db}) => _resolve(db).removeProject(id);
}
