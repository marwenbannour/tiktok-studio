import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';

/// لوحة إحصائيات الأداء (V2)
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // أسماء قصيرة للأنواع
  static const _cats = <String, String>{
    'Dev AI': '🤖 Dev AI',
    'Football': '⚽ Football',
    'معلومات وحقائق': '🧠 معلومات',
    'ضحك وحكايات تونسية': '😂 ضحك',
  };

  bool _loading = true;
  int _total = 0;
  ({int published, int views, int likes, int comments}) _g =
      (published: 0, views: 0, likes: 0, comments: 0);
  List<({String category, int count, double avgViews})> _byCat = [];
  List<VideoScript> _top = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final total = await AppStorage.scriptCount();
      final g = await AppStorage.globalStats();
      final byCat = await AppStorage.categoryStats();
      final top = await AppStorage.topByViews(5);
      if (mounted) {
        setState(() {
          _total = total;
          _g = g;
          _byCat = byCat;
          _top = top;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('stats load: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  static String fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  String _cat(String c) => _cats[c] ?? c;

  Widget _tile(String emoji, String value, String label, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
            ],
          ),
        ),
      );

  /// شريط أفقي (مقارنة متوسّط المشاهدات) — لون واحد + label (الهوية بالاسم موش باللون)
  Widget _bar(String category, double avg, double maxAvg) {
    final frac = maxAvg <= 0 ? 0.0 : (avg / maxAvg).clamp(0.06, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_cat(category), style: const TextStyle(fontSize: 13)),
              Text('${fmt(avg.round())} مشاهدة/فيديو',
                  style: const TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 10, color: AppColors.bgSecondary),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final withViews = _byCat.where((c) => c.avgViews > 0).toList();
    final maxAvg = withViews.isEmpty ? 0.0 : withViews.map((c) => c.avgViews).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('📊 إحصائيات الأداء')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _total == 0
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('ما عندك حتى سكريبت بعد. حضّر فيديو من «حضّر» 🎬',
                        textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                  children: [
                    Row(children: [
                      _tile('📝', '$_total', 'سكريبت', AppColors.textHigh),
                      _tile('✅', '${_g.published}', 'تنشرو', AppColors.success),
                      _tile('👁️', fmt(_g.views), 'مشاهدة', AppColors.cyan),
                    ]),
                    Row(children: [
                      _tile('❤️', fmt(_g.likes), 'لايك', AppColors.rose),
                      _tile('💬', fmt(_g.comments), 'كومنت', AppColors.warning),
                    ]),
                    const SizedBox(height: 20),
                    Text('📈 الأداء حسب النوع', style: tt.titleMedium),
                    const SizedBox(height: 8),
                    if (withViews.isEmpty)
                      Text(
                        'دخّل مشاهدات الفيديوهات (من شاشة النتيجة ← 📊) باش تشوف أنهي نوع يخدم أكثر.',
                        style: tt.bodySmall?.copyWith(color: AppColors.textMid),
                      )
                    else
                      ...withViews.map((c) => _bar(c.category, c.avgViews, maxAvg)),
                    if (_top.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('🏆 أحسن الفيديوهات', style: tt.titleMedium),
                      const SizedBox(height: 4),
                      ..._top.asMap().entries.map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                                child: Text('${e.key + 1}',
                                    style: const TextStyle(color: AppColors.cyan))),
                            title: Text(e.value.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(_cat(e.value.category), style: const TextStyle(fontSize: 12)),
                            trailing: Text('👁️ ${fmt(e.value.views ?? 0)}',
                                style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)),
                          )),
                    ],
                  ],
                ),
    );
  }
}
