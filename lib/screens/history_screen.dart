import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // النوع → تسمية قصيرة للفلترة (F23)
  static const _cats = <String, String>{
    'Dev AI': '🤖 Dev AI',
    'Football': '⚽ Football',
    'معلومات وحقائق': '🧠 معلومات',
    'ضحك وحكايات تونسية': '😂 ضحك',
  };

  final _searchCtrl = TextEditingController();
  List<VideoScript> _items = [];
  bool _loading = true;
  String _query = '';
  String? _category;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    List<VideoScript> list = [];
    try {
      list = await AppStorage.searchScripts(
        query: _query,
        category: _category,
        favoritesOnly: _favoritesOnly,
      );
    } catch (e) {
      debugPrint('history load: $e');
    }
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  Future<void> _delete(VideoScript s) async {
    if (s.dbId != null) await AppStorage.deleteScript(s.dbId!);
    await _load();
  }

  Future<void> _toggleFav(VideoScript s) async {
    if (s.dbId == null) return;
    await AppStorage.setFavorite(s.dbId!, !s.isFavorite);
    await _load();
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  Widget _filters() {
    Widget chip(String label, bool sel, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: sel,
            labelStyle: TextStyle(
              color: sel ? AppColors.night : AppColors.textMid,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => onTap(),
          ),
        );
    // SingleChildScrollView+Row: كل الـchips تتبنى ديما (ما يتفسخوش كي نسكرولو)
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            chip('⭐ المفضّلة', _favoritesOnly, () {
              setState(() => _favoritesOnly = !_favoritesOnly);
              _load();
            }),
            Container(
                width: 1,
                height: 24,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 4)),
            chip('الكل', _category == null, () {
              setState(() => _category = null);
              _load();
            }),
            for (final e in _cats.entries)
              chip(e.value, _category == e.key, () {
                setState(() => _category = e.key);
                _load();
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('السكريبتات المحفوظة')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _query = v;
                _load();
              },
              decoration: InputDecoration(
                hintText: 'لوّج على سكريبت…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          _query = '';
                          _load();
                        },
                      ),
                isDense: true,
              ),
            ),
          ),
          _filters(),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _query.isNotEmpty || _category != null || _favoritesOnly
                                ? 'ما فماش نتيجة. بدّل البحث ولا الفلتر.'
                                : 'ما عندك حتى سكريبت. حضّر أول فيديو من «حضّر» 🎬',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = _items[i];
                          return ListTile(
                            title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Row(
                              children: [
                                Flexible(
                                  child: Text('${s.category} – ${s.duration}s – ${_date(s.createdAt)}',
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                if (s.publishedAt != null)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Text('✅ تنشر', style: TextStyle(color: AppColors.success, fontSize: 12)),
                                  ),
                                if (s.views != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text('👁️ ${s.views}',
                                        style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
                                  ),
                                if (s.inSeries)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text('📺 ح${s.episode}',
                                        style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
                                  ),
                              ],
                            ),
                            leading: IconButton(
                              tooltip: s.isFavorite ? 'شيل من المفضّلة' : 'زيد للمفضّلة',
                              icon: Icon(s.isFavorite ? Icons.star : Icons.star_border,
                                  color: s.isFavorite ? AppColors.warning : cs.onSurfaceVariant),
                              onPressed: () => _toggleFav(s),
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ResultScreen(script: s)),
                              );
                              _load(); // ممكن تبدّل (مفضّلة/نشر/تعديل)
                            },
                            trailing: IconButton(
                              tooltip: 'فسخ',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(s),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
