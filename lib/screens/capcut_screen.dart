import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../capcut_export.dart';
import '../models.dart';
import '../theme.dart';

/// جسر لـCapCut: تبعث الفيديو مباشرة، وتاخو الترجمة والخطة جاهزين.
class CapCutScreen extends StatefulWidget {
  final VideoScript script;

  /// فيديو جاهز (مثلاً export من المحرّر). كان null، المستعمل يختار من الـgalerie.
  final String? videoPath;

  const CapCutScreen({super.key, required this.script, this.videoPath});

  @override
  State<CapCutScreen> createState() => _CapCutScreenState();
}

class _CapCutScreenState extends State<CapCutScreen> {
  String? _video;
  bool? _installed;
  bool _busy = false;
  late final List<SrtCue> _subs = CapCutExport.subtitleCues(widget.script);
  late final List<SrtCue> _titles = CapCutExport.titleCues(widget.script);

  VideoScript get _s => widget.script;

  @override
  void initState() {
    super.initState();
    _video = widget.videoPath;
    CapCutExport.isCapCutInstalled().then((v) {
      if (mounted) setState(() => _installed = v);
    });
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _run(Future<void> Function() job, String error) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (_) {
      _snack(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickVideo() => _run(() async {
        final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
        if (x != null && mounted) setState(() => _video = x.path);
      }, 'ما نجمتش نحلّ الـgalerie.');

  Future<void> _send() => _run(() async {
        final r = await CapCutExport.sendVideoToCapCut(_video!, subject: _s.title);
        if (r == CapCutSendResult.openedShareSheet) {
          _snack('CapCut ما تحلّش مباشرة. اختارو من القائمة.');
        }
      }, 'ما نجمتش نبعث الفيديو. ثبّت إنّو مازال في التليفون.');

  String _fileName(String path) => path.split(Platform.pathSeparator).last;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('🎬 إلى CapCut')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            _StatusChip(installed: _installed),
            const SizedBox(height: 12),

            // ---- 1. الفيديو
            _Step(
              number: 1,
              title: 'ابعث الفيديو لـCapCut',
              subtitle: _video == null
                  ? 'اختار الفيديو اللي سجّلتو (ولا اللي صدّرتو من المحرّر).'
                  : '🎞️ ${_fileName(_video!)}',
              children: [
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(_video == null ? 'اختار فيديو' : 'بدّل الفيديو'),
                ),
                FilledButton.icon(
                  onPressed: _video == null ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(_installed == false ? 'شارك الفيديو' : 'حلّ في CapCut'),
                ),
              ],
            ),

            // ---- 2. الترجمة
            _Step(
              number: 2,
              title: 'الترجمة والنصوص',
              subtitle: '${_subs.length} سطر ترجمة (≤ ${CapCutExport.maxChars} حرف، موقّتين بالـms)'
                  '${_titles.isEmpty ? '' : ' · ${_titles.length} نصّ على الشاشة'}',
              children: [
                FilledButton.tonalIcon(
                  onPressed: _subs.isEmpty
                      ? null
                      : () async {
                          await CapCutExport.copySubtitles(_s);
                          _snack('تنسخت الترجمة ✅');
                        },
                  icon: const Icon(Icons.copy_all),
                  label: const Text('انسخ الترجمة'),
                ),
                OutlinedButton.icon(
                  onPressed: _subs.isEmpty
                      ? null
                      : () => _run(() => CapCutExport.shareSubtitles(_s),
                          'ما نجمتش نصدّر ملفات SRT.'),
                  icon: const Icon(Icons.subtitles_outlined),
                  label: const Text('صدّر SRT'),
                ),
              ],
              footer: 'على التليفون: Texte ← Sous-titres automatiques، وصلّح الكلمات بالنصّ المنسوخ. '
                  'على الـPC: Texte ← Importer ← captions.srt.',
            ),
            if (_subs.isNotEmpty) _CuePreview(cues: _subs),

            // ---- 3. الخطة
            _Step(
              number: 3,
              title: 'خطة المونتاج',
              subtitle: '${_s.segments.length} مشاهد · ${_s.duration}s · 9:16',
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await CapCutExport.copyPlan(_s);
                    _snack('تنسخت الخطة ✅');
                  },
                  icon: const Icon(Icons.copy_all),
                  label: const Text('انسخ الخطة'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _run(() => CapCutExport.sharePlan(_s), 'ما نجمتش نصدّر الخطة.'),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('صدّر (txt)'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('📋 معاينة الخطة', style: tt.titleSmall),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SelectableText(
                      CapCutExport.plan(_s),
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool? installed;
  const _StatusChip({required this.installed});

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (installed) {
      null => (Icons.hourglass_empty, AppColors.textMid, 'نثبّت في CapCut…'),
      true => (Icons.check_circle, AppColors.success, 'CapCut منصّب: الفيديو يتحلّ فيه مباشرة'),
      false => (Icons.info_outline, AppColors.warning,
          'CapCut موش منصّب: الفيديو يتبعث بقائمة المشاركة'),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? footer;

  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
                child: Text('$number',
                    style: const TextStyle(
                        color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: tt.titleMedium)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: children),
          if (footer != null) ...[
            const SizedBox(height: 10),
            Text(footer!, style: tt.bodySmall?.copyWith(color: AppColors.textLow)),
          ],
        ],
      ),
    );
  }
}

class _CuePreview extends StatelessWidget {
  final List<SrtCue> cues;
  const _CuePreview({required this.cues});

  String _t(int ms) => '${ms ~/ 60000}:${two((ms % 60000) ~/ 1000)}.${(ms % 1000) ~/ 100}';

  @override
  Widget build(BuildContext context) {
    final shown = cues.take(6).toList();
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text('${_t(c.startMs)}–${_t(c.endMs)}',
                        textDirection: TextDirection.ltr,
                        style: small?.copyWith(color: AppColors.cyan)),
                  ),
                  Expanded(child: Text(c.text, style: small)),
                ],
              ),
            ),
          if (cues.length > shown.length)
            Text('+ ${cues.length - shown.length} سطر آخر',
                style: small?.copyWith(color: AppColors.textLow)),
        ],
      ),
    );
  }
}
