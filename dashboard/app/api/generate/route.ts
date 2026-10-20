import { NextResponse } from "next/server";
import { buildPrompt } from "@/lib/prompt";
import type { Script } from "@/lib/types";

export const dynamic = "force-dynamic";

function extractJson(text: string): Script {
  const clean = text.replace(/```json|```/g, "").trim();
  const s = clean.indexOf("{");
  const e = clean.lastIndexOf("}");
  if (s < 0 || e <= s) throw new Error("bad json");
  return JSON.parse(clean.slice(s, e + 1)) as Script;
}

function demoScript(theme: string, duration: number): Script {
  return {
    title: `(تجريبي) ${theme} في ${duration} ثانية 🎬`,
    hook_idea: "هذا سكريبت تجريبي — ثبّت BACKEND_URL و APP_TOKEN باش يخدم بصحّ.",
    segments: [
      { from: 0, to: 5, screen: "الشاشة الرئيسية", text: "شدّ بالك 👀", voice: "في 3 ثواني نفسّرلك الفكرة." },
      { from: 5, to: Math.max(12, duration - 8), screen: "شرح + مثال", text: "الخطوات", voice: "آك الطريقة خطوة بخطوة." },
      { from: Math.max(12, duration - 8), to: duration, screen: "وجهي + CTA", text: "اكتب DEV 👇", voice: "عجبك؟ اكتبلي DEV في الكومنتار." },
    ],
    code: 'function hello(){ return "Studio TikTok"; }',
    code_note: "مثال بسيط (تجريبي).",
    steps: [
      { title: "صوّر الشاشة", detail: "سجّل وإنت تشرح." },
      { title: "المونتاج", detail: "CapCut + زoom على المهمّ." },
    ],
    caption: "سكريبت تجريبي من الداشبورد ⚡",
    hashtags: ["#dev", "#tiktok", "#تونس"],
    tips: ["ثبّت الـbackend باش التوليد يخدم بالحقّ."],
  };
}

export async function POST(req: Request) {
  let payload: { theme: string; idea?: string; mode: string; duration: number; model?: string };
  try {
    payload = await req.json();
  } catch {
    return NextResponse.json({ error: "طلب غير صالح" }, { status: 400 });
  }
  const { theme, idea, mode, duration, model } = payload;

  const backend = process.env.BACKEND_URL;
  const token = process.env.APP_TOKEN;

  // بلا backend → سكريبت تجريبي باش الصفحة تتشاف
  if (!backend || !token) {
    return NextResponse.json({ demo: true, script: demoScript(theme, duration) });
  }

  const prompt = buildPrompt({ theme, idea, mode, duration });
  try {
    const res = await fetch(backend, {
      method: "POST",
      headers: { "content-type": "application/json", "x-app-token": token },
      body: JSON.stringify({
        model: model || "gemma4:31b",
        messages: [{ role: "user", content: prompt }],
        stream: false,
        format: "json",
        options: { num_predict: 4000 },
      }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
      return NextResponse.json(
        { error: body?.error || `خطأ من السيرفر (${res.status})` },
        { status: res.status },
      );
    }
    const content: string = body?.message?.content ?? "";
    const script = extractJson(content);
    return NextResponse.json({ demo: false, script });
  } catch {
    return NextResponse.json(
      { error: "ما نجّمناش نولّدو. ثبّت فالعنوان/الكلمة السرّ ولا عاود." },
      { status: 502 },
    );
  }
}
