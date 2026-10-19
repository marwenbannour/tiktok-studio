import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ---- المحفوظات ----
  static Future<List<VideoScript>> loadHistory() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_historyName);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => VideoScript.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(List<VideoScript> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_historyName, jsonEncode(list.map((s) => s.toJson()).toList()));
  }

  static Future<void> saveScript(VideoScript s) async {
    final list = await loadHistory();
    list.insert(0, s);
    await _write(list.take(30).toList());
  }

  static Future<void> deleteAt(int index) async {
    final list = await loadHistory();
    if (index >= 0 && index < list.length) list.removeAt(index);
    await _write(list);
  }

  /// يبدّل السكريبت اللي عندو نفس الـcreatedAt (بعد التعديل)
  static Future<void> updateScript(VideoScript s) async {
    final list = await loadHistory();
    final i = list.indexWhere((e) => e.createdAt == s.createdAt);
    if (i < 0) return;
    list[i] = s;
    await _write(list);
  }

  static Future<VideoScript?> findScript(int createdAt) async {
    for (final s in await loadHistory()) {
      if (s.createdAt == createdAt) return s;
    }
    return null;
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
