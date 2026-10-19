import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../exporter.dart';
import '../models.dart';
import '../reminders.dart';
import '../storage.dart';
import '../theme.dart';
import 'plan_editor.dart';
import 'segment_editor.dart';
import 'teleprompter_screen.dart';

class ResultScreen extends StatefulWidget {
  final VideoScript script;
  const ResultScreen({super.key, required this.script});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late VideoScript script = widget.script;

  void _snack(String m, {Duration duration = const Duration(seconds: 2)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: duration));
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('تنسخ ✅', duration: const Duration(seconds: 1));
  }

  Future<void> _editSegment(int i) async {
    final s = await editSegment(context, script, i);
    if (s == null || !mounted) return;
    setState(() => script = script.withSegment(i, s));
    await AppStorage.updateScript(script);
    _snack('تسجّل التبديل ✅');
  }

  Future<void> _addToPlan() async {
    final p = await editPlan(context, title: script.title, scriptId: script.createdAt);
    if (p == null) return;
    await AppStorage.savePlan(p);
    try {
      await Reminders.sync(p);
    } catch (e) {
      debugPrint('Reminders.sync: $e');
    }
    _snack('تزاد للبرنامج: ${formatDay(p.date)} ${formatTime(p.date)} 📅');
  }

  void _onMenu(String what) {
    if (what == 'publish') {
      _togglePublished();
    } else {
      _share(what);
    }
  }

  Future<void> _share(String what) async {
    try {
      switch (what) {
        case 'script':
          await Exporter.shareScript(script);
        case 'caption':
          await Exporter.shareCaption(script);
        case 'txt':
          await Exporter.shareTxt(script);
      }
    } catch (e) {
      _snack('ما نجمتش نشارك. عاود جرّب.');
    }
  }

  Future<void> _toggleFav() async {
    if (script.dbId == null) return;
    final fav = !script.isFavorite;
    setState(() => script = script.copyWith(isFavorite: fav));
    await AppStorage.setFavorite(script.dbId!, fav);
    _snack(fav ? 'تزادت للمفضّلة ⭐' : 'تشالت من المفضّلة');
  }

  Future<void> _togglePublished() async {
    if (script.dbId == null) return;
    final publish = script.publishedAt == null;
    final ts = publish ? DateTime.now().millisecondsSinceEpoch : null;
    setState(() => script = script.copyWith(publishedAt: ts, clearPublished: !publish));
    await AppStorage.setPublished(script.dbId!, ts);
    _snack(publish ? 'تعلّم كتنشر ✅' : 'تشال وسم النشر');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(script.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (script.dbId != null)
            IconButton(
              tooltip: script.isFavorite ? 'شيل من المفضّلة' : 'زيد للمفضّلة',
              icon: Icon(script.isFavorite ? Icons.star : Icons.star_border,
                  color: script.isFavorite ? AppColors.warning : null),
              onPressed: _toggleFav,
            ),
          IconButton(
            tooltip: 'زيد للبرنامج',
            icon: const Icon(Icons.event_available),
            onPressed: _addToPlan,
          ),
          IconButton(
            tooltip: 'انسخ الكل',
            icon: const Icon(Icons.copy_all),
            onPressed: () => _copy(context, script.fullText()),
          ),
          PopupMenuButton<String>(
            tooltip: 'المزيد',
            onSelected: _onMenu,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'script', child: Text('📝 شارك السكريبت كامل')),
              const PopupMenuItem(value: 'caption', child: Text('📲 شارك الـcaption')),
              const PopupMenuItem(value: 'txt', child: Text('📄 صدّر fichier .txt')),
              if (script.dbId != null)
                PopupMenuItem(
                    value: 'publish',
                    child: Text(script.publishedAt == null ? '✅ علّم كتنشر' : '↩️ شيل وسم النشر')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TeleprompterScreen(script: script)),
        ),
        icon: const Icon(Icons.mic),
        label: const Text('Teleprompter'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text('${script.category} – ${script.duration} ثانية – 9:16',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          if (script.hookIdea.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(script.hookIdea, style: tt.bodyLarge),
            ),

          _Section(
            title: '🎬 السكريبت ثانية بثانية',
            action: TextButton(
                onPressed: () => _copy(context, script.voiceText()),
                child: const Text('انسخ الصوت')),
            child: Column(
              children: [
                for (var i = 0; i < script.segments.length; i++)
                  _SegmentTile(segment: script.segments[i], onTap: () => _editSegment(i)),
                Text('👆 اضغط على segment باش تبدّلو ولا الـAI يعاود يكتبو',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),

          if (script.code.trim().isNotEmpty)
            _Section(
              title: '💻 الكود',
              action: TextButton(
                  onPressed: () => _copy(context, script.code), child: const Text('انسخ')),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E33),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SelectableText(
                          script.code,
                          style: const TextStyle(
                              fontFamily: 'monospace', color: Color(0xFFE3ECF8), fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  if (script.codeNote.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(script.codeNote),
                    ),
                ],
              ),
            ),

          if (script.steps.isNotEmpty)
            _Section(
              title: '✂️ التصوير والمونتاج',
              child: Column(
                children: [
                  for (var i = 0; i < script.steps.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                      title: Text(script.steps[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(script.steps[i].detail),
                    ),
                ],
              ),
            ),

          _Section(
            title: '📲 الـCaption',
            action: TextButton(
                onPressed: () => _copy(context, script.captionText()),
                child: const Text('انسخ')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(script.caption),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: script.hashtags
                      .map((h) => Chip(label: Text(h), visualDensity: VisualDensity.compact))
                      .toList(),
                ),
              ],
            ),
          ),

          if (script.tips.isNotEmpty)
            _Section(
              title: '❤️ نصايح قبل ما تنشر',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: script.tips
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $t'),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Section({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  final Segment segment;
  final VoidCallback onTap;
  const _SegmentTile({required this.segment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 74,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(segment.range,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: cs.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎬 على الشاشة', style: small),
                Text(segment.screen),
                const SizedBox(height: 6),
                Text('✍️ النص على الفيديو', style: small),
                Text(segment.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('🎤 الصوت', style: small),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(segment.voice),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 18, color: cs.onSurfaceVariant),
        ],
      ),
      ),
    );
  }
}
