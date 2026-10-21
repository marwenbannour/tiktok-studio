import 'models.dart';

class Prompts {
  static const rules = '''إنت خبير في صناعة فيديوهات TikTok لصانع محتوى تونسي مبتدئ (أقل من 1000 متابع).
اكتب كل شي بالدارجة التونسية بالحروف العربية، وخلّي المصطلحات التقنية بالإنجليزي/الفرنسي كيما يحكيو التوانسة (code, bug, function, AI...).
قواعد:
- الـhook في أول 3 ثواني لازم يوقّف المشاهد.
- الـcall to action في الآخر يطلب كلمة في الكومنتارات.
- إذا الموضوع برمجة، عطي مثال كود قصير (أقل من 12 سطر)، صحيح 100%، وإذا ينجم ورّي غلطة حقيقية تبيّن علاش لازم تجرّب الكود.
- ما تقولش إنّ AI ديما صحيح ولا إنّ الربح مضمون.
- للكورة: ما تستعملش لقطات ماتشات عندها حقوق بثّ؛ اقترح بدائل (صور خاصة، رسوم، تكتيك على لوحة).
- نصايح الخصوصية: ما يبانوش كلمات سرّ ولا إشعارات ولا معلومات شخصية.''';

  static String script({
    required String category,
    required String idea,
    required String style,
    required int duration,
    String seriesContext = '',
    String hook = '',
  }) =>
      '''$rules

المطلوب: سكريبت فيديو TikTok.
- النوع: $category
- الفكرة: ${idea.isEmpty ? 'إختار إنت فكرة قوية وبسيطة تناسب مبتدئ' : idea}
- طريقة الظهور: $style
- المدّة: $duration ثانية بالضبط، format 9:16
${hook.trim().isEmpty ? '' : '- الـhook (segment الأول، أول 3 ثواني) لازم يكون بالضبط: «${hook.trim()}» — ابنِ الباقي عليه.'}
${seriesContext.isEmpty ? '' : '''
هذا جزء من سلسلة حلقات متواصلة. الحلقات اللي فاتت:
$seriesContext
كمّل القصّة في هالحلقة الجديدة: ما تعاودش نفس الكلام، خلّي ربط واضح مع اللي فات (مثلا «في الحلقة اللي فاتت...»)، وخلّي الآخر يشوّق للحلقة الجاية.
'''}
جاوب بـJSON برك، بلا أي كلام آخر وبلا backticks، بالشكل هذا:
{
 "title": "عنوان الفيديو",
 "hook_idea": "جملة وحدة تشرح الفكرة",
 "segments": [ {"from":0,"to":3,"screen":"شنوّة يبان على الشاشة","text":"النص المكتوب على الفيديو","voice":"شنوّة تقول بصوتك"} ],
 "code": "الكود إذا لازم، وإلّا string فارغة",
 "code_note": "شرح قصير للكود أو string فارغة",
 "steps": [ {"title":"عنوان الخطوة","detail":"كيفاش تعملها بالتفصيل (تسجيل، CapCut، صوت...)"} ],
 "caption": "الـcaption متاع البوست",
 "hashtags": ["#..."],
 "tips": ["نصيحة"]
}
الـsegments تغطّي من 0 لين $duration بلا فراغات (بين 4 و7 segments). الـsteps بين 4 و6.''';

  static String rewriteSegment(VideoScript script, int index, String instruction) {
    final s = script.segments[index];
    final all = [
      for (var i = 0; i < script.segments.length; i++)
        '${i == index ? '👉 ' : ''}[${script.segments[i].range}] ${script.segments[i].voice}'
    ].join('\n');
    return '''$rules

عاود اكتب segment واحد من سكريبت TikTok.
- العنوان: ${script.title}
- النوع: ${script.category} – ${script.duration} ثانية
- السكريبت الكل (الـsegment المطلوب عليه 👉):
$all

الـsegment المطلوب: ${s.range}${index == 0 ? ' (هذا الـhook: لازم يوقّف المشاهد في أول 3 ثواني)' : ''}
- الشاشة: ${s.screen}
- النص: ${s.text}
- الصوت: ${s.voice}
الطلب: ${instruction.isEmpty ? 'خلّيه أقوى وأوضح' : instruction}

خلّي نفس المدّة (${s.to - s.from} ثواني) ونفس الـstyle. جاوب بـJSON برك:
{"screen":"...","text":"...","voice":"..."}''';
  }

  static String ideas(String category) => '''$rules

اقترح 5 أفكار فيديوهات TikTok قصيرة في موضوع: $category. كل فكرة جملة قصيرة بالدارجة التونسية، سهلة التصوير لمبتدئ.
جاوب بـJSON برك: {"ideas":["...","..."]}''';

  static String hooks(String category, String idea) => '''$rules

المطلوب: 3 hooks مختلفة لفيديو TikTok في موضوع: $category.
${idea.trim().isEmpty ? 'إختار إنت زاوية قوية تناسب مبتدئ.' : 'الفكرة: ${idea.trim()}'}
الـhook هو أول 3 ثواني: جملة وحدة قصيرة (أقل من 12 كلمة) توقّف المشاهد وتمنعو يسكرولا.
خلّي الـ3 مختلفين في الأسلوب (مثلا: سؤال مثير، نتيجة صادمة، غلطة شائعة، «شدّ بالك»...).
جاوب بـJSON برك: {"hooks":["...","...","..."]}''';
}
