import 'package:flutter/material.dart';

import '../capcut_export.dart';
import '../models.dart';
import '../theme.dart';

/// جسر لـCapCut: خطة المونتاج + captions جاهزين للتسليم.
class CapCutScreen extends StatelessWidget {
  final VideoScript script;
  const CapCutScreen({super.key, required this.script});

  void _snack(BuildContext c, String m) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('🎬 إلى CapCut')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'سجّل فيديوك (بكاميرا التطبيق ولا مسجّل الشاشة)، وبعد كمّل المونتاج '
            'الاحترافي في CapCut. التطبيق يجهّزلك كل شي:',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await CapCutExport.copyPlan(script);
                  if (context.mounted) _snack(context, 'تنسخت الخطة ✅ الصقها وين تحب');
                },
                icon: const Icon(Icons.copy_all),
                label: const Text('انسخ الخطة'),
              ),
              OutlinedButton.icon(
                onPressed: () => CapCutExport.sharePlan(script),
                icon: const Icon(Icons.description_outlined),
                label: const Text('صدّر الخطة (نصّ)'),
              ),
              OutlinedButton.icon(
                onPressed: () => CapCutExport.shareSrt(script),
                icon: const Icon(Icons.subtitles_outlined),
                label: const Text('صدّر captions (SRT)'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
            ),
            child: Text(
              '💡 الفيديو اللي سجّلتو بالكاميرا يتحفظ في الـgalerie. في CapCut: '
              'مشروع جديد ← استورد الفيديو، وبعد استورد ملف captions.srt (ولا زيد '
              'النصوص يدوي كيما الخطة). كيما تحبّ تشاركو مباشرة، استعمل زرّ المشاركة '
              'في الـgalerie واختار CapCut.',
              style: tt.bodySmall?.copyWith(color: AppColors.textMid),
            ),
          ),
          const SizedBox(height: 20),
          Text('📋 معاينة الخطة', style: tt.titleMedium),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              CapCutExport.plan(script),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
