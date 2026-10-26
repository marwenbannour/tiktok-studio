import 'dart:convert';

import 'package:flutter/material.dart';

import '../db/database.dart';
import '../editor/project_repo.dart';
import '../theme.dart';

/// محرّر الفيديو (Lot 2) — نسخة أولى: يورّي الـtimeline متاع المشروع
/// (المسارات + الـclips بتوقيتها من الـassemblage auto). التحرير الكامل
/// (drag/trim/split/export) يجي في increments جايين.
class VideoEditorScreen extends StatefulWidget {
  final int projectId;
  const VideoEditorScreen({super.key, required this.projectId});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  // ترتيب المسارات (كيما CapCut): الفيديو فوق، الموسيقى تحت
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProjectRepo.byId(widget.projectId);
    final c = await ProjectRepo.clips(widget.projectId);
    if (!mounted) return;
    setState(() {
      _project = p;
      _clips = c;
      _loading = false;
    });
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
            tooltip: 'استورد rushes (قريباً)',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('استيراد الـrushes يجي في التحديث الجاي 🎥')),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : p == null
              ? const Center(child: Text('المشروع ماكانش'))
              : Column(
                  children: [
                    // معاينة (placeholder — video_player يجي لاحقاً)
                    AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text('👁️ المعاينة\n(تجي مع video_player)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMid)),
                        ),
                      ),
                    ),
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
                    // الـtimeline
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
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الـexport الكامل بالنصوص يجي قريباً 🎬')),
                  ),
                  icon: const Icon(Icons.movie_filter_outlined),
                  label: const Text('صدّر MP4'),
                ),
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
                    // خلفية المسار
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // الـclips
                    for (final clip in clips)
                      Positioned(
                        left: (clip.startMs / durMs * w).clamp(0, w - 2),
                        width: ((clip.outMs <= 0 ? durMs : clip.outMs) / durMs * w)
                            .clamp(10, w),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                          ),
                          alignment: Alignment.centerRight,
                          child: Text(_clipLabel(clip),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textHigh)),
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
