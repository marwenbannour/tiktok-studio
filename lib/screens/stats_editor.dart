import 'package:flutter/material.dart';

import '../models.dart';

typedef Stats = ({int? views, int? likes, int? comments});

/// يحلّ dialog لإدخال إحصائيات الفيديو؛ يرجّع الإحصائيات ولا null كان بطّل
Future<Stats?> editStats(BuildContext context, VideoScript s) =>
    showDialog<Stats>(context: context, builder: (_) => _StatsEditor(script: s));

class _StatsEditor extends StatefulWidget {
  final VideoScript script;
  const _StatsEditor({required this.script});

  @override
  State<_StatsEditor> createState() => _StatsEditorState();
}

class _StatsEditorState extends State<_StatsEditor> {
  late final _views = TextEditingController(text: widget.script.views?.toString() ?? '');
  late final _likes = TextEditingController(text: widget.script.likes?.toString() ?? '');
  late final _comments = TextEditingController(text: widget.script.comments?.toString() ?? '');

  @override
  void dispose() {
    _views.dispose();
    _likes.dispose();
    _comments.dispose();
    super.dispose();
  }

  int? _parse(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : int.tryParse(t);
  }

  Widget _field(String label, String emoji, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            prefixText: '$emoji  ',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📊 إحصائيات الفيديو'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('دخّل الأرقام من TikTok باش الـapp توصّيك بأحسن نوع.',
                  style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 12),
            _field('مشاهدات', '👁️', _views),
            _field('لايكات', '❤️', _likes),
            _field('كومنتات', '💬', _comments),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('بطّل')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
              (views: _parse(_views), likes: _parse(_likes), comments: _parse(_comments))),
          child: const Text('سجّل'),
        ),
      ],
    );
  }
}
