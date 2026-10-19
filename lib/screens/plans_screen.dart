import 'package:flutter/material.dart';

import '../models.dart';
import '../reminders.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/neon.dart';
import 'plan_editor.dart';
import 'result_screen.dart';

/// «البرنامج»: الفيديوهات المبرمجة ووين وصلت (فكرة ← تصوّر ← تنشر)
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<PlannedVideo> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AppStorage.loadPlans();
    if (mounted) {
      setState(() {
        _plans = list;
        _loading = false;
      });
    }
  }

  Future<void> _save(PlannedVideo p) async {
    await AppStorage.savePlan(p);
    await _load();
    try {
      await Reminders.sync(p);
    } catch (e) {
      debugPrint('Reminders.sync: $e');
    }
  }

  Future<void> _add() async {
    final p = await editPlan(context);
    if (p != null) await _save(p);
  }

  Future<void> _edit(PlannedVideo p) async {
    final n = await editPlan(context, plan: p);
    if (n != null) await _save(n);
  }

  Future<void> _delete(PlannedVideo p) async {
    await AppStorage.deletePlan(p.id);
    await _load();
    try {
      await Reminders.cancel(p);
    } catch (_) {}
  }

  Future<void> _openScript(PlannedVideo p) async {
    final s = await AppStorage.findScript(p.scriptId!);
    if (!mounted) return;
    if (s == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('السكريبت هذا تفسخ من المحفوظات.')));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(script: s)));
  }

  Widget _summary() {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    final week = _plans.where((p) => p.date.isAfter(now) && p.date.isBefore(weekEnd)).length;
    final posted = _plans.where((p) => p.status == PlanStatus.posted).length;
    final todo = _plans.where((p) => p.status != PlanStatus.posted).length;
    final pct = _plans.isEmpty ? 0.0 : posted / _plans.length;
    Widget stat(String n, String l, Color c) => Column(children: [
          Text(n, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: c)),
          Text(l, style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
        ]);
    return GlowCard(
      glow: AppColors.cyan,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NeonRing(
            percent: pct,
            size: 86,
            center: '${(pct * 100).round()}%',
            sub: 'تنشرو',
          ),
          stat('$week', 'هالجمعة', AppColors.cyan),
          stat('$todo', 'باقي', AppColors.rose),
          stat('$posted', 'تنشرو', AppColors.success),
        ],
      ),
    );
  }

  Widget _tile(PlannedVideo p) {
    final cs = Theme.of(context).colorScheme;
    final late_ = p.status != PlanStatus.posted && p.date.isBefore(DateTime.now());
    return ListTile(
      key: ValueKey(p.id),
      title: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Text('${formatDay(p.date)} · ', style: TextStyle(color: late_ ? cs.error : null)),
          Text(formatTime(p.date),
              textDirection: TextDirection.ltr, style: TextStyle(color: late_ ? cs.error : null)),
          if (p.reminder && p.status != PlanStatus.posted) const Text(' 🔔'),
          if (p.scriptId != null) const Text(' 🔗'),
        ],
      ),
      leading: ActionChip(
        tooltip: 'بدّل الحالة',
        label: Text(p.status.label),
        onPressed: () => _save(p.copyWith(status: p.status.next)),
      ),
      onTap: p.scriptId == null ? () => _edit(p) : () => _openScript(p),
      trailing: PopupMenuButton<String>(
        tooltip: 'خيارات',
        onSelected: (v) => v == 'edit' ? _edit(p) : _delete(p),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('✏️ بدّل')),
          PopupMenuItem(value: 'delete', child: Text('🗑️ فسخ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البرنامج')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('برمج فيديو'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'ما برمجت حتى فيديو. النشر بانتظام (3 مرّات في الجمعة) يعاون برشا باش تكبر 📈',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    _summary(),
                    for (final p in _plans) ...[_tile(p), const Divider(height: 1)],
                  ],
                ),
    );
  }
}
