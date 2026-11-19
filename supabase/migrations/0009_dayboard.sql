-- Dayboard board storage on the shared supabase-multitenant `fleet` project.
-- One row per (day, user): a whole-day save is a single UPDATE. `rev` provides
-- optimistic concurrency so concurrent tabs surface a 409 instead of clobbering.

create table if not exists public.boards (
  day text not null,
  user_id text not null default 'default',
  tasks jsonb not null default '[]'::jsonb,
  updated_at timestamptz,
  rev integer not null default 0,
  primary key (day, user_id)
);

alter table public.boards enable row level security;

drop policy if exists boards_all on public.boards;
create policy boards_all on public.boards
  for all to anon, authenticated
  using (true) with check (true);

grant all on public.boards to anon, authenticated, service_role;
