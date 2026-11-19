-- Tdrive Zero-knowledge fleet schema.
-- Migrated from server-ts SQLite (files, chunks, jobs). The API reaches this
-- schema exclusively over the Supabase HTTP gateway with the service-role key;
-- raw Postgres connections are not used by the deployed container.
-- RLS is enabled with permissive policies because access control lives in the
-- API layer. Run with: supabase db push (or paste into the Studio SQL editor).

create table if not exists public.files (
  file_id text primary key,
  file_uuid text,
  filename text not null,
  virtual_path text not null,
  size bigint not null default 0,
  sha256 text not null default '',
  chunk_count integer not null default 0,
  encrypted integer not null default 0,
  is_folder integer not null default 0,
  thumbnail text,
  status text not null default 'completed',
  sync_status text not null default 'synced',
  is_starred integer not null default 0,
  is_trashed integer not null default 0,
  deleted_at text,
  original_path text,
  is_materialized integer not null default 0,
  storage_provider text,
  -- SQLite datetime('now') shape: UTC "YYYY-MM-DD HH:MM:SS" kept as text so
  -- the S3 Last-Modified parser and lexicographic ordering are unchanged.
  created_at text not null default ''
);

create index if not exists idx_files_virtual_path on public.files (virtual_path, is_trashed);
create index if not exists idx_files_sha256 on public.files (sha256);
create index if not exists idx_files_file_uuid on public.files (file_uuid);

create table if not exists public.chunks (
  chunk_id text primary key,
  file_id text not null references public.files(file_id) on delete cascade,
  sequence integer not null,
  msg_id bigint not null,
  channel_id text not null,
  chunk_size integer not null,
  chunk_sha256 text not null
);

create index if not exists idx_chunks_file on public.chunks (file_id, sequence);

create table if not exists public.jobs (
  job_id text primary key default gen_random_uuid()::text,
  status text,
  created_at text,
  payload jsonb
);

alter table public.files enable row level security;
alter table public.chunks enable row level security;
alter table public.jobs enable row level security;

drop policy if exists "tdrive_all_files" on public.files;
create policy "tdrive_all_files" on public.files
  for all to anon, authenticated, service_role using (true) with check (true);

drop policy if exists "tdrive_all_chunks" on public.chunks;
create policy "tdrive_all_chunks" on public.chunks
  for all to anon, authenticated, service_role using (true) with check (true);

drop policy if exists "tdrive_all_jobs" on public.jobs;
create policy "tdrive_all_jobs" on public.jobs
  for all to anon, authenticated, service_role using (true) with check (true);
