import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../db/database.dart';
import '../editor/project_repo.dart';
import '../theme.dart';

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

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// V05: يحرّر clip فيديو — قصّ المدّة (trim) ولا فسخ.
  Future<void> _editVideoClip(Clip clip) async {
    var outMs = (clip.outMs > 0 ? clip.outMs : 1000).toDouble();
    final maxMs = outMs; // المدّة الأصلية = الحدّ الأقصى للقصّ
    final changed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
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
              Text('✂️ المدّة: ${(outMs / 1000).toStringAsFixed(1)}s'),
              Slider(
                value: outMs,
                min: 200,
                max: maxMs < 200 ? 200 : maxMs,
                onChanged: (v) => setSheet(() => outMs = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, false),
                      icon: const Icon(Icons.delete_outline, color: AppColors.rose),
                      label: const Text('فسخ', style: TextStyle(color: AppColors.rose)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.content_cut),
                      label: const Text('قصّ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (changed == null) return; // تسكّر بلا اختيار
    if (changed) {
      await ProjectRepo.trimVideoClip(
          projectId: widget.projectId, clipId: clip.id, outMs: outMs.round());
    } else {
      await ProjectRepo.deleteClip(projectId: widget.projectId, clipId: clip.id);
      await _preview?.dispose();
      _preview = null;
    }
    await _load();
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
                  onPressed: () => _snack('الـexport الكامل بالنصوص يجي قريباً 🎬'),
                  icon: const Icon(Icons.movie_filter_outlined),
                  label: const Text('صدّر MP4'),
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
                        left: (clip.startMs / durMs * w).clamp(0, w - 2),
                        width: ((clip.outMs <= 0 ? durMs : clip.outMs) / durMs * w)
                            .clamp(10, w),
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
