import { createClient } from "@supabase/supabase-js";
import type { ModelStat, Stats, UsageRow } from "./types";

const DAYS = 14;

function dayKey(d: Date): string {
  return d.toISOString().slice(0, 10); // YYYY-MM-DD
}

function aggregate(rows: UsageRow[], demo: boolean): Stats {
  const now = new Date();
  const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

  let month = 0;
  let okCount = 0;
  let msSum = 0;
  let msCount = 0;
  const byModelMap = new Map<string, number>();
  const byDayMap = new Map<string, number>();
  const hours = new Array(24).fill(0);
  const statusMap = new Map<number, number>();
  // لكل يوم: مجموع ms وعدد
  const dayMs = new Map<string, { sum: number; n: number }>();
  // لكل موديل: تفاصيل
  const modelDetail = new Map<string, { count: number; ok: number; sum: number; n: number }>();

  // آخر DAYS يوم (حتى لو فارغين)
  for (let i = DAYS - 1; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    byDayMap.set(dayKey(d), 0);
    dayMs.set(dayKey(d), { sum: 0, n: 0 });
  }

  for (const r of rows) {
    if (r.ok) okCount++;
    if (typeof r.ms === "number") {
      msSum += r.ms;
      msCount++;
    }
    byModelMap.set(r.model, (byModelMap.get(r.model) ?? 0) + 1);
    statusMap.set(r.status, (statusMap.get(r.status) ?? 0) + 1);
    hours[new Date(r.created_at).getHours()]++;

    const dk = r.created_at.slice(0, 10);
    if (byDayMap.has(dk)) byDayMap.set(dk, (byDayMap.get(dk) ?? 0) + 1);
    if (typeof r.ms === "number" && dayMs.has(dk)) {
      const e = dayMs.get(dk)!;
      e.sum += r.ms;
      e.n++;
    }

    const md = modelDetail.get(r.model) ?? { count: 0, ok: 0, sum: 0, n: 0 };
    md.count++;
    if (r.ok) md.ok++;
    if (typeof r.ms === "number") {
      md.sum += r.ms;
      md.n++;
    }
    modelDetail.set(r.model, md);

    if (r.created_at.slice(0, 7) === monthKey) month++;
  }

  const models: ModelStat[] = [...modelDetail.entries()]
    .map(([model, d]) => ({
      model,
      count: d.count,
      okRate: d.count ? d.ok / d.count : 0,
      avgMs: d.n ? Math.round(d.sum / d.n) : 0,
    }))
    .sort((a, b) => b.count - a.count);

  return {
    demo,
    total: rows.length,
    month,
    okRate: rows.length ? okCount / rows.length : 0,
    avgMs: msCount ? Math.round(msSum / msCount) : 0,
    byDay: [...byDayMap.entries()].map(([day, count]) => ({ day, count })),
    byModel: [...byModelMap.entries()]
      .map(([model, count]) => ({ model, count }))
      .sort((a, b) => b.count - a.count),
    byHour: hours.map((count, hour) => ({ hour, count })),
    latencyByDay: [...dayMs.entries()].map(([day, e]) => ({
      day,
      ms: e.n ? Math.round(e.sum / e.n) : 0,
    })),
    models,
    statuses: [...statusMap.entries()]
      .map(([status, count]) => ({ status, count }))
      .sort((a, b) => b.count - a.count),
    recent: rows.slice(0, 12),
  };
}

function demoRows(): UsageRow[] {
  const models = ["gemma4:31b", "gpt-oss:20b", "gpt-oss:120b", "qwen3-coder:480b"];
  const weights = [0.5, 0.25, 0.15, 0.1];
  const rows: UsageRow[] = [];
  const now = Date.now();
  let seed = 42;
  const rnd = () => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  };
  for (let i = 0; i < 180; i++) {
    const t = now - Math.floor(rnd() * DAYS * 864e5);
    let acc = 0;
    const r = rnd();
    let model = models[0];
    for (let m = 0; m < models.length; m++) {
      acc += weights[m];
      if (r <= acc) {
        model = models[m];
        break;
      }
    }
    const ok = rnd() > 0.08;
    rows.push({
      created_at: new Date(t).toISOString(),
      model,
      ok,
      status: ok ? 200 : [401, 429, 502][Math.floor(rnd() * 3)],
      ms: Math.round(1500 + rnd() * 4000),
    });
  }
  return rows.sort((a, b) => b.created_at.localeCompare(a.created_at));
}

export async function getStats(): Promise<Stats> {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) return aggregate(demoRows(), true);

  try {
    const supa = createClient(url, key, { auth: { persistSession: false } });
    const since = new Date(Date.now() - DAYS * 864e5).toISOString();
    const { data, error } = await supa
      .from("usage_log")
      .select("created_at, model, ok, status, ms")
      .gte("created_at", since)
      .order("created_at", { ascending: false })
      .limit(5000);
    if (error) throw error;
    return aggregate((data ?? []) as UsageRow[], false);
  } catch {
    // كان الجدول موش موجود ولا غلطة اتصال → بيانات تجريبية
    return aggregate(demoRows(), true);
  }
}
