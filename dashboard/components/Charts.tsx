"use client";

import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  LabelList,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

const CYAN = "#00e5ff";
const GRID = "#1b2947";
const AXIS = "#22304d";
const INK_MID = "#9fb0c9";

function Tip({
  active,
  label,
  value,
  unit,
}: {
  active?: boolean;
  label?: string;
  value?: number | string;
  unit: string;
}) {
  if (!active) return null;
  return (
    <div
      style={{
        background: "#0a1020",
        border: "1px solid #22304d",
        borderRadius: 10,
        padding: "8px 11px",
        fontSize: 12,
        color: "#eef3fb",
        boxShadow: "0 8px 24px rgba(0,0,0,.4)",
      }}
    >
      <div style={{ color: INK_MID, marginBottom: 3 }}>{label}</div>
      <div style={{ fontWeight: 700 }}>
        {value} <span style={{ color: INK_MID, fontWeight: 400 }}>{unit}</span>
      </div>
    </div>
  );
}

/** توليدات في الوقت (14 يوم) — سلسلة وحيدة، لون واحد (cyan) */
export function UsageChart({ data }: { data: { day: string; count: number }[] }) {
  const short = (d: string) => d.slice(5); // MM-DD
  return (
    <ResponsiveContainer width="100%" height={240}>
      <AreaChart data={data} margin={{ top: 10, right: 14, left: -14, bottom: 0 }}>
        <defs>
          <linearGradient id="cyanFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={CYAN} stopOpacity={0.35} />
            <stop offset="100%" stopColor={CYAN} stopOpacity={0.02} />
          </linearGradient>
        </defs>
        <CartesianGrid stroke={GRID} vertical={false} />
        <XAxis
          dataKey="day"
          tickFormatter={short}
          tick={{ fill: INK_MID, fontSize: 11 }}
          tickLine={false}
          axisLine={{ stroke: AXIS }}
          minTickGap={16}
        />
        <YAxis
          allowDecimals={false}
          tick={{ fill: INK_MID, fontSize: 11 }}
          tickLine={false}
          axisLine={false}
          width={34}
        />
        <Tooltip
          cursor={{ stroke: AXIS }}
          content={({ active, payload, label }) => (
            <Tip
              active={active}
              label={label as string}
              value={payload?.[0]?.value as number}
              unit="توليدة"
            />
          )}
        />
        <Area
          type="monotone"
          dataKey="count"
          stroke={CYAN}
          strokeWidth={2}
          fill="url(#cyanFill)"
          dot={false}
          activeDot={{ r: 4, fill: CYAN, stroke: "#0a1020", strokeWidth: 2 }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

/** توليدات حسب الموديل — مقدار، لون واحد (cyan) + labels مباشرة */
export function ModelBar({ data }: { data: { model: string; count: number }[] }) {
  return (
    <ResponsiveContainer width="100%" height={Math.max(130, data.length * 46)}>
      <BarChart
        data={data}
        layout="vertical"
        margin={{ top: 4, right: 40, left: 6, bottom: 4 }}
      >
        <XAxis type="number" hide />
        <YAxis
          type="category"
          dataKey="model"
          width={118}
          tick={{ fill: INK_MID, fontSize: 12 }}
          tickLine={false}
          axisLine={false}
        />
        <Tooltip
          cursor={{ fill: "rgba(255,255,255,.04)" }}
          content={({ active, payload }) => (
            <Tip
              active={active}
              label={payload?.[0]?.payload?.model}
              value={payload?.[0]?.value as number}
              unit="توليدة"
            />
          )}
        />
        <Bar dataKey="count" fill={CYAN} radius={[0, 4, 4, 0]} barSize={16}>
          <LabelList dataKey="count" position="right" fill={INK_MID} fontSize={12} />
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}

/** متوسّط زمن الردّ (ms) في الوقت — سلسلة وحيدة cyan */
export function LatencyChart({ data }: { data: { day: string; ms: number }[] }) {
  const short = (d: string) => d.slice(5);
  return (
    <ResponsiveContainer width="100%" height={240}>
      <AreaChart data={data} margin={{ top: 10, right: 14, left: -6, bottom: 0 }}>
        <defs>
          <linearGradient id="cyanFill2" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={CYAN} stopOpacity={0.3} />
            <stop offset="100%" stopColor={CYAN} stopOpacity={0.02} />
          </linearGradient>
        </defs>
        <CartesianGrid stroke={GRID} vertical={false} />
        <XAxis
          dataKey="day"
          tickFormatter={short}
          tick={{ fill: INK_MID, fontSize: 11 }}
          tickLine={false}
          axisLine={{ stroke: AXIS }}
          minTickGap={16}
        />
        <YAxis
          tickFormatter={(v) => `${(v / 1000).toFixed(0)}s`}
          tick={{ fill: INK_MID, fontSize: 11 }}
          tickLine={false}
          axisLine={false}
          width={38}
        />
        <Tooltip
          cursor={{ stroke: AXIS }}
          content={({ active, payload, label }) => (
            <Tip
              active={active}
              label={label as string}
              value={payload?.[0]?.value ? ((payload[0].value as number) / 1000).toFixed(1) : 0}
              unit="ثانية"
            />
          )}
        />
        <Area
          type="monotone"
          dataKey="ms"
          stroke={CYAN}
          strokeWidth={2}
          fill="url(#cyanFill2)"
          dot={false}
          activeDot={{ r: 4, fill: CYAN, stroke: "#0a1020", strokeWidth: 2 }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

/** النشاط حسب ساعة اليوم (0–23) — أعمدة cyan */
export function HourBar({ data }: { data: { hour: number; count: number }[] }) {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={data} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
        <CartesianGrid stroke={GRID} vertical={false} />
        <XAxis
          dataKey="hour"
          tickFormatter={(h) => `${h}`}
          tick={{ fill: INK_MID, fontSize: 10 }}
          tickLine={false}
          axisLine={{ stroke: AXIS }}
          interval={2}
        />
        <YAxis
          allowDecimals={false}
          tick={{ fill: INK_MID, fontSize: 11 }}
          tickLine={false}
          axisLine={false}
          width={28}
        />
        <Tooltip
          cursor={{ fill: "rgba(255,255,255,.04)" }}
          content={({ active, payload }) => (
            <Tip
              active={active}
              label={`الساعة ${payload?.[0]?.payload?.hour}:00`}
              value={payload?.[0]?.value as number}
              unit="توليدة"
            />
          )}
        />
        <Bar dataKey="count" fill={CYAN} radius={[3, 3, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}

/** نسبة النجاح لكل موديل — أعمدة أفقية cyan (0–100%) */
export function SuccessBar({ data }: { data: { model: string; okRate: number }[] }) {
  const rows = data.map((d) => ({ model: d.model, pct: Math.round(d.okRate * 100) }));
  return (
    <ResponsiveContainer width="100%" height={Math.max(130, rows.length * 46)}>
      <BarChart data={rows} layout="vertical" margin={{ top: 4, right: 44, left: 6, bottom: 4 }}>
        <XAxis type="number" domain={[0, 100]} hide />
        <YAxis
          type="category"
          dataKey="model"
          width={118}
          tick={{ fill: INK_MID, fontSize: 12 }}
          tickLine={false}
          axisLine={false}
        />
        <Tooltip
          cursor={{ fill: "rgba(255,255,255,.04)" }}
          content={({ active, payload }) => (
            <Tip
              active={active}
              label={payload?.[0]?.payload?.model}
              value={payload?.[0]?.value as number}
              unit="% نجاح"
            />
          )}
        />
        <Bar dataKey="pct" fill={CYAN} radius={[0, 4, 4, 0]} barSize={16}>
          <LabelList dataKey="pct" position="right" fill={INK_MID} fontSize={12} formatter={(v: number) => `${v}%`} />
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
