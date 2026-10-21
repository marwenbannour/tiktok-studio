import 'package:flutter/material.dart';

import '../claude_api.dart';
import '../models.dart';
import '../prompts.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/neon.dart';
import 'ab_screen.dart';
import 'result_screen.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  static const _categories = <String, String>{
    'Dev AI': '🤖 Dev AI',
    'Football': '⚽ Football',
    'معلومات وحقائق': '🧠 معلومات',
    'ضحك وحكايات تونسية': '😂 ضحك',
  };
  static const _styles = <String, String>{
    'تصوير الشاشة والكود فقط، بلا وجه، مع صوتي': '💻 الشاشة فقط',
    'نظهر بوجهي ونحكي للكاميرا': '🎥 بوجهي',
    'صور وخلفيات مع صوتي فقط': '🎙️ صور وصوت',
    'كتابة وصور مع صوت AI': '🤖 صوت AI',
  };
  static const _durations = [15, 20, 30, 45];

  String _category = 'Dev AI';
  String _style = _styles.keys.first;
  int _duration = 20;
  final _idea = TextEditingController();
  bool _loading = false;
  bool _loadingIdeas = false;
  List<String> _ideas = [];
  bool _loadingHooks = false;
  List<String> _hooks = [];
  String? _chosenHook; // الـhook المختار (يتبعث للتوليد)
  ({String category, double avgViews, int count})? _best; // نصيحة V2

  // سلاسل الحلقات (V2)
  static const _newSeriesTag = '__new__';
  final _newSeries = TextEditingController();
  List<String> _seriesList = [];
  String? _series; // null = بلا سلسلة ; '__new__' = سلسلة جديدة ; غير هكّا = موجودة

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    try {
      final b = await AppStorage.bestCategory();
      final s = await AppStorage.seriesTitles();
      if (mounted) {
        setState(() {
          _best = b;
          _seriesList = s;
          if (_series != null && _series != _newSeriesTag && !s.contains(_series)) _series = null;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _idea.dispose();
    _newSeries.dispose();
    super.dispose();
  }

  /// اسم السلسلة المختار (فارغ = بلا سلسلة)
  String get _seriesName {
    if (_series == null) return '';
    if (_series == _newSeriesTag) return _newSeries.text.trim();
    return _series!;
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<ClaudeApi?> _api() async {
    final api = await ClaudeApi.fromSettings();
    if (api == null) _snack(ClaudeApi.noKeyMessage);
    return api;
  }

  Future<void> _generate() async {
    final api = await _api();
    if (api == null) return;
    // F20: الحدّ الشهري + تنبيه عند 80%
    final cap = await AppStorage.getGenCap();
    if (cap > 0) {
      final count = await AppStorage.genCount();
      if (count >= cap) {
        _snack('وصلت الحدّ الشهري ($cap توليدة). بدّلو في «الإعدادات».');
        return;
      }
      if (count >= (cap * 0.8).ceil()) {
        _snack('⚠️ وصلت $count/$cap من الحدّ الشهري متاع هالشهر.');
      }
    }
    setState(() => _loading = true);
    try {
      // سلسلة (V2): سياق الحلقات السابقة + رقم الحلقة
      final series = _seriesName;
      String seriesContext = '';
      int? episode;
      if (series.isNotEmpty) {
        episode = await AppStorage.nextEpisode(series);
        final prev = await AppStorage.seriesEpisodes(series);
        seriesContext = prev
            .map((e) => 'الحلقة ${e.episode}: ${e.title}'
                '${e.hookIdea.isEmpty ? '' : ' — ${e.hookIdea}'}')
            .join('\n');
      }

      final json = await api.askJson(Prompts.script(
        category: _category,
        idea: _idea.text.trim(),
        style: _style,
        duration: _duration,
        seriesContext: seriesContext,
        hook: _chosenHook ?? '',
      ));
      var script = VideoScript.fromJson({
        ...json,
        'category': _category,
        'style': _style,
        'duration': _duration,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      if (script.segments.isEmpty) {
        throw ClaudeException('الجواب جا ناقص. عاود جرّب.');
      }
      if (series.isNotEmpty) {
        script = script.copyWith(seriesTitle: series, episode: episode);
      }
      final saved = await AppStorage.saveScript(script);
      await AppStorage.incrementGenCount(); // F20
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(script: saved)),
      );
      _loadInsight(); // يمكن دخّل إحصائيات في شاشة النتيجة
    } catch (e) {
      _snack(errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// A/B: نسختين بـhooks مختلفة باش تجرّب أنهي أحسن.
  Future<void> _generateAB() async {
    final api = await _api();
    if (api == null) return;
    final cap = await AppStorage.getGenCap();
    if (cap > 0 && await AppStorage.genCount() >= cap) {
      _snack('وصلت الحدّ الشهري ($cap توليدة). بدّلو في «الإعدادات».');
      return;
    }
    setState(() => _loading = true);
    try {
      final idea = _idea.text.trim();
      // نجيبو hooks (نبداو بالمختار كان فمّا)
      final hooks = <String>[if (_chosenHook != null) _chosenHook!.trim()];
      final hj = await api.askJson(Prompts.hooks(_category, idea), maxTokens: 1000);
      hooks.addAll((hj['hooks'] as List?)?.map((e) => '$e'.trim()).toList() ?? []);
      final uniq = hooks.where((h) => h.isNotEmpty).toSet().toList();
      if (uniq.length < 2) {
        throw ClaudeException('ما نجّمناش نجيبو زوز hooks مختلفة. عاود جرّب.');
      }
      // نولّدو الزوز سكريبتات بالتوازي
      final results = await Future.wait([
        api.askJson(Prompts.script(
            category: _category, idea: idea, style: _style, duration: _duration, hook: uniq[0])),
        api.askJson(Prompts.script(
            category: _category, idea: idea, style: _style, duration: _duration, hook: uniq[1])),
      ]);
      VideoScript build(Map<String, dynamic> json) => VideoScript.fromJson({
            ...json,
            'category': _category,
            'style': _style,
            'duration': _duration,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
      final a = build(results[0]);
      final b = build(results[1]);
      if (a.segments.isEmpty || b.segments.isEmpty) {
        throw ClaudeException('جا جواب ناقص. عاود جرّب.');
      }
      await AppStorage.incrementGenCount();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ABScreen(a: a, b: b)),
      );
      _loadInsight();
    } catch (e) {
      _snack(errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _suggestIdeas() async {
    final api = await _api();
    if (api == null) return;
    setState(() => _loadingIdeas = true);
    try {
      final json = await api.askJson(Prompts.ideas(_category), maxTokens: 1000);
      final list = (json['ideas'] as List?)?.map((e) => '$e').toList() ?? [];
      setState(() => _ideas = list);
    } catch (e) {
      _snack(errorMessage(e));
    } finally {
      if (mounted) setState(() => _loadingIdeas = false);
    }
  }

  Future<void> _suggestHooks() async {
    final api = await _api();
    if (api == null) return;
    setState(() => _loadingHooks = true);
    try {
      final json =
          await api.askJson(Prompts.hooks(_category, _idea.text.trim()), maxTokens: 1000);
      final list = (json['hooks'] as List?)?.map((e) => '$e').toList() ?? [];
      setState(() => _hooks = list);
    } catch (e) {
      _snack(errorMessage(e));
    } finally {
      if (mounted) setState(() => _loadingHooks = false);
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(t, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _chips<T>(Map<T, String> items, T selected, ValueChanged<T> onPick) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.entries.map((e) {
          final sel = e.key == selected;
          return ChoiceChip(
            label: Text(e.value),
            selected: sel,
            labelStyle: TextStyle(
              color: sel ? AppColors.night : AppColors.textMid,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => setState(() => onPick(e.key)),
          );
        }).toList(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ستوديو التيكتوك 🎬'),
            Text('فكرة · سكريبت · فيديو',
                style: TextStyle(fontSize: 11, color: AppColors.textMid)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أهلا 👋', style: Theme.of(context).textTheme.headlineSmall),
                const Text('جاهز تحضّر فيديوك الجديد؟',
                    style: TextStyle(color: AppColors.textMid)),
              ],
            ),
          ),
          if (_best != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Text('📈', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '«${_categories[_best!.category] ?? _best!.category}» يخدم مليح عندك — '
                      'متوسّط ${_best!.avgViews.round()} مشاهدة. جرّب تزيد منّو!',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          _label('نوع المحتوى'),
          _chips(_categories, _category, (v) => _category = v),
          _label('الفكرة (اختياري)'),
          TextField(
            controller: _idea,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'مثلاً: AI يلقى bug في الكود متاعي…',
              border: OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _loadingIdeas ? null : _suggestIdeas,
              icon: _loadingIdeas
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lightbulb_outline),
              label: Text(_loadingIdeas ? 'نخمّم…' : 'اقترحلي أفكار'),
            ),
          ),
          ..._ideas.map((i) => Card(
                child: ListTile(
                  leading: const Text('💡'),
                  title: Text(i),
                  onTap: () => setState(() {
                    _idea.text = i;
                    _ideas = [];
                  }),
                ),
              )),
          // 🎣 اقتراح 3 hooks — نختار وحدة وتتبعث للتوليد (أهمّ حاجة: أول 3 ثواني)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _loadingHooks ? null : _suggestHooks,
              icon: _loadingHooks
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bolt_outlined),
              label: Text(_loadingHooks ? 'نخمّم…' : 'اقترحلي 3 hooks 🎣'),
            ),
          ),
          ..._hooks.map((h) => Card(
                child: ListTile(
                  leading: const Text('🎣'),
                  title: Text(h),
                  trailing: const Icon(Icons.add_circle_outline, color: AppColors.cyan),
                  onTap: () => setState(() {
                    _chosenHook = h;
                    _hooks = [];
                  }),
                ),
              )),
          if (_chosenHook != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('🎣 '),
                    Expanded(
                      child: Text('الـhook المختار: ${_chosenHook!}',
                          style: const TextStyle(
                              color: AppColors.cyan, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      tooltip: 'شيل',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _chosenHook = null),
                    ),
                  ],
                ),
              ),
            ),
          _label('📺 سلسلة (اختياري)'),
          DropdownButtonFormField<String?>(
            initialValue: _series,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('بلا سلسلة')),
              for (final s in _seriesList) DropdownMenuItem(value: s, child: Text('📺 $s')),
              const DropdownMenuItem(value: _newSeriesTag, child: Text('➕ سلسلة جديدة')),
            ],
            onChanged: (v) => setState(() => _series = v),
          ),
          if (_series == _newSeriesTag)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _newSeries,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'اسم السلسلة الجديدة',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          if (_seriesName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('باش يكمّل القصّة من الحلقات اللي فاتت في «$_seriesName» 🔗',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.cyan)),
            ),
          _label('كيفاش تظهر في الفيديو'),
          _chips(_styles, _style, (v) => _style = v),
          _label('المدّة'),
          _chips({for (final d in _durations) d: '${d}s'}, _duration, (v) => _duration = v),
          const SizedBox(height: 28),
          NeonButton(
            onPressed: _loading ? null : _generate,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.movie_creation),
            label: _loading ? 'نحضّر… (20–60 ثانية)' : 'حضّرلي الفيديو',
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loading ? null : _generateAB,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('جرّب نسختين A/B 🆎'),
          ),
        ],
      ),
    );
  }
}
