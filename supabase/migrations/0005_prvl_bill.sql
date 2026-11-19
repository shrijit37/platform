-- 0001: fleet schema for bill-generator monthly persistence.
-- Applied through the Supabase project (SQL editor / `supabase db push`),
-- not via the repo's psql-based `make migrate`. The app writes over the
-- public PostgREST gateway with the service-role key.
-- One row per billing month; settings/vals/readings are JSON documents.
create table if not exists public.months (
    month      text primary key,
    settings   jsonb not null default '{}'::jsonb,
    vals       jsonb not null default '{}'::jsonb,
    readings   jsonb not null default '{}'::jsonb,
    updated_at timestamptz not null default now()
);

alter table public.months enable row level security;

-- Permissive policy: the service-role key authenticates the app over the
-- gateway (and bypasses RLS); anon/authenticated are included for parity.
drop policy if exists "months_all" on public.months;
create policy "months_all"
    on public.months
    for all
    to anon, authenticated, service_role
    using (true)
    with check (true);

-- Explicit grants so the PostgREST roles can reach the table regardless of
-- how the project's default privileges were configured.
grant all on public.months to anon, authenticated, service_role;
