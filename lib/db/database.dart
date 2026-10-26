import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// جدول السكريبتات (section 8 متاع الـcahier des charges)
class Scripts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get style => text()();
  IntColumn get duration => integer()();

  /// JSON الكامل متاع VideoScript (segments, code, steps, caption, hashtags, tips)
  TextColumn get content => text()();
  TextColumn get model => text().withDefault(const Constant(''))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// وقت النشر على TikTok (null = ما تنشرش)
  IntColumn get publishedAt => integer().nullable()();
  IntColumn get createdAt => integer()();

  // ---- إحصائيات الفيديو (V2) — تتدخّل بيدّ المستعمل بعد النشر ----
  IntColumn get views => integer().nullable()();
  IntColumn get likes => integer().nullable()();
  IntColumn get comments => integer().nullable()();

  // ---- سلاسل الحلقات (V2) ----
  TextColumn get seriesTitle => text().nullable()();
  IntColumn get episode => integer().nullable()();
}

/// مشروع فيديو (Lot 2) — projet 9:16 مربوط بسكريبت (ولا فارغ)
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scriptId => integer().nullable()();
  TextColumn get title => text()();
  IntColumn get width => integer().withDefault(const Constant(1080))();
  IntColumn get height => integer().withDefault(const Constant(1920))();
  IntColumn get fps => integer().withDefault(const Constant(30))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get exportedPath => text().nullable()();
  IntColumn get updatedAt => integer()();
}

/// clip على الـtimeline: فيديو/overlay/نص/sous-titre/voix/musique
class Clips extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get track => text()(); // video, overlay, text, subtitle, voice, music
  TextColumn get sourcePath => text().nullable()(); // null للنصّ
  IntColumn get startMs => integer()(); // الموضع على الـtimeline
  IntColumn get inMs => integer().withDefault(const Constant(0))();
  IntColumn get outMs => integer().withDefault(const Constant(0))();
  RealColumn get speed => real().withDefault(const Constant(1.0))();
  IntColumn get zOrder => integer().withDefault(const Constant(0))();
  TextColumn get props => text().withDefault(const Constant('{}'))(); // JSON: text, style, animation...
}

@DriftDatabase(tables: [Scripts, Projects, Clips])
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.e);

  /// القاعدة المشتركة متاع الـapp (studio.db). قابلة للتبديل في الـtests.
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._(driftDatabase(name: 'studio'));
  static set instance(AppDatabase db) => _instance = db;

  /// للـtests (قاعدة في الذاكرة)
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(scripts, scripts.views);
            await m.addColumn(scripts, scripts.likes);
            await m.addColumn(scripts, scripts.comments);
          }
          if (from < 3) {
            await m.addColumn(scripts, scripts.seriesTitle);
            await m.addColumn(scripts, scripts.episode);
          }
          if (from < 4) {
            await m.createTable(projects);
            await m.createTable(clips);
          }
        },
      );

  // ---- كتابة ----
  Future<int> add(ScriptsCompanion c) => into(scripts).insert(c);

  Future<void> remove(int id) => (delete(scripts)..where((t) => t.id.equals(id))).go();

  Future<void> setFavorite(int id, bool fav) =>
      (update(scripts)..where((t) => t.id.equals(id))).write(ScriptsCompanion(isFavorite: Value(fav)));

  Future<void> setPublished(int id, int? ts) =>
      (update(scripts)..where((t) => t.id.equals(id))).write(ScriptsCompanion(publishedAt: Value(ts)));

  Future<void> updateContent(int id, String title, String content) =>
      (update(scripts)..where((t) => t.id.equals(id)))
          .write(ScriptsCompanion(title: Value(title), content: Value(content)));

  Future<void> setStats(int id, int? views, int? likes, int? comments) =>
      (update(scripts)..where((t) => t.id.equals(id))).write(ScriptsCompanion(
        views: Value(views),
        likes: Value(likes),
        comments: Value(comments),
      ));

  /// النوع اللي يخدم أكثر (أعلى متوسّط مشاهدات) من بين اللي عندهم إحصائيات
  Future<({String category, double avgViews, int count})?> bestCategory() async {
    final avg = scripts.views.avg();
    final cnt = scripts.id.count();
    final q = selectOnly(scripts)
      ..addColumns([scripts.category, avg, cnt])
      ..where(scripts.views.isNotNull())
      ..groupBy([scripts.category])
      ..orderBy([OrderingTerm.desc(avg)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    if (row == null) return null;
    final a = row.read(avg);
    final c = row.read(scripts.category);
    if (a == null || c == null) return null;
    return (category: c, avgViews: a, count: row.read(cnt) ?? 0);
  }

  // ---- قراية ----
  Future<Script?> byId(int id) =>
      (select(scripts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Script?> byCreatedAt(int createdAt) =>
      (select(scripts)..where((t) => t.createdAt.equals(createdAt))).getSingleOrNull();

  /// بحث + فلترة + ترتيب (F21, F22, F23). البحث بـLIKE: سريع (<200ms لـ1000 سكريبت)
  /// وصحيح مع الدارجة بالعربي.
  Future<List<Script>> search({
    String query = '',
    String? category,
    bool favoritesOnly = false,
  }) {
    final q = select(scripts)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (category != null) q.where((t) => t.category.equals(category));
    if (favoritesOnly) q.where((t) => t.isFavorite.equals(true));
    final term = query.trim();
    if (term.isNotEmpty) {
      final like = '%$term%';
      q.where((t) => t.title.like(like) | t.content.like(like));
    }
    return q.get();
  }

  // ---- السلاسل (V2) ----
  Future<List<String>> seriesTitles() async {
    final q = selectOnly(scripts, distinct: true)
      ..addColumns([scripts.seriesTitle])
      ..where(scripts.seriesTitle.isNotNull());
    final rows = await q.get();
    return rows.map((r) => r.read(scripts.seriesTitle)).whereType<String>().toList();
  }

  Future<List<Script>> seriesEpisodes(String title) => (select(scripts)
        ..where((t) => t.seriesTitle.equals(title))
        ..orderBy([(t) => OrderingTerm.asc(t.episode)]))
      .get();

  Future<int> nextEpisode(String title) async {
    final maxE = scripts.episode.max();
    final q = selectOnly(scripts)
      ..addColumns([maxE])
      ..where(scripts.seriesTitle.equals(title));
    final row = await q.getSingleOrNull();
    return (row?.read(maxE) ?? 0) + 1;
  }

  // ---- لوحة الإحصائيات (V2) ----
  /// مجاميع عامّة: المنشورين + مجموع المشاهدات/اللايكات/الكومنتات
  Future<({int published, int views, int likes, int comments})> globalStats() async {
    final v = scripts.views.sum();
    final l = scripts.likes.sum();
    final c = scripts.comments.sum();
    final sumRow = await (selectOnly(scripts)..addColumns([v, l, c])).getSingle();
    final pubCnt = scripts.id.count();
    final pubRow = await (selectOnly(scripts)
          ..addColumns([pubCnt])
          ..where(scripts.publishedAt.isNotNull()))
        .getSingle();
    return (
      published: pubRow.read(pubCnt) ?? 0,
      views: sumRow.read(v) ?? 0,
      likes: sumRow.read(l) ?? 0,
      comments: sumRow.read(c) ?? 0,
    );
  }

  /// عدد السكريبتات ومتوسّط المشاهدات حسب النوع
  Future<List<({String category, int count, double avgViews})>> categoryStats() async {
    final cnt = scripts.id.count();
    final avg = scripts.views.avg();
    final q = selectOnly(scripts)
      ..addColumns([scripts.category, cnt, avg])
      ..groupBy([scripts.category])
      ..orderBy([OrderingTerm.desc(avg), OrderingTerm.desc(cnt)]);
    final rows = await q.get();
    return rows
        .map((r) => (
              category: r.read(scripts.category) ?? '',
              count: r.read(cnt) ?? 0,
              avgViews: r.read(avg) ?? 0.0,
            ))
        .toList();
  }

  /// أحسن الفيديوهات (أعلى مشاهدات)
  Future<List<Script>> topByViews(int limit) => (select(scripts)
        ..where((t) => t.views.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.views)])
        ..limit(limit))
      .get();

  Future<int> total() async {
    final c = scripts.id.count();
    final row = await (selectOnly(scripts)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }

  // ---- مشاريع الفيديو والـclips (Lot 2) ----
  Future<int> createProject(ProjectsCompanion c) => into(projects).insert(c);

  Future<List<Project>> allProjects() =>
      (select(projects)..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])).get();

  Future<Project?> projectById(int id) =>
      (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<void> removeProject(int id) async {
    // صريح (ما نعتمدوش على PRAGMA foreign_keys)
    await (delete(clips)..where((c) => c.projectId.equals(id))).go();
    await (delete(projects)..where((p) => p.id.equals(id))).go();
  }

  Future<void> touchProject(int id, {int? durationMs, String? exportedPath}) =>
      (update(projects)..where((p) => p.id.equals(id))).write(ProjectsCompanion(
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        durationMs: durationMs == null ? const Value.absent() : Value(durationMs),
        exportedPath:
            exportedPath == null ? const Value.absent() : Value(exportedPath),
      ));

  Future<int> addClip(ClipsCompanion c) => into(clips).insert(c);

  Future<List<Clip>> projectClips(int projectId) => (select(clips)
        ..where((c) => c.projectId.equals(projectId))
        ..orderBy([(c) => OrderingTerm.asc(c.startMs), (c) => OrderingTerm.asc(c.zOrder)]))
      .get();

  Future<void> updateClip(int id, ClipsCompanion c) =>
      (update(clips)..where((cl) => cl.id.equals(id))).write(c);

  Future<void> removeClip(int id) => (delete(clips)..where((c) => c.id.equals(id))).go();

  /// يعاود يحطّ كل الـclips متاع مشروع (للـassemblage auto)
  Future<void> replaceClips(int projectId, List<ClipsCompanion> newClips) async {
    await batch((b) {
      b.deleteWhere(clips, (c) => c.projectId.equals(projectId));
      b.insertAll(clips, newClips);
    });
  }
}
