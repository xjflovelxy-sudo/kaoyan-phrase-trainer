-- V40真正逐项云同步：Supabase SQL Editor执行一次。不会删除旧study_state。
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
create index if not exists study_progress_items_user_updated_idx on public.study_progress_items(user_id,updated_at desc);
alter table public.study_progress_items enable row level security;
do $$ begin
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='study_progress_items' and policyname='v40_select_own') then create policy v40_select_own on public.study_progress_items for select using(auth.uid()=user_id); end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='study_progress_items' and policyname='v40_insert_own') then create policy v40_insert_own on public.study_progress_items for insert with check(auth.uid()=user_id); end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='study_progress_items' and policyname='v40_update_own') then create policy v40_update_own on public.study_progress_items for update using(auth.uid()=user_id) with check(auth.uid()=user_id); end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='study_progress_items' and policyname='v40_delete_own') then create policy v40_delete_own on public.study_progress_items for delete using(auth.uid()=user_id); end if;
end $$;
