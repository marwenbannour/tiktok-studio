import 'dart:convert';

import 'package:drift/drift.dart';

import 'db/database.dart';

/// نسخة احتياطية محلّية: تصدير/استرجاع كل السكريبتات لملف JSON.
/// المنطق نقي (بلا I/O ولا plugins) باش يتختبر بسهولة.
class Backup {
  static const magic = 'studio_tiktok';
  static const formatVersion = 1;

  /// Script row → map (بلا id خاطر يتعاود بالـautoincrement وقت الاسترجاع)
  static Map<String, dynamic> rowToMap(Script s) => {
        'title': s.title,
        'category': s.category,
        'style': s.style,
        'duration': s.duration,
        'content': s.content,
        'model': s.model,
        'isFavorite': s.isFavorite,
        'publishedAt': s.publishedAt,
        'createdAt': s.createdAt,
        'views': s.views,
        'likes': s.likes,
        'comments': s.comments,
        'seriesTitle': s.seriesTitle,
        'episode': s.episode,
      };

  static ScriptsCompanion mapToCompanion(Map<String, dynamic> m) =>
      ScriptsCompanion.insert(
        title: m['title'] as String,
        category: m['category'] as String,
        style: m['style'] as String,
        duration: (m['duration'] as num).toInt(),
        content: m['content'] as String,
        model: Value(m['model'] as String? ?? ''),
        isFavorite: Value(m['isFavorite'] as bool? ?? false),
        publishedAt: Value((m['publishedAt'] as num?)?.toInt()),
        createdAt: (m['createdAt'] as num).toInt(),
        views: Value((m['views'] as num?)?.toInt()),
        likes: Value((m['likes'] as num?)?.toInt()),
        comments: Value((m['comments'] as num?)?.toInt()),
        seriesTitle: Value(m['seriesTitle'] as String?),
        episode: Value((m['episode'] as num?)?.toInt()),
      );

  /// يبني نصّ JSON من كل السكريبتات الموجودة
  static Future<String> exportJson({AppDatabase? db}) async {
    final d = db ?? AppDatabase.instance;
    final rows = await d.search(); // الكل، الأحدث أول
    final map = {
      'app': magic,
      'version': formatVersion,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'count': rows.length,
      'scripts': rows.map(rowToMap).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// يسترجع من نصّ JSON. يتخطّى اللي عندهم نفس createdAt (باش ما يتعاودوش).
  /// يرجّع عدد المضاف والمتخطّى. يرمي FormatException كان الملف موش صالح.
  static Future<({int added, int skipped})> importJson(String raw,
      {AppDatabase? db}) async {
    final d = db ?? AppDatabase.instance;
    final dynamic data;
    try {
      data = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('الملف موش JSON صالح');
    }
    if (data is! Map || data['app'] != magic || data['scripts'] is! List) {
      throw const FormatException('هذا موش ملف نسخة احتياطية تاع ستوديو التيكتوك');
    }
    var added = 0, skipped = 0;
    for (final item in (data['scripts'] as List)) {
      if (item is! Map) {
        skipped++;
        continue;
      }
      final m = item.cast<String, dynamic>();
      final created = (m['createdAt'] as num?)?.toInt();
      if (created != null && await d.byCreatedAt(created) != null) {
        skipped++; // موجود ديجا
        continue;
      }
      await d.add(mapToCompanion(m));
      added++;
    }
    return (added: added, skipped: skipped);
  }
}
