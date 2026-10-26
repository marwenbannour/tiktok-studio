import 'package:flutter/material.dart';

import '../db/database.dart';
import '../editor/project_repo.dart';
import 'video_editor_screen.dart';

/// tab «Projets» (Lot 2): قائمة مشاريع الفيديو.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<Project> list = [];
    try {
      list = await ProjectRepo.all();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشاريع الفيديو')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'ماكانش مشاريع بعد.\nمن شاشة النتيجة، اضغط «🎞️ ركّب الفيديو» '
                      'باش تبدا مشروع من سكريبت.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = _items[i];
                    return ListTile(
                      leading: const Text('🎬', style: TextStyle(fontSize: 22)),
                      title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${(p.durationMs / 1000).toStringAsFixed(1)}s · ${p.width}×${p.height} · ${_date(p.updatedAt)}'),
                      trailing: IconButton(
                        tooltip: 'فسخ',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ProjectRepo.remove(p.id);
                          await _load();
                        },
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => VideoEditorScreen(projectId: p.id),
                        ));
                        _load();
                      },
                    );
                  },
                ),
    );
  }
}
