import 'package:flutter/material.dart';

import '../claude_api.dart';
import '../models.dart';
import '../prompts.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/neon.dart';
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

  @override
  void dispose() {
    _idea.dispose();
    super.dispose();
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
      final json = await api.askJson(Prompts.script(
        category: _category,
        idea: _idea.text.trim(),
        style: _style,
        duration: _duration,
      ));
      final script = VideoScript.fromJson({
        ...json,
        'category': _category,
        'style': _style,
        'duration': _duration,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      if (script.segments.isEmpty) {
        throw ClaudeException('الجواب جا ناقص. عاود جرّب.');
      }
      final saved = await AppStorage.saveScript(script);
      await AppStorage.incrementGenCount(); // F20
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(script: saved)),
      );
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
        ],
      ),
    );
  }
}
