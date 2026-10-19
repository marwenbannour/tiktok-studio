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

@DriftDatabase(tables: [Scripts])
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.e);

  /// القاعدة المشتركة متاع الـapp (studio.db). قابلة للتبديل في الـtests.
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._(driftDatabase(name: 'studio'));
  static set instance(AppDatabase db) => _instance = db;

  /// للـtests (قاعدة في الذاكرة)
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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

  Future<int> total() async {
    final c = scripts.id.count();
    final row = await (selectOnly(scripts)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
