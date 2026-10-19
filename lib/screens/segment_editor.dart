import 'package:flutter/material.dart';

import '../claude_api.dart';
import '../models.dart';
import '../prompts.dart';

/// يحلّ الـeditor متاع segment؛ يرجّع الـsegment الجديد ولا null كان بطّل
Future<Segment?> editSegment(BuildContext context, VideoScript script, int index) =>
    showModalBottomSheet<Segment>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SegmentEditor(script: script, index: index),
    );

class SegmentEditor extends StatefulWidget {
  final VideoScript script;
  final int index;
  const SegmentEditor({super.key, required this.script, required this.index});

  @override
  State<SegmentEditor> createState() => _SegmentEditorState();
}

class _SegmentEditorState extends State<SegmentEditor> {
  late final Segment _orig = widget.script.segments[widget.index];
  late final _screen = TextEditingController(text: _orig.screen);
  late final _text = TextEditingController(text: _orig.text);
  late final _voice = TextEditingController(text: _orig.voice);
  final _ask = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _isHook => widget.index == 0;

  List<String> get _quick => [
        if (_isHook) 'hook أقوى يوقّف السكرول',
        'أقصر وأوضح',
        'زيد شوية ضحك',
        'بالدارجة أكثر',
      ];

  @override
  void dispose() {
    for (final c in [_screen, _text, _voice, _ask]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _rewrite() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = await ClaudeApi.fromSettings();
      if (api == null) throw ClaudeException(ClaudeApi.noKeyMessage);
      // نبعثو النسخة اللي في الـeditor (باش Claude يبني على التعديلات)
      final current = widget.script.withSegment(
          widget.index, _orig.copyWith(screen: _screen.text, text: _text.text, voice: _voice.text));
      final j = await api.askJson(
        Prompts.rewriteSegment(current, widget.index, _ask.text.trim()),
        maxTokens: 800,
      );
      final voice = '${j['voice'] ?? ''}'.trim();
      if (voice.isEmpty) throw ClaudeException('الجواب جا ناقص. عاود جرّب.');
      setState(() {
        _screen.text = '${j['screen'] ?? _screen.text}';
        _text.text = '${j['text'] ?? _text.text}';
        _voice.text = voice;
      });
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _save() => Navigator.of(context).pop(_orig.copyWith(
        screen: _screen.text.trim(),
        text: _text.text.trim(),
        voice: _voice.text.trim(),
      ));

  Widget _field(String label, TextEditingController c, {int lines = 2}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          minLines: 1,
          maxLines: lines,
          enabled: !_loading,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('✏️ بدّل ${_orig.range}${_isHook ? ' (الـhook)' : ''}',
                style: tt.titleMedium),
            const SizedBox(height: 12),
            _field('🎬 على الشاشة', _screen),
            _field('✍️ النص على الفيديو', _text),
            _field('🎤 الصوت', _voice, lines: 5),
            const Divider(),
            Text('🤖 خلّي الـAI يعاود يكتبو', style: tt.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quick
                  .map((q) => ActionChip(
                        label: Text(q),
                        onPressed: _loading ? null : () => setState(() => _ask.text = q),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ask,
              enabled: !_loading,
              decoration: const InputDecoration(
                hintText: 'شنوّة تحب تبدّل؟ (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading ? null : _rewrite,
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'الـAI يكتب…' : 'عاود اكتبو'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('بطّل'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    child: const Text('سجّل التبديل'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
