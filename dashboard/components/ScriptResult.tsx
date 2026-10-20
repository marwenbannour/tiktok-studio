import type { Script } from "@/lib/types";

const two = (n: number) => String(n).padStart(2, "0");
const t = (n: number) => `${two(Math.floor(n / 60))}:${two(n % 60)}`;

export default function ScriptResult({ script }: { script: Script }) {
  return (
    <div className="card">
      <h2 className="section-title" style={{ fontSize: 17 }}>
        {script.title}
      </h2>
      {script.hook_idea && <p className="muted">{script.hook_idea}</p>}

      <h3 className="section-title" style={{ marginTop: 16 }}>
        🎬 المقاطع
      </h3>
      {script.segments?.map((seg, i) => (
        <div className="seg" key={i}>
          <div className="time">
            {t(seg.from)}–{t(seg.to)}
          </div>
          <div>
            <div className="screen">🖥️ {seg.screen}</div>
            <div className="voice">🎙️ {seg.voice}</div>
            {seg.text && (
              <div className="muted" style={{ marginTop: 2 }}>
                📝 {seg.text}
              </div>
            )}
          </div>
        </div>
      ))}

      {script.code && (
        <>
          <h3 className="section-title" style={{ marginTop: 16 }}>
            💻 مثال كود
          </h3>
          <pre className="code">{script.code}</pre>
          {script.code_note && <p className="muted">{script.code_note}</p>}
        </>
      )}

      {script.steps && script.steps.length > 0 && (
        <>
          <h3 className="section-title" style={{ marginTop: 16 }}>
            🎞️ خطوات التصوير والمونتاج
          </h3>
          {script.steps.map((st, i) => (
            <div key={i} style={{ marginBottom: 8 }}>
              <strong>{st.title}</strong>
              <div className="muted">{st.detail}</div>
            </div>
          ))}
        </>
      )}

      {script.caption && (
        <>
          <h3 className="section-title" style={{ marginTop: 16 }}>
            ✍️ الوصف
          </h3>
          <p>{script.caption}</p>
        </>
      )}

      {script.hashtags && script.hashtags.length > 0 && (
        <div className="tags" style={{ marginTop: 8 }}>
          {script.hashtags.map((h, i) => (
            <span className="tag" key={i}>
              {h}
            </span>
          ))}
        </div>
      )}

      {script.tips && script.tips.length > 0 && (
        <>
          <h3 className="section-title" style={{ marginTop: 16 }}>
            💡 نصائح
          </h3>
          <ul className="muted" style={{ margin: 0, paddingInlineStart: 18 }}>
            {script.tips.map((tip, i) => (
              <li key={i}>{tip}</li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
