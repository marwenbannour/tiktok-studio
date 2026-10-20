"use client";

import { useState } from "react";
import ScriptResult from "@/components/ScriptResult";
import { DURATIONS, MODES, THEMES } from "@/lib/prompt";
import type { Script } from "@/lib/types";

const MODELS = [
  "gemma4:31b",
  "gpt-oss:20b",
  "gpt-oss:120b",
  "qwen3-coder:480b",
  "deepseek-v3.1:671b",
];

export default function GeneratePage() {
  const [theme, setTheme] = useState(Object.keys(THEMES)[0]);
  const [mode, setMode] = useState(Object.keys(MODES)[0]);
  const [duration, setDuration] = useState(20);
  const [model, setModel] = useState(MODELS[0]);
  const [idea, setIdea] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [script, setScript] = useState<Script | null>(null);
  const [demo, setDemo] = useState(false);

  async function generate() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/generate", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ theme, idea, mode, duration, model }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || "صار مشكل. عاود جرّب.");
      setScript(data.script);
      setDemo(!!data.demo);
    } catch (e) {
      setError(e instanceof Error ? e.message : "صار مشكل.");
    } finally {
      setLoading(false);
    }
  }

  const Chips = <T extends string | number>({
    items,
    value,
    onPick,
    label,
  }: {
    items: { key: T; label: string }[];
    value: T;
    onPick: (v: T) => void;
    label: string;
  }) => (
    <div className="field">
      <label>{label}</label>
      <div className="chips">
        {items.map((it) => (
          <button
            key={String(it.key)}
            type="button"
            className={`chip ${value === it.key ? "on" : ""}`}
            onClick={() => onPick(it.key)}
          >
            {it.label}
          </button>
        ))}
      </div>
    </div>
  );

  return (
    <main className="grid cols2" style={{ alignItems: "start" }}>
      <div className="card">
        <h2 className="section-title" style={{ fontSize: 16 }}>
          🎬 ولّد سكريبت
        </h2>

        <Chips
          label="نوع المحتوى"
          items={Object.keys(THEMES).map((k) => ({ key: k, label: k }))}
          value={theme}
          onPick={setTheme}
        />

        <div className="field">
          <label>الفكرة (اختياري)</label>
          <textarea
            rows={3}
            placeholder="مثلاً: AI يلقى bug في الكود متاعي…"
            value={idea}
            onChange={(e) => setIdea(e.target.value)}
            maxLength={500}
          />
        </div>

        <Chips
          label="طريقة العرض"
          items={Object.keys(MODES).map((k) => ({ key: k, label: k }))}
          value={mode}
          onPick={setMode}
        />

        <Chips
          label="المدّة"
          items={DURATIONS.map((d) => ({ key: d, label: `${d}s` }))}
          value={duration}
          onPick={setDuration}
        />

        <div className="field">
          <label>الموديل</label>
          <select
            value={model}
            onChange={(e) => setModel(e.target.value)}
            style={{
              width: "100%",
              background: "var(--bg-2)",
              border: "1px solid var(--border)",
              borderRadius: 12,
              color: "var(--text-high)",
              padding: "11px 13px",
              font: "inherit",
              direction: "ltr",
            }}
          >
            {MODELS.map((m) => (
              <option key={m} value={m}>
                {m}
              </option>
            ))}
          </select>
        </div>

        <button className="btn" onClick={generate} disabled={loading}>
          {loading ? "نحضّر… (20–60 ثانية)" : "حضّرلي الفيديو"}
        </button>

        {error && (
          <p style={{ color: "var(--rose)", marginTop: 12, fontSize: 14 }}>⚠️ {error}</p>
        )}
      </div>

      <div>
        {demo && (
          <div className="banner">
            ⚠️ سكريبت تجريبي. ثبّت <code>BACKEND_URL</code> و <code>APP_TOKEN</code> باش
            يولّد بالحقّ.
          </div>
        )}
        {script ? (
          <ScriptResult script={script} />
        ) : (
          <div className="card">
            <p className="muted">
              اختار النوع والمدّة واضغط «حضّرلي الفيديو» باش يبان السكريبت هنا. 🎥
            </p>
          </div>
        )}
      </div>
    </main>
  );
}
