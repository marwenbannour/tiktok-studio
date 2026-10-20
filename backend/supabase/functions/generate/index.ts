// Supabase Edge Function: "generate"
// Proxy شفّاف على Ollama Cloud يخبّي مفتاح الـAPI في السيرفر.
// الـapp تبعث نفس شكل طلب Ollama (/api/chat) + header x-app-token،
// والسيرفر يعدّيه لـOllama بالمفتاح السرّي ويرجّع الجواب كيما هو.
//
// أسرار لازمين (Supabase → Edge Functions → Secrets):
//   OLLAMA_API_KEY  : المفتاح متاع ollama.com (سرّي — ما يبانش فالـapp)
//   APP_TOKEN       : كلمة سرّ تاع التطبيق (يبعثها الـapp في x-app-token)
//
// deploy:  supabase functions deploy generate --no-verify-jwt
// (--no-verify-jwt خاطر ما نستعملوش حسابات Supabase؛ الحماية بـAPP_TOKEN)

const OLLAMA_URL = "https://ollama.com/api/chat";

// نحدّدو سقف أعلى للـtokens باش حتى لو الـapp طلبت برشا، ما نخرجوش على الميزانية
const MAX_NUM_PREDICT = 4000;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "content-type, x-app-token",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "content-type": "application/json" },
  });

// تسجيل الاستعمال في جدول usage_log (fire-and-forget — ما يعطّلش الجواب).
// SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY يحطّهم Supabase وحدو فالـEdge Function.
function logUsage(row: {
  model: string;
  ok: boolean;
  status: number;
  ms: number;
  source?: string;
}) {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return;
  fetch(`${url}/rest/v1/usage_log`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      apikey: key,
      authorization: `Bearer ${key}`,
      prefer: "return=minimal",
    },
    body: JSON.stringify({ source: "app", ...row }),
  }).catch(() => {});
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const serverKey = Deno.env.get("OLLAMA_API_KEY");
  const appToken = Deno.env.get("APP_TOKEN");
  if (!serverKey || !appToken) {
    return json({ error: "server not configured (missing secrets)" }, 500);
  }

  // حماية: لازم الـtoken يطابق
  if (req.headers.get("x-app-token") !== appToken) {
    return json({ error: "unauthorized" }, 401);
  }

  // قراءة الطلب (نفس شكل Ollama /api/chat)
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

  // نحدّدو num_predict بسقف أعلى
  const options = (payload["options"] ?? {}) as Record<string, unknown>;
  const numPredict = Math.min(
    typeof options["num_predict"] === "number" ? options["num_predict"] as number : MAX_NUM_PREDICT,
    MAX_NUM_PREDICT,
  );

  const upstreamBody: Record<string, unknown> = {
    model,
    messages,
    stream: false,
    options: { ...options, num_predict: numPredict },
  };
  if (payload["format"] === "json") upstreamBody["format"] = "json";

  // تعدية لـOllama بالمفتاح السرّي
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
  } catch (_e) {
    logUsage({ model, ok: false, status: 502, ms: Date.now() - started });
    return json({ error: "upstream unreachable" }, 502);
  }

  // نرجّعو الجواب كيما هو (نفس شكل Ollama: {message:{content}})
  const text = await upstream.text();
  logUsage({
    model,
    ok: upstream.ok,
    status: upstream.status,
    ms: Date.now() - started,
  });
  return new Response(text, {
    status: upstream.status,
    headers: { ...cors, "content-type": "application/json" },
  });
});
