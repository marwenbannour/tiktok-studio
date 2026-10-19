import 'package:flutter/material.dart';

import '../models.dart';

const _days = ['الإثنين', 'الثلاثاء', 'الإربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

String formatDay(DateTime d) => '${_days[d.weekday - 1]} ${two(d.day)}/${two(d.month)}';
String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// غدوة على 18:00 (وقت باهي للنشر)
DateTime defaultPlanDate([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month, n.day + 1, 18);
}

/// يحلّ الفورم متاع plan جديد ولا موجود. يرجّع الـplan ولا null.
Future<PlannedVideo?> editPlan(
  BuildContext context, {
  PlannedVideo? plan,
  String? title,
  int? scriptId,
}) =>
    showDialog<PlannedVideo>(
      context: context,
      builder: (_) => PlanEditor(
        isNew: plan == null,
        plan: plan ??
            PlannedVideo(
              id: DateTime.now().millisecondsSinceEpoch,
              title: title ?? '',
              date: defaultPlanDate(),
              scriptId: scriptId,
            ),
      ),
    );

class PlanEditor extends StatefulWidget {
  final PlannedVideo plan;
  final bool isNew;
  const PlanEditor({super.key, required this.plan, this.isNew = false});

  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  late final _title = TextEditingController(text: widget.plan.title);
  late DateTime _date = widget.plan.date;
  late bool _reminder = widget.plan.reminder;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (t != null) setState(() => _date = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
  }

  void _save() {
    final t = _title.text.trim();
    if (t.isEmpty) return;
    Navigator.of(context).pop(widget.plan.copyWith(title: t, date: _date, reminder: _reminder));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNew ? '📅 برمج فيديو' : '📅 بدّل الفيديو'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              autofocus: widget.plan.title.isEmpty,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'العنوان ولا الفكرة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDay,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(formatDay(_date)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(formatTime(_date), textDirection: TextDirection.ltr),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('🔔 فكّرني وقت النشر'),
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
            ),
            if (widget.plan.scriptId != null)
              const Text('🔗 مربوط بسكريبت من المحفوظات', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('بطّل')),
        FilledButton(
          onPressed: _title.text.trim().isEmpty ? null : _save,
          child: const Text('سجّل'),
        ),
      ],
    );
  }
}
