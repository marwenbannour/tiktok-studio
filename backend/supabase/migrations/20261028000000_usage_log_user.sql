-- usage_log: نربطو كل طلب بالمستعمل باش نطبّقو الحدّ اليومي لكل واحد.
-- user_id = null → طلب صاحب المشروع (x-app-token، source = 'owner').
alter table public.usage_log
  add column if not exists user_id uuid references auth.users (id) on delete set null;

create index if not exists usage_log_user_day_idx
  on public.usage_log (user_id, created_at desc);
create index if not exists usage_log_source_day_idx
  on public.usage_log (source, created_at desc);

-- RLS: مازال بلا policies → service role برك يقرا/يكتب.
