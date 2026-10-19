import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/prompter.dart';
import 'record_screen.dart';

class TeleprompterScreen extends StatefulWidget {
  final VideoScript script;
  const TeleprompterScreen({super.key, required this.script});

  @override
  State<TeleprompterScreen> createState() => _TeleprompterScreenState();
}

class _TeleprompterScreenState extends State<TeleprompterScreen> {
  final _scroller = AutoScroller();
  double _fontSize = 34;

  @override
  void initState() {
    super.initState();
    _scroller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Teleprompter'),
        actions: [
          IconButton(
            tooltip: 'صغّر الخط',
            icon: const Icon(Icons.text_decrease),
            onPressed: () => setState(() => _fontSize = (_fontSize - 4).clamp(20.0, 64.0)),
          ),
          IconButton(
            tooltip: 'كبّر الخط',
            icon: const Icon(Icons.text_increase),
            onPressed: () => setState(() => _fontSize = (_fontSize + 4).clamp(20.0, 64.0)),
          ),
          IconButton(
            tooltip: 'سجّل بالكاميرا',
            icon: const Icon(Icons.videocam),
            onPressed: () {
              _scroller.stop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RecordScreen(script: widget.script)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PrompterText(
            script: widget.script,
            controller: _scroller.controller,
            fontSize: _fontSize,
            padding: EdgeInsets.fromLTRB(22, h * 0.35, 22, h * 0.6),
          ),
          // خط القراءة
          Positioned(
            left: 0,
            right: 0,
            top: h * 0.3,
            child: IgnorePointer(
              child: Container(height: 3, color: const Color(0x8CF2B632)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: const Color(0xFF111A27),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              PrompterControls(scroller: _scroller),
              const Spacer(),
              FilledButton.icon(
                onPressed: _scroller.toggle,
                icon: Icon(_scroller.playing ? Icons.pause : Icons.play_arrow),
                label: Text(_scroller.playing ? 'وقّف' : 'ابدأ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
