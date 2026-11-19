-- OpenTV fleet schema (Supabase / Postgres).
-- Maps the former MongoDB collections and the Appwrite `profiles` collection
-- onto Postgres tables. Column names are kept camelCase/quoted where the
-- TypeScript types use them, so the app needs no field renaming.

-- Local profiles (formerly Appwrite `profiles` / Mongo `users`).
create table if not exists public.profiles (
  _id uuid primary key default gen_random_uuid(),
  "authId" text not null unique,
  username text not null,
  role text not null default 'member' check (role in ('owner', 'member')),
  "createdAt" timestamptz not null default now()
);

-- Watch history (Mongo `watch_history`).
create table if not exists public.watch_history (
  _id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references public.profiles(_id) on delete cascade,
  "mediaType" text not null check ("mediaType" in ('movie', 'tv', 'anime')),
  "mediaId" bigint not null,
  "animeKind" text check ("animeKind" in ('movie', 'tv')),
  title text not null,
  season integer,
  episode integer,
  "positionSeconds" integer,
  "watchedAt" timestamptz not null default now()
);

-- Resume/progress state (Mongo `resume_state`).
create table if not exists public.resume_state (
  _id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references public.profiles(_id) on delete cascade,
  "mediaType" text not null check ("mediaType" in ('movie', 'tv', 'anime')),
  "mediaId" bigint not null,
  "animeKind" text check ("animeKind" in ('movie', 'tv')),
  "resumeKey" text not null,
  title text not null,
  "seasonKey" integer not null default 0,
  "episodeKey" integer not null default 0,
  season integer,
  episode integer,
  "positionSeconds" integer not null default 0,
  "updatedAt" timestamptz not null default now(),
  constraint resume_state_user_resume_key unique ("userId", "resumeKey")
);

-- Continue-watching markers (Mongo `continueWatching`, used by the person page).
create table if not exists public.continue_watching (
  _id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references public.profiles(_id) on delete cascade,
  "mediaType" text,
  "mediaId" bigint not null,
  "animeKind" text,
  title text,
  "positionSeconds" integer not null default 0,
  finished boolean not null default false,
  "updatedAt" timestamptz not null default now(),
  constraint continue_watching_user_media unique ("userId", "mediaType", "mediaId")
);

-- Legacy invite codes (Mongo `invites`) — kept for schema parity.
create table if not exists public.invites (
  _id uuid primary key default gen_random_uuid(),
  "invitedBy" uuid references public.profiles(_id) on delete set null,
  email text not null,
  "createdAt" timestamptz not null default now(),
  constraint invites_owner_email_unique unique ("invitedBy", email)
);

-- Login attempts (Mongo `login_logs`).
create table if not exists public.login_logs (
  _id uuid primary key default gen_random_uuid(),
  "timestamp" timestamptz not null default now(),
  username text,
  ip text not null default '',
  success boolean not null default false,
  "userAgent" text,
  city text,
  country text,
  "countryCode" text
);

-- Watch activity (Mongo `watch_logs`).
create table if not exists public.watch_logs (
  _id uuid primary key default gen_random_uuid(),
  "userId" uuid references public.profiles(_id) on delete set null,
  username text not null,
  "mediaType" text not null check ("mediaType" in ('movie', 'tv', 'anime')),
  "mediaId" bigint not null,
  "animeKind" text check ("animeKind" in ('movie', 'tv')),
  title text not null,
  season integer,
  episode integer,
  ip text not null default '',
  city text,
  country text,
  "countryCode" text,
  "watchedAt" timestamptz not null default now()
);

-- Indexes replacing the former Mongo index declarations.
create index if not exists watch_history_user_watched_at on public.watch_history ("userId", "watchedAt" desc);
create index if not exists continue_watching_user_id on public.continue_watching ("userId");
create index if not exists resume_state_user_updated_at on public.resume_state ("userId", "updatedAt" desc);
create index if not exists login_logs_timestamp on public.login_logs ("timestamp" desc);
create index if not exists login_logs_username_timestamp on public.login_logs (username, "timestamp" desc);
create index if not exists watch_logs_watched_at on public.watch_logs ("watchedAt" desc);
create index if not exists watch_logs_username_watched_at on public.watch_logs (username, "watchedAt" desc);
create index if not exists watch_logs_user_id_watched_at on public.watch_logs ("userId", "watchedAt" desc);

-- Aggregations used by the admin activity page (replaces Mongo $facet).
create or replace function public.get_activity_stats()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'loginStats', jsonb_build_object(
      'totalLogins', (select count(*)::int from public.login_logs),
      'successfulLogins', (select count(*)::int from public.login_logs where success = true),
      'failedLogins', (select count(*)::int from public.login_logs where success = false),
      'recentLogins', (select count(*)::int from public.login_logs where "timestamp" >= now() - interval '24 hours')
    ),
    'watchStats', jsonb_build_object(
      'totalWatches', (select count(*)::int from public.watch_logs),
      'recentWatches', (select count(*)::int from public.watch_logs where "watchedAt" >= now() - interval '24 hours'),
      'weeklyWatches', (select count(*)::int from public.watch_logs where "watchedAt" >= now() - interval '7 days'),
      'topUsers', coalesce((
        select jsonb_agg(jsonb_build_object('username', username, 'count', cnt) order by cnt desc)
        from (select username, count(*)::int as cnt from public.watch_logs group by username order by cnt desc limit 5) as u
      ), '[]'::jsonb),
      'topContent', coalesce((
        select jsonb_agg(jsonb_build_object(
          '_id', jsonb_build_object('mediaId', media_id, 'title', title),
          'count', cnt
        ) order by cnt desc)
        from (
          select "mediaId" as media_id, title, count(*)::int as cnt
          from public.watch_logs
          group by "mediaId", title
          order by cnt desc
          limit 10
        ) as c
      ), '[]'::jsonb)
    )
  );
$$;

-- This is a single-tenant internal app: permissive RLS for anon/authenticated.
do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'watch_history', 'resume_state', 'continue_watching',
    'invites', 'login_logs', 'watch_logs'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "opentv_full_access" on public.%I', t);
    execute format(
      'create policy "opentv_full_access" on public.%I for all to anon, authenticated using (true) with check (true)',
      t
    );
    execute format(
      'grant select, insert, update, delete on public.%I to anon, authenticated, service_role',
      t
    );
  end loop;
end $$;

grant usage on schema public to anon, authenticated, service_role;
grant execute on function public.get_activity_stats() to anon, authenticated, service_role;
