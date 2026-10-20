export type UsageRow = {
  created_at: string;
  model: string;
  ok: boolean;
  status: number;
  ms: number | null;
};

export type ModelStat = {
  model: string;
  count: number;
  okRate: number; // 0..1
  avgMs: number;
};

export type Stats = {
  demo: boolean;
  total: number;
  month: number;
  okRate: number; // 0..1
  avgMs: number;
  byDay: { day: string; count: number }[];
  byModel: { model: string; count: number }[];
  byHour: { hour: number; count: number }[]; // 0..23
  latencyByDay: { day: string; ms: number }[];
  models: ModelStat[];
  statuses: { status: number; count: number }[];
  recent: UsageRow[];
};

// ----- شكل السكريبت اللي يرجّعه التوليد (نفس الـapp) -----
export type Segment = {
  from: number;
  to: number;
  screen: string;
  text: string;
  voice: string;
};

export type Script = {
  title: string;
  hook_idea?: string;
  segments: Segment[];
  code?: string;
  code_note?: string;
  steps?: { title: string; detail: string }[];
  caption?: string;
  hashtags?: string[];
  tips?: string[];
};
