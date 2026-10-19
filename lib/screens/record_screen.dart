import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../models.dart';
import '../widgets/prompter.dart';

/// تسجيل الفيديو بالكاميرا الأمامية والنص يتسكرولا فوقها
class RecordScreen extends StatefulWidget {
  final VideoScript script;
  const RecordScreen({super.key, required this.script});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with WidgetsBindingObserver {
  final _scroller = AutoScroller();
  CameraController? _cam;
  List<CameraDescription> _cameras = [];
  int _camIndex = 0;
  String? _error;
  bool _recording = false;
  bool _saving = false;
  int? _countdown;
  final _clock = Stopwatch();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroller.addListener(() => setState(() {}));
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _scroller.dispose();
    _cam?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _cam;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      if (_recording) _stop();
      _cam = null;
      cam.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _open(_cameras[_camIndex]);
    }
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'ما لقيتش كاميرا في التليفون.');
        return;
      }
      final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _camIndex = front < 0 ? 0 : front;
      await _open(_cameras[_camIndex]);
    } on CameraException catch (e) {
      setState(() => _error = _cameraError(e));
    }
  }

  Future<void> _open(CameraDescription d) async {
    final old = _cam;
    _cam = null;
    await old?.dispose();
    final cam = CameraController(d, ResolutionPreset.high, enableAudio: true);
    try {
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      setState(() {
        _cam = cam;
        _error = null;
      });
    } on CameraException catch (e) {
      await cam.dispose();
      if (mounted) setState(() => _error = _cameraError(e));
    }
  }

  String _cameraError(CameraException e) => switch (e.code) {
        'CameraAccessDenied' ||
        'CameraAccessDeniedWithoutPrompt' ||
        'CameraAccessRestricted' =>
          'لازم تعطي الإذن للكاميرا من Paramètres ← Applications.',
        'AudioAccessDenied' ||
        'AudioAccessDeniedWithoutPrompt' ||
        'AudioAccessRestricted' =>
          'لازم تعطي الإذن للميكرو من Paramètres ← Applications.',
        _ => 'الكاميرا ما حلّتش (${e.code}).',
      };

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _recording) return;
    _camIndex = (_camIndex + 1) % _cameras.length;
    await _open(_cameras[_camIndex]);
  }

  Future<void> _start() async {
    final cam = _cam;
    if (cam == null || _recording || _countdown != null) return;
    _scroller.restart();
    for (var i = 3; i > 0; i--) {
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    setState(() => _countdown = null);
    try {
      await cam.startVideoRecording();
    } on CameraException catch (e) {
      _snack(_cameraError(e));
      return;
    }
    _clock
      ..reset()
      ..start();
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
    _scroller.start();
    setState(() => _recording = true);
  }

  Future<void> _stop() async {
    final cam = _cam;
    if (cam == null || !_recording) return;
    _scroller.stop();
    _tick?.cancel();
    _clock.stop();
    setState(() {
      _recording = false;
      _saving = true;
    });
    try {
      final file = await cam.stopVideoRecording();
      if (!await Gal.hasAccess(toAlbum: true)) await Gal.requestAccess(toAlbum: true);
      await Gal.putVideo(file.path, album: 'TikTok Studio');
      _snack('تسجّل الفيديو في الـgalerie ✅');
    } on GalException catch (e) {
      _snack('ما نجمتش نسجّل في الـgalerie (${e.type.name}).');
    } on CameraException catch (e) {
      _snack(_cameraError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String get _elapsed {
    final s = _clock.elapsed.inSeconds;
    return '${two(s ~/ 60)}:${two(s % 60)} / ${two(widget.script.duration ~/ 60)}:${two(widget.script.duration % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final cam = _cam;
    final h = MediaQuery.of(context).size.height;
    final over = _clock.elapsed.inSeconds > widget.script.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('سجّل الفيديو'),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              tooltip: 'بدّل الكاميرا',
              icon: const Icon(Icons.cameraswitch),
              onPressed: _recording ? null : _switchCamera,
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cam != null && cam.value.isInitialized)
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cam.value.previewSize?.height ?? 1080,
                  height: cam.value.previewSize?.width ?? 1920,
                  child: CameraPreview(cam),
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          // النص في النص الفوقاني، قريب من الكاميرا باش العينين يقعدو في البلاصة
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h * 0.42,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Color(0x00000000)],
                ),
              ),
              child: PrompterText(
                script: widget.script,
                controller: _scroller.controller,
                fontSize: 26,
                padding: EdgeInsets.fromLTRB(20, 12, 20, h * 0.3),
              ),
            ),
          ),
          if (_countdown != null)
            Center(
              child: Text('$_countdown',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 12)])),
            ),
          if (_recording)
            Positioned(
              top: h * 0.42,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: over ? Colors.orange : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('● $_elapsed',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
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
              _saving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: cam == null || _countdown != null
                          ? null
                          : (_recording ? _stop : _start),
                      icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
                      label: Text(_recording ? 'وقّف التسجيل' : 'سجّل'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
