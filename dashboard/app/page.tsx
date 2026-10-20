import { HourBar, LatencyChart, ModelBar, UsageChart } from "@/components/Charts";
import { getStats } from "@/lib/stats";

export const dynamic = "force-dynamic";

function fmtTime(iso: string): string {
  const d = new Date(iso);
  const p = (n: number) => String(n).padStart(2, "0");
  return `${p(d.getDate())}/${p(d.getMonth() + 1)} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

export default async function DashboardPage() {
  const s = await getStats();
  const okPct = Math.round(s.okRate * 100);

  return (
    <main>
      {s.demo && (
        <div className="banner">
          ⚠️ بيانات تجريبية (demo). ثبّت <code>SUPABASE_URL</code> و{" "}
          <code>SUPABASE_SERVICE_ROLE_KEY</code> باش تشوف الاستعمال الحقيقي.
        </div>
      )}

      <div className="grid tiles">
        <div className="card tile">
          <div className="label">📝 التوليدات (14 يوم)</div>
          <div className="value" style={{ color: "var(--text-high)" }}>
            {s.total}
          </div>
          <div className="hint">كل الطلبات اللي عدّاو من السيرفر</div>
        </div>
        <div className="card tile">
          <div className="label">📅 هالشهر</div>
          <div className="value" style={{ color: "var(--cyan)" }}>
            {s.month}
          </div>
          <div className="hint">عدد التوليدات في الشهر الحالي</div>
        </div>
        <div className="card tile">
          <div className="label">✅ نسبة النجاح</div>
          <div
            className="value"
            style={{ color: okPct >= 90 ? "var(--success)" : "var(--warning)" }}
          >
            {okPct}%
          </div>
          <div className="hint">طلبات رجّعت 200</div>
        </div>
        <div className="card tile">
          <div className="label">⏱️ متوسّط المدّة</div>
          <div className="value" style={{ color: "var(--text-high)" }}>
            {(s.avgMs / 1000).toFixed(1)}
            <span style={{ fontSize: 15, color: "var(--text-mid)" }}> ثانية</span>
          </div>
          <div className="hint">وقت ردّ Ollama</div>
        </div>
      </div>

      <div className="grid cols2" style={{ marginTop: 14 }}>
        <div className="card">
          <h2 className="section-title">📈 التوليدات في الوقت (14 يوم)</h2>
          <UsageChart data={s.byDay} />
        </div>
        <div className="card">
          <h2 className="section-title">🧠 حسب الموديل</h2>
          {s.byModel.length ? (
            <ModelBar data={s.byModel} />
          ) : (
            <p className="muted">ما فماش بيانات بعد.</p>
          )}
        </div>
      </div>

      <div className="grid cols2" style={{ marginTop: 14 }}>
        <div className="card">
          <h2 className="section-title">⏱️ زمن الردّ (14 يوم)</h2>
          <LatencyChart data={s.latencyByDay} />
        </div>
        <div className="card">
          <h2 className="section-title">🕐 النشاط حسب الساعة</h2>
          <HourBar data={s.byHour} />
        </div>
      </div>

      <div className="card" style={{ marginTop: 14 }}>
        <h2 className="section-title">🕑 آخر الطلبات</h2>
        {s.recent.length ? (
          <table>
            <thead>
              <tr>
                <th>الوقت</th>
                <th>الموديل</th>
                <th>الحالة</th>
                <th>المدّة</th>
              </tr>
            </thead>
            <tbody>
              {s.recent.map((r, i) => (
                <tr key={i}>
                  <td>{fmtTime(r.created_at)}</td>
                  <td style={{ direction: "ltr", textAlign: "start" }}>{r.model}</td>
                  <td>
                    {r.ok ? (
                      <span className="badge ok">✓ {r.status}</span>
                    ) : (
                      <span className="badge err">✕ {r.status}</span>
                    )}
                  </td>
                  <td>{r.ms != null ? `${(r.ms / 1000).toFixed(1)}s` : "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="muted">ما فماش طلبات بعد.</p>
        )}
      </div>
    </main>
  );
}
