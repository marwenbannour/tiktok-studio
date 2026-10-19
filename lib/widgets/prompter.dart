import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';

/// السكرول الأوتوماتيكي متاع الـTeleprompter (مشترك بين الشاشة والكاميرا)
class AutoScroller extends ChangeNotifier {
  final controller = ScrollController();
  Timer? _timer;
  double speed = 1.2;

  bool get playing => _timer != null;

  void start() {
    if (playing) return;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!controller.hasClients) return;
      final max = controller.position.maxScrollExtent;
      final next = controller.offset + speed;
      if (next >= max) {
        controller.jumpTo(max);
        stop();
      } else {
        controller.jumpTo(next);
      }
    });
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void toggle() => playing ? stop() : start();

  void restart() {
    stop();
    if (controller.hasClients) controller.jumpTo(0);
  }

  void faster() {
    speed = (speed + 0.2).clamp(0.4, 4.0);
    notifyListeners();
  }

  void slower() {
    speed = (speed - 0.2).clamp(0.4, 4.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }
}

/// النص اللي يتقرا: الصوت متاع كل segment
class PrompterText extends StatelessWidget {
  final VideoScript script;
  final ScrollController controller;
  final double fontSize;
  final EdgeInsets padding;

  const PrompterText({
    super.key,
    required this.script,
    required this.controller,
    required this.fontSize,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: padding,
      children: script.segments
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.range,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: Color(0xFFF2B632), fontSize: 14)),
                    Text(s.voice,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            shadows: const [Shadow(blurRadius: 6)])),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

/// أزرار التحكّم: من الأوّل، أبطأ، السرعة، أسرع
class PrompterControls extends StatelessWidget {
  final AutoScroller scroller;
  const PrompterControls({super.key, required this.scroller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          color: Colors.white,
          tooltip: 'من الأوّل',
          icon: const Icon(Icons.replay),
          onPressed: scroller.restart,
        ),
        IconButton(
          color: Colors.white,
          tooltip: 'أبطأ',
          icon: const Icon(Icons.remove),
          onPressed: scroller.slower,
        ),
        Text('×${scroller.speed.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white70)),
        IconButton(
          color: Colors.white,
          tooltip: 'أسرع',
          icon: const Icon(Icons.add),
          onPressed: scroller.faster,
        ),
      ],
    );
  }
}
