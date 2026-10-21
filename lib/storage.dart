import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/database.dart';
import 'models.dart';

class AppStorage {
  // resetOnError: إذا المفتاح المشفّر ما عادش يتقرا (keystore تبدّل بعد réinstallation)،
  // يتفسخ عوض ما الـapp تطيح؛ المستعمل يعاود يحطّو.
  static const _secure = FlutterSecureStorage(aOptions: AndroidOptions(resetOnError: true));
  static const _keyName = 'anthropic_api_key';
  static const _modelName = 'model';
  static const _historyName = 'history_v1';

  /// موديلات Ollama Cloud (بلا suffix -cloud للـAPI؛ تنجم تكتب موديل آخر من ollama.com/search?c=cloud)
  static const models = <String, String>{
    'gemma4:31b': 'Gemma 4 · 🆓 مجّاني (free plan)',
    'gpt-oss:20b': 'GPT-OSS 20B · أسرع (يحتاج plan مدفوع)',
    'gpt-oss:120b': 'GPT-OSS 120B · أقوى (يحتاج plan مدفوع)',
    'qwen3-coder:480b': 'Qwen3 Coder · للكود (يحتاج plan مدفوع)',
    'deepseek-v3.1:671b': 'DeepSeek V3.1 · قوي (يحتاج plan مدفوع)',
  };
  static const defaultModel = 'gemma4:31b';

  // ---- المفتاح (محفوظ بطريقة مشفّرة على التليفون) ----
  static Future<String?> getApiKey() async {
    try {
      return await _secure.read(key: _keyName);
    } catch (e) {
      debugPrint('getApiKey: $e');
      await _secure.deleteAll().catchError((_) {});
      return null;
    }
  }
  static Future<void> setApiKey(String k) => _secure.write(key: _keyName, value: k);
  static Future<void> deleteApiKey() => _secure.delete(key: _keyName);

  // ---- السيرفر الوسيط (backend) — يخبّي المفتاح في السيرفر ----
  // العنوان موش سرّي (prefs)؛ الـtoken سرّي (مشفّر كيما المفتاح).
  static const _backendUrlName = 'backend_url';
  static const _appTokenName = 'app_token';

  static Future<String?> getBackendUrl() async {
    final p = await SharedPreferences.getInstance();
    final u = p.getString(_backendUrlName)?.trim();
    return (u == null || u.isEmpty) ? null : u;
  }

  static Future<void> setBackendUrl(String? url) async {
    final p = await SharedPreferences.getInstance();
    final u = url?.trim() ?? '';
    if (u.isEmpty) {
      await p.remove(_backendUrlName);
    } else {
      await p.setString(_backendUrlName, u);
    }
  }

  static Future<String?> getAppToken() async {
    try {
      return await _secure.read(key: _appTokenName);
    } catch (e) {
      debugPrint('getAppToken: $e');
      return null;
    }
  }

  static Future<void> setAppToken(String? t) async {
    final v = t?.trim() ?? '';
    if (v.isEmpty) {
      await _secure.delete(key: _appTokenName);
    } else {
      await _secure.write(key: _appTokenName, value: v);
    }
  }

  // ---- حساب Supabase (Auth + مزامنة) ----
  // URL + anon key موش سرّيين (public، RLS يحمي البيانات) → prefs.
  // الـsession (tokens) سرّية → مشفّرة.
  static const _supaUrlName = 'supabase_url';
  static const _supaAnonName = 'supabase_anon';
  static const _sessionName = 'supabase_session';
  static const _googleIdName = 'google_web_client_id';

  // Google Web Client ID (عمومي، موش سرّي) — يلزمو google_sign_in باش يجيب id_token
  static Future<String?> getGoogleClientId() async {
    final p = await SharedPreferences.getInstance();
    final c = p.getString(_googleIdName)?.trim();
    return (c == null || c.isEmpty) ? null : c;
  }

  static Future<void> setGoogleClientId(String? id) async {
    final p = await SharedPreferences.getInstance();
    final v = id?.trim() ?? '';
    v.isEmpty ? await p.remove(_googleIdName) : await p.setString(_googleIdName, v);
  }

  static Future<String?> getSupabaseUrl() async {
    final p = await SharedPreferences.getInstance();
    final u = p.getString(_supaUrlName)?.trim();
    return (u == null || u.isEmpty) ? null : u;
  }

  static Future<String?> getSupabaseAnonKey() async {
    final p = await SharedPreferences.getInstance();
    final k = p.getString(_supaAnonName)?.trim();
    return (k == null || k.isEmpty) ? null : k;
  }

  static Future<void> setSupabaseConfig(String? url, String? anon) async {
    final p = await SharedPreferences.getInstance();
    final u = url?.trim() ?? '', a = anon?.trim() ?? '';
    u.isEmpty ? await p.remove(_supaUrlName) : await p.setString(_supaUrlName, u);
    a.isEmpty ? await p.remove(_supaAnonName) : await p.setString(_supaAnonName, a);
  }

  /// الـsession محفوظة (JSON: access_token, refresh_token, user_id, email) ولا null
  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final raw = await _secure.read(key: _sessionName);
      if (raw == null || raw.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (e) {
      debugPrint('getSession: $e');
      return null;
    }
  }

  static Future<void> setSession(Map<String, dynamic>? session) async {
    if (session == null) {
      await _secure.delete(key: _sessionName);
    } else {
      await _secure.write(key: _sessionName, value: jsonEncode(session));
    }
  }

  // ---- الموديل ----
  static Future<String> getModel() async {
    final p = await SharedPreferences.getInstance();
    var m = p.getString(_modelName) ?? defaultModel;
    // إصلاح: الـcloud المباشر ما يقبلش suffix -cloud (كان يرجّع 410)
    if (m.endsWith('-cloud')) m = m.substring(0, m.length - 6);
    return m;
  }

  static Future<void> setModel(String m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_modelName, m);
  }

  // ---- الحدّ الشهري للتوليد (F20) ----
  static const _capName = 'gen_cap';
  static const _countName = 'gen_count';
  static const _monthName = 'gen_month';

  static String _thisMonth() {
    final n = DateTime.now();
    return '${n.year}-${two(n.month)}';
  }

  /// الحدّ الشهري (0 = بلا حدّ)
  static Future<int> getGenCap() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_capName) ?? 0;
  }

  static Future<void> setGenCap(int cap) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_capName, cap < 0 ? 0 : cap);
  }

  /// عدد التوليدات هالشهر (يرجع 0 كي يتبدّل الشهر)
  static Future<int> genCount() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_monthName) == _thisMonth() ? (p.getInt(_countName) ?? 0) : 0;
  }

  static Future<int> incrementGenCount() async {
    final p = await SharedPreferences.getInstance();
    final month = _thisMonth();
    final count = (p.getString(_monthName) == month ? (p.getInt(_countName) ?? 0) : 0) + 1;
    await p.setString(_monthName, month);
    await p.setInt(_countName, count);
    return count;
  }

  // ---- المحفوظات (SQLite / drift — بلا حدّ، مع بحث وفلترة) ----
  static AppDatabase get _db => AppDatabase.instance;

  static VideoScript _toScript(Script r) {
    final j = jsonDecode(r.content) as Map<String, dynamic>;
    return VideoScript.fromJson({
      ...j,
      'category': r.category,
      'style': r.style,
      'duration': r.duration,
      'createdAt': r.createdAt,
    }).copyWith(
      dbId: r.id,
      isFavorite: r.isFavorite,
      publishedAt: r.publishedAt,
      setStats: true,
      views: r.views,
      likes: r.likes,
      comments: r.comments,
      seriesTitle: r.seriesTitle,
      episode: r.episode,
    );
  }

  /// بحث + فلترة حسب النوع + مفضّلة برك (F21, F22, F23)
  static Future<List<VideoScript>> searchScripts({
    String query = '',
    String? category,
    bool favoritesOnly = false,
  }) async {
    await _migrateOldHistory();
    final rows = await _db.search(query: query, category: category, favoritesOnly: favoritesOnly);
    return rows.map(_toScript).toList();
  }

  static Future<int> scriptCount() => _db.total();

  /// يسجّل سكريبت جديد ويرجّعو مع الـdbId (F16 — بلا حدّ)
  static Future<VideoScript> saveScript(VideoScript s) async {
    await _migrateOldHistory();
    final model = await getModel();
    final id = await _db.add(ScriptsCompanion.insert(
      title: s.title,
      category: s.category,
      style: s.style,
      duration: s.duration,
      content: jsonEncode(s.toJson()),
      createdAt: s.createdAt,
      model: Value(model),
      seriesTitle: Value(s.seriesTitle),
      episode: Value(s.episode),
    ));
    return s.copyWith(dbId: id);
  }

  static Future<void> deleteScript(int dbId) => _db.remove(dbId);

  static Future<void> updateScript(VideoScript s) async {
    if (s.dbId == null) return;
    await _db.updateContent(s.dbId!, s.title, jsonEncode(s.toJson()));
  }

  static Future<void> setFavorite(int dbId, bool fav) => _db.setFavorite(dbId, fav);

  static Future<void> setPublished(int dbId, int? ts) => _db.setPublished(dbId, ts);

  // ---- إحصائيات الفيديو (V2) ----
  static Future<void> setStats(int dbId, int? views, int? likes, int? comments) =>
      _db.setStats(dbId, views, likes, comments);

  /// النوع اللي يخدم أكثر (لتوجيه المواضيع الجاية)
  static Future<({String category, double avgViews, int count})?> bestCategory() =>
      _db.bestCategory();

  // ---- لوحة الإحصائيات (V2) ----
  static Future<({int published, int views, int likes, int comments})> globalStats() =>
      _db.globalStats();
  static Future<List<({String category, int count, double avgViews})>> categoryStats() =>
      _db.categoryStats();
  static Future<List<VideoScript>> topByViews(int limit) async =>
      (await _db.topByViews(limit)).map(_toScript).toList();

  // ---- السلاسل (V2) ----
  static Future<List<String>> seriesTitles() => _db.seriesTitles();
  static Future<int> nextEpisode(String title) => _db.nextEpisode(title);
  static Future<List<VideoScript>> seriesEpisodes(String title) async =>
      (await _db.seriesEpisodes(title)).map(_toScript).toList();

  static Future<VideoScript?> findScript(int createdAt) async {
    final r = await _db.byCreatedAt(createdAt);
    return r == null ? null : _toScript(r);
  }

  /// ترحيل المحفوظات القديمة (SharedPreferences) للقاعدة، مرّة وحدة
  static bool _migrated = false;
  static Future<void> _migrateOldHistory() async {
    if (_migrated) return;
    _migrated = true;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_historyName);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => VideoScript.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      for (final s in list.reversed) {
        if (await _db.byCreatedAt(s.createdAt) != null) continue;
        await _db.add(ScriptsCompanion.insert(
          title: s.title,
          category: s.category,
          style: s.style,
          duration: s.duration,
          content: jsonEncode(s.toJson()),
          createdAt: s.createdAt,
        ));
      }
    } catch (e) {
      debugPrint('migrate history: $e');
    }
    await p.remove(_historyName);
  }

  // ---- البرنامج ----
  static const _plansName = 'plans_v1';

  static Future<List<PlannedVideo>> loadPlans() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_plansName);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PlannedVideo.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writePlans(List<PlannedVideo> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_plansName, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> savePlan(PlannedVideo plan) async {
    final list = await loadPlans();
    final i = list.indexWhere((e) => e.id == plan.id);
    i < 0 ? list.add(plan) : list[i] = plan;
    await _writePlans(list);
  }

  static Future<void> deletePlan(int id) async {
    final list = await loadPlans()..removeWhere((e) => e.id == id);
    await _writePlans(list);
  }
}
