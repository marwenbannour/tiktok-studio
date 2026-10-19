import 'package:flutter/material.dart';

import '../main.dart';
import '../theme.dart';

/// شاشة الإطلاق (Écran de lancement) — logo + wordmark + tagline
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final _fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.5, curve: Curves.easeOut));
  late final _scale = Tween(begin: 0.85, end: 1.0)
      .animate(CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const HomeShell()),
          ),
        );
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _badge(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(t, style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // logo
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(color: AppColors.cyan.withValues(alpha: 0.35), blurRadius: 30),
                      BoxShadow(color: AppColors.rose.withValues(alpha: 0.30), blurRadius: 30),
                    ],
                  ),
                  child: const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 24),
                // wordmark بـgradient
                ShaderMask(
                  shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                  child: Text('ستوديو التيكتوك',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                ),
                const SizedBox(height: 6),
                const Text('فكرة · سكريبت · فيديو',
                    style: TextStyle(color: AppColors.textMid, fontSize: 14, letterSpacing: 1)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: [_badge('سريع'), _badge('ساهل'), _badge('تونس 🇹🇳')],
                ),
                const SizedBox(height: 36),
                // شريط تحميل gradient (مربوط بالـanimation)
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 5, color: AppColors.card),
                        AnimatedBuilder(
                          animation: _c,
                          builder: (_, __) => FractionallySizedBox(
                            widthFactor: _c.value,
                            child: Container(
                              height: 5,
                              decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
