import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../db/database.dart';
import '../editor/project_repo.dart';
import '../theme.dart';
import '../video_engine.dart';

/// محرّر الفيديو (Lot 2): معاينة (video_player) + timeline متعدّد المسارات.
/// V02 استيراد rushes + V07 معاينة. التحرير الكامل (trim/split/export) جاي.
class VideoEditorScreen extends StatefulWidget {
  final int projectId;
  const VideoEditorScreen({super.key, required this.projectId});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  static const _tracks = [
    ('video', '🎬 فيديو'),
    ('overlay', '🖼️ طبقة'),
    ('text', '📝 نصّ'),
    ('subtitle', '💬 ترجمة'),
    ('voice', '🎙️ صوت'),
    ('music', '🎵 موسيقى'),
  ];

  Project? _project;
  List<Clip> _clips = [];
  bool _loading = true;
  bool _busy = false;
  VideoPlayerController? _preview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await ProjectRepo.byId(widget.projectId);
    final c = await ProjectRepo.clips(widget.projectId);
    // المعاينة = أول clip فيديو
    final firstVideo = c.where((x) => x.track == 'video' && x.sourcePath != null);
    if (firstVideo.isNotEmpty && _preview == null) {
      final f = File(firstVideo.first.sourcePath!);
      if (await f.exists()) {
        final ctrl = VideoPlayerController.file(f);
        try {
          await ctrl.initialize();
          _preview = ctrl;
        } catch (_) {
          await ctrl.dispose();
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _project = p;
      _clips = c;
      _loading = false;
    });
  }

  Future<void> _importRush() async {
    setState(() => _busy = true);
    try {
      final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (x == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final copied = await ProjectRepo.importMedia(widget.projectId, x.path);
      // المدّة
      final ctrl = VideoPlayerController.file(File(copied));
      var durMs = 0;
      try {
        await ctrl.initialize();
        durMs = ctrl.value.duration.inMilliseconds;
      } finally {
        await ctrl.dispose();
      }
      await ProjectRepo.addVideoClip(
          projectId: widget.projectId, sourcePath: copied, durationMs: durMs);
      await _preview?.dispose();
      _preview = null;
      await _load();
      if (mounted) _snack('تزاد الفيديو للـtimeline ✅');
    } catch (e) {
      if (mounted) _snack('ما نجّمناش نستوردو الفيديو.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// V21: export المشروع لـMP4 (دمج الفيديوهات + حرق النصوص الموقّتة) → galerie.
  Future<void> _export() async {
    final plan = await ProjectRepo.buildExportPlan(widget.projectId);
    if (plan.clips.isEmpty) {
      _snack('زيد فيديو واحد على الأقلّ قبل الـexport (➕ فوق).');
      return;
    }
    setState(() => _busy = true);
    try {
      final base = await getApplicationDocumentsDirectory();
      final out =
          '${base.path}/projects/${widget.projectId}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final p = _project!;
      final r = await VideoEngine.exportComposition(
        clips: plan.clips,
        overlays: plan.overlays,
        output: out,
        width: p.width,
        height: p.height,
      );
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putVideo(r.output, album: 'TikTok Studio');
      await ProjectRepo.markExported(widget.projectId, r.output);
      if (mounted) {
        _snack('تصدّر فالـgalerie ✅ (${(r.ms / 1000).toStringAsFixed(1)}s)');
      }
    } catch (e) {
      if (mounted) _snack('فشل الـexport: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// V05: يحرّر clip فيديو — قصّ (trim)، قسمة (split)، ولا فسخ.
  Future<void> _editVideoClip(Clip clip) async {
    final dur = ProjectRepo.clipDuration(clip).toDouble();
    final maxDur = dur < 400 ? 400.0 : dur;
    var trimMs = dur < 200 ? 200.0 : dur;
    var splitMs = dur / 2;
    final action = await showModalBottomSheet<(String, int)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(clip.sourcePath?.split('/').last ?? 'clip',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('✂️ قصّ المدّة: ${(trimMs / 1000).toStringAsFixed(1)}s'),
              Slider(
                value: trimMs.clamp(200, maxDur).toDouble(),
                min: 200,
                max: maxDur,
                onChanged: (v) => setSheet(() => trimMs = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, ('delete', 0)),
                      icon: const Icon(Icons.delete_outline, color: AppColors.rose),
                      label: const Text('فسخ', style: TextStyle(color: AppColors.rose)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, ('trim', trimMs.round())),
                      icon: const Icon(Icons.content_cut),
                      label: const Text('قصّ'),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              Text('✁ قسّم عند: ${(splitMs / 1000).toStringAsFixed(1)}s'),
              Slider(
                value: splitMs.clamp(0, maxDur).toDouble(),
                min: 0,
                max: maxDur,
                onChanged: dur <= 400
                    ? null // قصير برشة باش يتقسّم
                    : (v) => setSheet(() => splitMs = v),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: dur <= 400
                      ? null
                      : () => Navigator.pop(ctx, ('split', splitMs.round())),
                  icon: const Icon(Icons.call_split),
                  label: const Text('قسّم لجوجة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null) return; // تسكّر بلا اختيار
    switch (action.$1) {
      case 'trim':
        await ProjectRepo.trimVideoClip(
            projectId: widget.projectId, clipId: clip.id, durationMs: action.$2);
      case 'split':
        await ProjectRepo.splitVideoClip(
            projectId: widget.projectId, clipId: clip.id, atMs: action.$2);
      case 'delete':
        await ProjectRepo.deleteClip(projectId: widget.projectId, clipId: clip.id);
        await _preview?.dispose();
        _preview = null;
    }
    await _load();
  }

  /// V05: رتّب clips الفيديو بالسحب (ReorderableListView).
  Future<void> _reorderClips() async {
    final videos = _clips.where((c) => c.track == 'video').toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));
    if (videos.length < 2) {
      _snack('رتّب يحتاج زوز clips فيديو على الأقلّ.');
      return;
    }
    final items = List<Clip>.from(videos);
    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('⇅ رتّب الفيديوهات (اسحب)',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              Flexible(
                child: ReorderableListView(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  onReorderItem: (oldI, newI) => setSheet(() {
                    items.insert(newI, items.removeAt(oldI));
                  }),
                  children: [
                    for (var i = 0; i < items.length; i++)
                      ListTile(
                        key: ValueKey(items[i].id),
                        leading: CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.rose.withValues(alpha: 0.25),
                            child: Text('${i + 1}',
                                style: const TextStyle(fontSize: 12))),
                        title: Text(items[i].sourcePath?.split('/').last ?? 'clip',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${(ProjectRepo.clipDuration(items[i]) / 1000).toStringAsFixed(1)}s'),
                        trailing: ReorderableDragStartListener(
                            index: i, child: const Icon(Icons.drag_handle)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('تمّ')),
              ),
            ],
          ),
        ),
      ),
    );
    if (applied == true) {
      await ProjectRepo.reorderVideoClips(
          projectId: widget.projectId,
          orderedIds: items.map((c) => c.id).toList());
      await _load();
    }
  }

  String _clipLabel(Clip c) {
    if (c.sourcePath != null) return c.sourcePath!.split('/').last;
    try {
      return (jsonDecode(c.props)['text'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final p = _project;
    final durMs = (p?.durationMs ?? 0).clamp(1, 1 << 30);

    return Scaffold(
      appBar: AppBar(
        title: Text(p?.title ?? 'محرّر الفيديو', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'رتّب الفيديوهات',
            icon: const Icon(Icons.swap_vert),
            onPressed: _busy ? null : _reorderClips,
          ),
          IconButton(
            tooltip: 'استورد rushes',
            icon: _busy
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _busy ? null : _importRush,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : p == null
              ? const Center(child: Text('المشروع ماكانش'))
              : Column(
                  children: [
                    _previewArea(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${p.width}×${p.height} · ${p.fps}fps', style: tt.bodySmall),
                          Text('⏱️ ${(durMs / 1000).toStringAsFixed(1)}s · ${_clips.length} clip',
                              style: tt.bodySmall?.copyWith(color: AppColors.cyan)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        children: [
                          for (final t in _tracks) _trackRow(t.$1, t.$2, durMs.toInt()),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _loading || p == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.movie_filter_outlined),
                  label: Text(_busy ? 'يصدّر…' : 'صدّر MP4'),
                ),
              ),
            ),
    );
  }

  Widget _previewArea() {
    final ctrl = _preview;
    final ready = ctrl != null && ctrl.value.isInitialized;
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: ui.Clip.antiAlias,
        child: ready
            ? GestureDetector(
                onTap: () => setState(
                    () => ctrl.value.isPlaying ? ctrl.pause() : ctrl.play()),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: ctrl.value.size.width,
                        height: ctrl.value.size.height,
                        child: VideoPlayer(ctrl),
                      ),
                    ),
                    if (!ctrl.value.isPlaying)
                      const Icon(Icons.play_circle_fill,
                          size: 56, color: Colors.white70),
                  ],
                ),
              )
            : const Center(
                child: Text('👁️ المعاينة\nاستورد فيديو من ➕ فوق',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMid)),
              ),
      ),
    );
  }

  Widget _trackRow(String track, String label, int durMs) {
    final clips = _clips.where((c) => c.track == track).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: 34,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    for (final clip in clips)
                      Positioned(
                        left: (clip.startMs / durMs * w).clamp(0.0, w - 2),
                        width: (() {
                          final cd = ProjectRepo.clipDuration(clip);
                          return ((cd <= 0 ? durMs : cd) / durMs * w).clamp(10.0, w);
                        })(),
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: track == 'video' ? () => _editVideoClip(clip) : null,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: track == 'video'
                                  ? AppColors.rose.withValues(alpha: 0.22)
                                  : AppColors.cyan.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: (track == 'video' ? AppColors.rose : AppColors.cyan)
                                      .withValues(alpha: 0.5)),
                            ),
                            alignment: Alignment.centerRight,
                            child: Text(_clipLabel(clip),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textHigh)),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
