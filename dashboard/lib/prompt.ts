// بناء الـprompt لتوليد سكريبت TikTok بالدارجة التونسية (نفس منطق الـapp).
export const THEMES: Record<string, string> = {
  "Dev AI": "الذكاء الاصطناعي للمطوّرين (برمجة، أدوات AI، نصائح كود)",
  Football: "الكرة (تكتيك، أخبار، تحاليل)",
  "معلومات وحقائق": "معلومات وحقائق غريبة ومفيدة",
  "ضحك وحكايات تونسية": "نكت وحكايات تونسية خفيفة",
};

export const DURATIONS = [15, 20, 30, 45];

export const MODES: Record<string, string> = {
  "الشاشة فقط": "تسجيل شاشة + صوت (بلا وجه)",
  وجهي: "وجه المستخدم في الكاميرا",
  "صور وصوت": "صور + تعليق صوتي",
  "صوت AI": "تعليق بصوت AI",
};

export function buildPrompt(opts: {
  theme: string;
  idea?: string;
  mode: string;
  duration: number;
}): string {
  const { theme, idea, mode, duration } = opts;
  const themeDesc = THEMES[theme] ?? theme;
  const modeDesc = MODES[mode] ?? mode;

  return `إنت كاتب سكريبتات TikTok محترف بالدارجة التونسية (أحرف عربية).
اعمل سكريبت فيديو كامل على الموضوع: «${themeDesc}».
${idea && idea.trim() ? `الفكرة متاع المستخدم: «${idea.trim()}».` : ""}
طريقة العرض: ${modeDesc}. المدّة: ${duration} ثانية بالضبط.

قواعد لازمة:
- دارجة تونسية طبيعية بأحرف عربية (تنجّم تخلط مصطلحات tech بالفرنسية/الإنڤليزية).
- الـhook في أول 3 ثواني.
- appel à l'action في آخر الفيديو.
- الـsegments تغطّي من 0 لـ${duration} ثانية بلا فراغ ولا تداخل.
- كان الموضوع برمجة، زيد مثال كود صحيح أقلّ من 12 سطر.
- بلا وعود بالربح، بلا صور مباريات محمية بحقوق.

جاوب بـJSON فقط (بلا نصّ آخر، بلا markdown) بهالشكل:
{
  "title": "string",
  "hook_idea": "string",
  "segments": [{"from": 0, "to": 3, "screen": "string", "text": "string", "voice": "string"}],
  "code": "string",
  "code_note": "string",
  "steps": [{"title": "string", "detail": "string"}],
  "caption": "string",
  "hashtags": ["string"],
  "tips": ["string"]
}`;
}
