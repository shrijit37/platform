-- auth-service fleet schema (Supabase project rjrynmjugsxuytpotfma).
--
-- Supabase Auth owns identity, sessions, OAuth and the users table. The hub
-- only needs its own organization/membership rows; it reaches them with the
-- service_role key, which bypasses RLS. The permissive anon/authenticated
-- policies below let fleet spokes read and join membership with the
-- publishable key if they query these tables directly.
--
-- Apply with the Supabase SQL editor or `supabase db push`. Safe to re-run.

create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  logo text,
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations (id) on delete cascade,
  user_id uuid not null
    references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

create index if not exists members_user_id_idx on public.members (user_id);

-- Service_role already bypasses RLS; these policies are for spokes using the
-- publishable key. Deliberately open, matching the hub's open self-join gate.
alter table public.organizations enable row level security;
alter table public.members enable row level security;

drop policy if exists "fleet organizations full access" on public.organizations;
create policy "fleet organizations full access"
  on public.organizations for all to anon, authenticated
  using (true) with check (true);

drop policy if exists "fleet members full access" on public.members;
create policy "fleet members full access"
  on public.members for all to anon, authenticated
  using (true) with check (true);

grant select, insert, update, delete on public.organizations, public.members to anon, authenticated;
