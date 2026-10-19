import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// زرّ كبير بـgradient neon وتوهّج (للـCTA الرئيسي)
class NeonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Gradient gradient;
  final double height;

  const NeonButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.gradient = AppColors.brandGradient,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.rose.withValues(alpha: 0.40),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(height / 2),
            onTap: onPressed,
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: const IconThemeData(color: Colors.white),
                    child: icon,
                  ),
                  const SizedBox(width: 10),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// card بحدود متوهّجة بلون neon
class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glow;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GlowCard({
    super.key,
    required this.child,
    this.glow = AppColors.cyan,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glow.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.12), blurRadius: 18, spreadRadius: -2),
        ],
      ),
      child: child,
    );
  }
}

/// حلقة تقدّم دائرية بـgradient neon (كيما في التصميم)
class NeonRing extends StatelessWidget {
  final double percent; // 0..1
  final double size;
  final String center;
  final String? sub;

  const NeonRing({
    super.key,
    required this.percent,
    this.size = 120,
    required this.center,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(percent.clamp(0, 1)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(center,
                  style: TextStyle(
                      color: AppColors.textHigh,
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.bold)),
              if (sub != null)
                Text(sub!, style: const TextStyle(color: AppColors.textMid, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  _RingPainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const stroke = 10.0;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    canvas.drawCircle(center, radius, track);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.ringGradient.createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percent != percent;
}
