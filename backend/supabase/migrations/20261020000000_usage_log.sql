-- جدول تسجيل الاستعمال: صفّ لكل طلب توليد يعدّي من الـEdge Function.
-- تقراه الداشبورد (Next.js) عبر service role.
create table if not exists public.usage_log (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  model      text        not null,
  ok         boolean     not null,
  status     int         not null,
  ms         int,
  source     text        default 'app'
);

create index if not exists usage_log_created_idx on public.usage_log (created_at desc);
create index if not exists usage_log_model_idx   on public.usage_log (model);

-- RLS مفعّل بلا policies: service role برك (السيرفر) ينجّم يكتب/يقرا.
-- الـanon/public ما عندهمش دخول.
alter table public.usage_log enable row level security;
