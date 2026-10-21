-- مزامنة الـhistorique بين الأجهزة (V2 — حسابات).
-- كل مستخدم يشوف سكريبتاتو برك (RLS). المفتاح الطبيعي: (user_id, created_at)
-- باش نفس السكريبت ما يتعاودش كي نزامنو من عدّة أجهزة.
create table if not exists public.scripts (
  id           uuid        default gen_random_uuid() primary key,
  user_id      uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  created_at   bigint      not null,          -- createdAt متاع العميل (clé naturelle)
  title        text        not null,
  category     text        not null,
  style        text        not null,
  duration     int         not null,
  content      text        not null,
  model        text        default '',
  is_favorite  boolean     default false,
  published_at bigint,
  views        int,
  likes        int,
  comments     int,
  series_title text,
  episode      int,
  updated_at   timestamptz default now(),
  unique (user_id, created_at)
);

create index if not exists scripts_user_idx on public.scripts (user_id, created_at desc);

alter table public.scripts enable row level security;

-- كل عمليّة (select/insert/update/delete) محدودة لصاحب الصفّ
create policy "own scripts" on public.scripts
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
