import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import 'result_screen.dart';

/// مقارنة نسختين (A/B) بـhooks مختلفة — المستخدم يعتمد وحدة.
class ABScreen extends StatelessWidget {
  final VideoScript a;
  final VideoScript b;
  const ABScreen({super.key, required this.a, required this.b});

  Future<void> _choose(BuildContext context, VideoScript s) async {
    final saved = await AppStorage.saveScript(s);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(script: saved)),
    );
  }

  Widget _card(BuildContext context, String label, VideoScript s) {
    final tt = Theme.of(context).textTheme;
    final firstVoice = s.segments.isNotEmpty ? s.segments.first.voice : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.cyan, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.title,
                    style: tt.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('🎣 الـhook', style: tt.labelMedium?.copyWith(color: AppColors.textMid)),
          const SizedBox(height: 2),
          Text(
            s.hookIdea.isNotEmpty ? s.hookIdea : firstVoice,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          if (firstVoice.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('🎙️ أول segment',
                style: tt.labelMedium?.copyWith(color: AppColors.textMid)),
            const SizedBox(height: 2),
            Text(firstVoice, style: tt.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _choose(context, s),
              icon: const Icon(Icons.check),
              label: Text('اعتمد نسخة $label'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🆎 جرّب نسختين')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'نفس الفكرة، أما بـhooks مختلفة. اقرا الزوز، اعتمد اللي يعجبك، '
            'وبعد ما تنشر دخّل المشاهدات في «الإحصائيات» باش تعرف أنهي hook يخدم أكثر.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _card(context, 'A', a),
          _card(context, 'B', b),
        ],
      ),
    );
  }
}
