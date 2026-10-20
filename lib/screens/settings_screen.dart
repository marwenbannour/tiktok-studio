import 'package:flutter/material.dart';

import '../backup_io.dart';
import '../storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = TextEditingController();
  final _custom = TextEditingController();
  final _cap = TextEditingController();
  bool _obscure = true;
  String _model = AppStorage.defaultModel;
  int _count = 0;
  bool _busyBackup = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k = await AppStorage.getApiKey();
    final m = await AppStorage.getModel();
    final cap = await AppStorage.getGenCap();
    final count = await AppStorage.genCount();
    if (!mounted) return;
    setState(() {
      _key.text = k ?? '';
      _model = m;
      // إذا الموديل مش من القائمة، ورّيه في خانة «موديل آخر»
      if (!AppStorage.models.containsKey(m)) _custom.text = m;
      _cap.text = cap == 0 ? '' : '$cap';
      _count = count;
    });
  }

  @override
  void dispose() {
    _key.dispose();
    _custom.dispose();
    _cap.dispose();
    super.dispose();
  }

  Future<void> _saveCap() async {
    final cap = int.tryParse(_cap.text.trim()) ?? 0;
    await AppStorage.setGenCap(cap);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _snack(cap == 0 ? 'تشال الحدّ الشهري.' : 'تسجّل الحدّ: $cap توليدة في الشهر ✅');
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _saveKey() async {
    final k = _key.text.trim();
    if (k.isEmpty) {
      await AppStorage.deleteApiKey();
      if (!mounted) return;
      _snack('تفسخ المفتاح.');
    } else {
      await AppStorage.setApiKey(k);
      if (!mounted) return;
      _snack('تسجّل المفتاح ✅');
    }
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _export() async {
    setState(() => _busyBackup = true);
    try {
      final n = await BackupIO.exportAndShare();
      if (mounted) _snack(n == 0 ? 'ما فماش سكريبتات تتصدّر.' : 'تصدّرو $n سكريبت ✅');
    } catch (e) {
      if (mounted) _snack('ما نجّمناش نصدّرو النسخة.');
    } finally {
      if (mounted) setState(() => _busyBackup = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busyBackup = true);
    try {
      final r = await BackupIO.importFromClipboard();
      if (!mounted) return;
      if (r == null) {
        _snack('الحافظة فارغة. افتح ملف النسخة، اعمل Copier للكل، وبعد عاود.');
      } else {
        _snack(r.added == 0
            ? 'كل السكريبتات موجودين ديجا (تتخطّى ${r.skipped}).'
            : 'تسترجعو ${r.added} سكريبت ✅'
                '${r.skipped > 0 ? ' (تتخطّى ${r.skipped} موجودين)' : ''}');
      }
    } on FormatException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('ما نجّمناش نسترجعو.');
    } finally {
      if (mounted) setState(() => _busyBackup = false);
    }
  }

  Future<void> _pickModel(String m) async {
    setState(() {
      _model = m;
      _custom.clear();
    });
    await AppStorage.setModel(m);
  }

  Future<void> _saveCustomModel() async {
    final m = _custom.text.trim();
    if (m.isEmpty) return;
    setState(() => _model = m);
    await AppStorage.setModel(m);
    if (mounted) {
      FocusScope.of(context).unfocus();
      _snack('تسجّل الموديل: $m ✅');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('مفتاح Ollama API', style: tt.titleMedium),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _key,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: 'المفتاح متاع ollama.com',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _saveKey, child: const Text('سجّل المفتاح')),
          const SizedBox(height: 8),
          Text(
            'اعمل المفتاح في ollama.com ← Settings ← API Keys. يتسجّل مشفّر على التليفون '
            'متاعك برك. ما تورّيه لحدّ، وما يبانش في حتى فيديو تسجّل فيه الشاشة!',
            style: tt.bodySmall,
          ),
          const SizedBox(height: 28),
          Text('الموديل', style: tt.titleMedium),
          const SizedBox(height: 4),
          ...AppStorage.models.entries.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value),
                subtitle: Text(e.key, textDirection: TextDirection.ltr),
                trailing: _model == e.key
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : const Icon(Icons.circle_outlined),
                onTap: () => _pickModel(e.key),
              )),
          const SizedBox(height: 8),
          Text('ولا اكتب اسم موديل آخر من ollama.com/library', style: tt.bodySmall),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _custom,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      hintText: 'مثلا: gpt-oss:120b',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _saveCustomModel, child: const Text('سجّل')),
              ],
            ),
          ),
          if (!AppStorage.models.containsKey(_model))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('الموديل المستعمل توّا: $_model',
                  textDirection: TextDirection.ltr,
                  style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 28),
          Text('الحدّ الشهري للتوليد', style: tt.titleMedium),
          const SizedBox(height: 4),
          Text('باش ما تخرجش على الميزانية متاعك. 0 ولا فارغ = بلا حدّ.',
              style: tt.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cap,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'مثلا: 100',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'توليدة/شهر',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _saveCap, child: const Text('سجّل')),
            ],
          ),
          const SizedBox(height: 8),
          Text('استعملت $_count هالشهر.',
              style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 28),
          Text('النسخة الاحتياطية', style: tt.titleMedium),
          const SizedBox(height: 4),
          Text(
            '«صدّر» يعمل ملف JSON بكل السكريبتات ويفتحلك المشاركة (حطّو في Drive ولا '
            'ابعثو لروحك) — وينسخو زادة في الحافظة. باش تسترجع كي تبدّل التليفون: '
            'افتح ملف النسخة، اعمل Copier للكل، وبعد أعمل «استرجع من الحافظة». '
            'الاسترجاع ما يعاودش السكريبتات اللي موجودين ديجا.',
            style: tt.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busyBackup ? null : _export,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('صدّر'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busyBackup ? null : _import,
                  icon: const Icon(Icons.content_paste_go),
                  label: const Text('استرجع من الحافظة'),
                ),
              ),
            ],
          ),
          if (_busyBackup)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
