-- LLMBridge fleet stats store.
--
-- The gateway runs inside Coolify and cannot open a raw Postgres socket, so it
-- uses the public HTTP gateway (PostgREST) via @supabase/supabase-js with the
-- service-role key. This migration must be applied through Supabase's SQL
-- editor / migration tooling (it is DDL and cannot be run through PostgREST).
--
-- Every table is prefixed with `llmbridge_` to avoid collisions with the other
-- fleet tenants (a `public.request_logs` table already exists).
--
-- Idempotent: safe to re-run.

-- Provider-level rolling stats ------------------------------------------------
create table if not exists public.llmbridge_provider_stats (
  provider_id   text primary key,
  provider_name text not null,
  input         bigint not null default 0,
  output        bigint not null default 0,
  requests      bigint not null default 0,
  failures      bigint not null default 0,
  latency_total bigint not null default 0,
  quota_output  text
);

create index if not exists llmbridge_provider_stats_requests_idx
  on public.llmbridge_provider_stats (requests desc);

alter table public.llmbridge_provider_stats enable row level security;
drop policy if exists llmbridge_provider_stats_all on public.llmbridge_provider_stats;
create policy llmbridge_provider_stats_all
  on public.llmbridge_provider_stats
  for all to anon, authenticated, service_role
  using (true) with check (true);

-- Per-model usage stats -------------------------------------------------------
create table if not exists public.llmbridge_model_stats (
  provider_id   text not null,
  provider_name text not null,
  model_name    text not null,
  input         bigint not null default 0,
  output        bigint not null default 0,
  primary key (provider_id, model_name)
);

alter table public.llmbridge_model_stats enable row level security;
drop policy if exists llmbridge_model_stats_all on public.llmbridge_model_stats;
create policy llmbridge_model_stats_all
  on public.llmbridge_model_stats
  for all to anon, authenticated, service_role
  using (true) with check (true);

-- Known provider/model mappings ----------------------------------------------
create table if not exists public.llmbridge_provider_models (
  provider_id   text not null,
  provider_name text not null,
  model_name    text not null,
  primary key (provider_id, model_name)
);

alter table public.llmbridge_provider_models enable row level security;
drop policy if exists llmbridge_provider_models_all on public.llmbridge_provider_models;
create policy llmbridge_provider_models_all
  on public.llmbridge_provider_models
  for all to anon, authenticated, service_role
  using (true) with check (true);

-- Per-request observability log (bounded by the gateway's requestLogLimit) ----
create table if not exists public.llmbridge_request_logs (
  id            bigint primary key,
  timestamp_ms  bigint not null,
  provider_name text not null,
  model         text not null default '',
  status        integer not null,
  latency_ms    bigint not null default 0,
  input_tokens  bigint not null default 0,
  output_tokens bigint not null default 0,
  is_stream     integer not null default 0,
  error         text,
  request_body  text,
  response_body text
);

create index if not exists llmbridge_request_logs_timestamp_idx
  on public.llmbridge_request_logs (timestamp_ms desc);

alter table public.llmbridge_request_logs enable row level security;
drop policy if exists llmbridge_request_logs_all on public.llmbridge_request_logs;
create policy llmbridge_request_logs_all
  on public.llmbridge_request_logs
  for all to anon, authenticated, service_role
  using (true) with check (true);
