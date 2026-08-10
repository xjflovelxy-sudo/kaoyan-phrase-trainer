-- V43 多账号独立使用：在 Supabase SQL Editor 执行一次。
-- 不删除学习数据；只建立/检查同步表，并把这两个专用进度表的 RLS 统一为“只能访问自己的 user_id”。

create table if not exists public.study_progress_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  item_key text not null,
  data jsonb,
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  device_id text not null default '',
  deleted boolean not null default false,
  primary key (user_id,item_key)
);
create index if not exists study_progress_items_user_updated_idx
  on public.study_progress_items(user_id,updated_at desc);

alter table public.study_progress_items enable row level security;
alter table public.study_progress_items force row level security;

do $$
declare p record;
begin
  -- 该表只给本应用保存学习进度；清掉旧策略后统一重建，避免宽松旧策略与新策略 OR 叠加。
  for p in select policyname from pg_policies where schemaname='public' and tablename='study_progress_items'
  loop
    execute format('drop policy if exists %I on public.study_progress_items', p.policyname);
  end loop;
end $$;

create policy v43_progress_select_own on public.study_progress_items
  for select using (auth.uid() = user_id);
create policy v43_progress_insert_own on public.study_progress_items
  for insert with check (auth.uid() = user_id);
create policy v43_progress_update_own on public.study_progress_items
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy v43_progress_delete_own on public.study_progress_items
  for delete using (auth.uid() = user_id);

-- V40回退用的旧整包表如果存在，也统一成相同的账号隔离规则。
do $$
declare p record;
begin
  if to_regclass('public.study_state') is not null then
    execute 'alter table public.study_state enable row level security';
    execute 'alter table public.study_state force row level security';
    for p in select policyname from pg_policies where schemaname='public' and tablename='study_state'
    loop
      execute format('drop policy if exists %I on public.study_state', p.policyname);
    end loop;
    execute 'create policy v43_state_select_own on public.study_state for select using (auth.uid() = user_id)';
    execute 'create policy v43_state_insert_own on public.study_state for insert with check (auth.uid() = user_id)';
    execute 'create policy v43_state_update_own on public.study_state for update using (auth.uid() = user_id) with check (auth.uid() = user_id)';
    execute 'create policy v43_state_delete_own on public.study_state for delete using (auth.uid() = user_id)';
  end if;
end $$;
