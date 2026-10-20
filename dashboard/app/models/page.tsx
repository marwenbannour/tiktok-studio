import { ModelBar, SuccessBar } from "@/components/Charts";
import { getStats } from "@/lib/stats";

export const dynamic = "force-dynamic";

function statusBadge(status: number) {
  if (status >= 200 && status < 300) return <span className="badge ok">✓ {status}</span>;
  if (status >= 400 && status < 500) return <span className="badge warn">⚠ {status}</span>;
  return <span className="badge err">✕ {status}</span>;
}

export default async function ModelsPage() {
  const s = await getStats();

  return (
    <main>
      {s.demo && (
        <div className="banner">
          ⚠️ بيانات تجريبية (demo). ثبّت <code>SUPABASE_URL</code> و{" "}
          <code>SUPABASE_SERVICE_ROLE_KEY</code> باش تشوف الاستعمال الحقيقي.
        </div>
      )}

      <div className="grid cols2">
        <div className="card">
          <h2 className="section-title">🧠 التوليدات حسب الموديل</h2>
          {s.byModel.length ? (
            <ModelBar data={s.byModel} />
          ) : (
            <p className="muted">ما فماش بيانات بعد.</p>
          )}
        </div>
        <div className="card">
          <h2 className="section-title">✅ نسبة النجاح حسب الموديل</h2>
          {s.models.length ? (
            <SuccessBar data={s.models} />
          ) : (
            <p className="muted">ما فماش بيانات بعد.</p>
          )}
        </div>
      </div>

      <div className="card" style={{ marginTop: 14 }}>
        <h2 className="section-title">📋 تفاصيل الموديلات</h2>
        {s.models.length ? (
          <table>
            <thead>
              <tr>
                <th>الموديل</th>
                <th>توليدات</th>
                <th>نجاح</th>
                <th>متوسّط المدّة</th>
              </tr>
            </thead>
            <tbody>
              {s.models.map((m) => (
                <tr key={m.model}>
                  <td style={{ direction: "ltr", textAlign: "start" }}>{m.model}</td>
                  <td>{m.count}</td>
                  <td
                    style={{
                      color:
                        m.okRate >= 0.9 ? "var(--success)" : "var(--warning)",
                      fontWeight: 700,
                    }}
                  >
                    {Math.round(m.okRate * 100)}%
                  </td>
                  <td>{(m.avgMs / 1000).toFixed(1)}s</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="muted">ما فماش بيانات بعد.</p>
        )}
      </div>

      <div className="card" style={{ marginTop: 14 }}>
        <h2 className="section-title">🚦 حسب رمز الحالة (status)</h2>
        {s.statuses.length ? (
          <div className="tags" style={{ gap: 16 }}>
            {s.statuses.map((st) => (
              <span key={st.status}>
                {statusBadge(st.status)}{" "}
                <span className="muted">× {st.count}</span>
              </span>
            ))}
          </div>
        ) : (
          <p className="muted">ما فماش بيانات بعد.</p>
        )}
      </div>
    </main>
  );
}
