// Supabase Edge Function: "generate"
// Proxy على Ollama Cloud يخبّي مفتاح الـAPI في السيرفر.
//
// زوز طرق للدخول:
//  1. مستعمل عندو حساب (الـapp): header  Authorization: Bearer <access_token متاع Supabase>
//     السيرفر يثبّت فيه عند Supabase Auth (/auth/v1/user) → user_id حقيقي،
//     ويطبّق حدّ يومي لكل مستعمل (DAILY_LIMIT).
//  2. صاحب المشروع (الداشبورد ولا التجارب): header  x-app-token: <APP_TOKEN>
//     حدّ يومي منفصل (OWNER_DAILY_LIMIT). كان APP_TOKEN ما تحطّش، الطريقة هذي مسكّرة.
//
// ملاحظة: الـanon key زادة JWT صالح، على هذاك ما نعتمدوش على --verify-jwt
// وحدو: لازم /auth/v1/user يرجّع مستعمل حقيقي.
//
// أسرار (Supabase → Edge Functions → Secrets):
//   OLLAMA_API_KEY     (لازم)  مفتاح ollama.com
//   APP_TOKEN          (اختياري) كلمة سرّ صاحب المشروع
//   ALLOWED_MODELS     (اختياري) موديلات مسموحة، مفصولة بفاصلة
//   DAILY_LIMIT        (اختياري) طلبات/24 ساعة لكل مستعمل (افتراضي 30)
//   OWNER_DAILY_LIMIT  (اختياري) طلبات/24 ساعة لصاحب المشروع (افتراضي 200)
// SUPABASE_URL و SUPABASE_ANON_KEY و SUPABASE_SERVICE_ROLE_KEY يحطّهم Supabase وحدو.
//
// deploy:  supabase functions deploy generate --no-verify-jwt
// (الثبوت من الـJWT يصير هنا في الكود، باش x-app-token يقعد يخدم زادة)

const OLLAMA_URL = "https://ollama.com/api/chat";
const MAX_NUM_PREDICT = 4000;
const MAX_PROMPT_CHARS = 20_000;
const DEFAULT_MODELS = [
  "gemma4:31b",
  "gpt-oss:20b",
  "gpt-oss:120b",
  "qwen3-coder:480b",
  "deepseek-v3.1:671b",
];

const env = (k: string) => Deno.env.get(k)?.trim() || undefined;
const intEnv = (k: string, d: number) => {
  const n = Number(env(k));
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : d;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

/** مقارنة بوقت ثابت (ما تسرّبش الطول ولا موضع الاختلاف بالتوقيت). */
async function safeEqual(a: string, b: string): Promise<boolean> {
  const enc = new TextEncoder();
  const [ha, hb] = await Promise.all([
    crypto.subtle.digest("SHA-256", enc.encode(a)),
    crypto.subtle.digest("SHA-256", enc.encode(b)),
  ]);
  const x = new Uint8Array(ha), y = new Uint8Array(hb);
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

type Caller = { kind: "user"; userId: string } | { kind: "owner" };

/** شكون يطلب؟ null = ممنوع. */
async function identify(req: Request): Promise<Caller | null> {
  const auth = req.headers.get("authorization") ?? "";
  if (auth.toLowerCase().startsWith("bearer ")) {
    const url = env("SUPABASE_URL");
    const anon = env("SUPABASE_ANON_KEY");
    if (!url || !anon) return null;
    try {
      const r = await fetch(`${url}/auth/v1/user`, {
        headers: { apikey: anon, authorization: auth },
      });
      if (!r.ok) return null;
      const u = await r.json();
      return typeof u?.id === "string" ? { kind: "user", userId: u.id } : null;
    } catch {
      return null;
    }
  }
  const appToken = env("APP_TOKEN");
  const given = req.headers.get("x-app-token");
  if (appToken && given && await safeEqual(given, appToken)) return { kind: "owner" };
  return null;
}

/** عدد الطلبات في آخر 24 ساعة (service role). -1 كان ما نجمناش نحسبو. */
async function usedLast24h(caller: Caller): Promise<number> {
  const url = env("SUPABASE_URL");
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return -1;
  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const who = caller.kind === "user"
    ? `user_id=eq.${caller.userId}`
    : "user_id=is.null&source=eq.owner";
  try {
    const r = await fetch(
      `${url}/rest/v1/usage_log?select=id&${who}&created_at=gte.${encodeURIComponent(since)}`,
      {
        headers: {
          apikey: key,
          authorization: `Bearer ${key}`,
          prefer: "count=exact",
          range: "0-0",
        },
      },
    );
    const total = r.headers.get("content-range")?.split("/")[1];
    const n = Number(total);
    return Number.isFinite(n) ? n : -1;
  } catch {
    return -1;
  }
}

function logUsage(row: {
  model: string;
  ok: boolean;
  status: number;
  ms: number;
  caller: Caller;
}) {
  const url = env("SUPABASE_URL");
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return;
  const { caller, ...rest } = row;
  fetch(`${url}/rest/v1/usage_log`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      apikey: key,
      authorization: `Bearer ${key}`,
      prefer: "return=minimal",
    },
    body: JSON.stringify({
      ...rest,
      source: caller.kind === "user" ? "app" : "owner",
      user_id: caller.kind === "user" ? caller.userId : null,
    }),
  }).catch(() => {});
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const serverKey = env("OLLAMA_API_KEY");
  if (!serverKey) return json({ error: "server not configured" }, 500);

  const caller = await identify(req);
  if (!caller) return json({ error: "unauthorized" }, 401);

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "invalid json body" }, 400);
  }

  const model = payload["model"];
  const messages = payload["messages"];
  if (typeof model !== "string" || !Array.isArray(messages) || messages.length === 0) {
    return json({ error: "missing model or messages" }, 400);
  }

  const allowed = env("ALLOWED_MODELS")?.split(",").map((m) => m.trim()).filter(Boolean) ??
    DEFAULT_MODELS;
  if (!allowed.includes(model)) {
    return json({ error: "model not allowed", allowed }, 403);
  }

  // الرسائل: role/content نصّ برك، وطول محدود
  let chars = 0;
  const clean: { role: string; content: string }[] = [];
  for (const m of messages) {
    const role = (m as Record<string, unknown>)?.["role"];
    const content = (m as Record<string, unknown>)?.["content"];
    if (!["user", "assistant", "system"].includes(role as string) || typeof content !== "string") {
      return json({ error: "invalid message" }, 400);
    }
    chars += content.length;
    clean.push({ role: role as string, content });
  }
  if (chars > MAX_PROMPT_CHARS) return json({ error: "prompt too long" }, 413);

  // الحدّ اليومي
  const limit = caller.kind === "user"
    ? intEnv("DAILY_LIMIT", 30)
    : intEnv("OWNER_DAILY_LIMIT", 200);
  const used = await usedLast24h(caller);
  if (used >= limit) {
    return json({ error: "daily limit reached", limit }, 429);
  }

  const options = (payload["options"] ?? {}) as Record<string, unknown>;
  const asked = typeof options["num_predict"] === "number" ? options["num_predict"] as number : MAX_NUM_PREDICT;
  const upstreamBody: Record<string, unknown> = {
    model,
    messages: clean,
    stream: false,
    options: { num_predict: Math.min(Math.max(1, asked), MAX_NUM_PREDICT) },
  };
  if (payload["format"] === "json") upstreamBody["format"] = "json";

  const started = Date.now();
  let upstream: Response;
  try {
    upstream = await fetch(OLLAMA_URL, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${serverKey}`,
      },
      body: JSON.stringify(upstreamBody),
    });
  } catch {
    logUsage({ model, ok: false, status: 502, ms: Date.now() - started, caller });
    return json({ error: "upstream unreachable" }, 502);
  }

  const text = await upstream.text();
  logUsage({ model, ok: upstream.ok, status: upstream.status, ms: Date.now() - started, caller });
  return new Response(text, {
    status: upstream.status,
    headers: { "content-type": "application/json" },
  });
});
