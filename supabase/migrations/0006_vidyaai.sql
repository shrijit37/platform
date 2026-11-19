-- VidyaAI fleet schema for Supabase (public HTTP gateway / PostgREST).
-- Generated from packages/db/prisma/schema.prisma. Permissive RLS for service-role access.

create extension if not exists pgcrypto;

create table if not exists public."vidyaai_users" (
  "id" text primary key default gen_random_uuid()::text,
  "email" text,
  "auth_id" text,
  "password_hash" text,
  "name" text,
  "role" text default 'STUDENT',
  "school_id" text,
  "is_active" boolean default true,
  "last_login_at" timestamptz default now(),
  "created_at" timestamptz default now(),
  "updated_at" timestamptz default now()
);

alter table public."vidyaai_users" enable row level security;
drop policy if exists "fleet_full_access" on public."vidyaai_users";
create policy "fleet_full_access" on public."vidyaai_users" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."schools" (
  "id" text primary key default gen_random_uuid()::text,
  "name" text,
  "address" text,
  "board" text,
  "max_students" integer default 0,
  "ai_generation_quota" integer default 0,
  "storage_quota_mb" integer default 0,
  "is_active" boolean default true,
  "created_at" timestamptz default now(),
  "updated_at" timestamptz default now()
);

alter table public."schools" enable row level security;
drop policy if exists "fleet_full_access" on public."schools";
create policy "fleet_full_access" on public."schools" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."vidyaai_boards" (
  "id" text primary key default gen_random_uuid()::text,
  "code" text,
  "name" text,
  "is_active" boolean default true
);

alter table public."vidyaai_boards" enable row level security;
drop policy if exists "fleet_full_access" on public."vidyaai_boards";
create policy "fleet_full_access" on public."vidyaai_boards" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."grades" (
  "id" text primary key default gen_random_uuid()::text,
  "board_id" text,
  "level" integer default 0,
  "is_active" boolean default true
);

alter table public."grades" enable row level security;
drop policy if exists "fleet_full_access" on public."grades";
create policy "fleet_full_access" on public."grades" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."subjects" (
  "id" text primary key default gen_random_uuid()::text,
  "grade_id" text,
  "code" text,
  "name" text,
  "is_active" boolean default true
);

alter table public."subjects" enable row level security;
drop policy if exists "fleet_full_access" on public."subjects";
create policy "fleet_full_access" on public."subjects" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."chapters" (
  "id" text primary key default gen_random_uuid()::text,
  "subject_id" text,
  "chapter_number" integer default 0,
  "title" text,
  "summary" text,
  "is_active" boolean default true
);

alter table public."chapters" enable row level security;
drop policy if exists "fleet_full_access" on public."chapters";
create policy "fleet_full_access" on public."chapters" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."topics" (
  "id" text primary key default gen_random_uuid()::text,
  "chapter_id" text,
  "title" text,
  "order_index" integer default 0,
  "is_active" boolean default true
);

alter table public."topics" enable row level security;
drop policy if exists "fleet_full_access" on public."topics";
create policy "fleet_full_access" on public."topics" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."concepts" (
  "id" text primary key default gen_random_uuid()::text,
  "topic_id" text,
  "title" text,
  "description" text,
  "order_index" integer default 0
);

alter table public."concepts" enable row level security;
drop policy if exists "fleet_full_access" on public."concepts";
create policy "fleet_full_access" on public."concepts" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."learning_objectives" (
  "id" text primary key default gen_random_uuid()::text,
  "topic_id" text,
  "description" text
);

alter table public."learning_objectives" enable row level security;
drop policy if exists "fleet_full_access" on public."learning_objectives";
create policy "fleet_full_access" on public."learning_objectives" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."curriculum_sources" (
  "id" text primary key default gen_random_uuid()::text,
  "chapter_id" text,
  "source_type" text,
  "url" text,
  "version" text
);

alter table public."curriculum_sources" enable row level security;
drop policy if exists "fleet_full_access" on public."curriculum_sources";
create policy "fleet_full_access" on public."curriculum_sources" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."curriculum_chunks" (
  "id" text primary key default gen_random_uuid()::text,
  "chapter_id" text,
  "concept_id" text,
  "source_id" text,
  "content" text,
  "chunk_index" integer default 0,
  "conceptTags" text[]
);

alter table public."curriculum_chunks" enable row level security;
drop policy if exists "fleet_full_access" on public."curriculum_chunks";
create policy "fleet_full_access" on public."curriculum_chunks" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."locked_definitions" (
  "id" text primary key default gen_random_uuid()::text,
  "concept_id" text,
  "term" text,
  "definition" text,
  "updated_at" timestamptz default now(),
  "updated_by_id" text,
  "version" integer default 0
);

alter table public."locked_definitions" enable row level security;
drop policy if exists "fleet_full_access" on public."locked_definitions";
create policy "fleet_full_access" on public."locked_definitions" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."locked_formulas" (
  "id" text primary key default gen_random_uuid()::text,
  "concept_id" text,
  "formula" text,
  "explanation" text,
  "updated_at" timestamptz default now(),
  "updated_by_id" text,
  "version" integer default 0
);

alter table public."locked_formulas" enable row level security;
drop policy if exists "fleet_full_access" on public."locked_formulas";
create policy "fleet_full_access" on public."locked_formulas" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."locked_definition_snapshots" (
  "id" text primary key default gen_random_uuid()::text,
  "locked_definition_id" text,
  "term" text,
  "definition" text,
  "changed_by_id" text,
  "change_reason" text,
  "changed_at" timestamptz default now()
);

alter table public."locked_definition_snapshots" enable row level security;
drop policy if exists "fleet_full_access" on public."locked_definition_snapshots";
create policy "fleet_full_access" on public."locked_definition_snapshots" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."locked_formula_snapshots" (
  "id" text primary key default gen_random_uuid()::text,
  "locked_formula_id" text,
  "formula" text,
  "explanation" text,
  "changed_by_id" text,
  "change_reason" text,
  "changed_at" timestamptz default now()
);

alter table public."locked_formula_snapshots" enable row level security;
drop policy if exists "fleet_full_access" on public."locked_formula_snapshots";
create policy "fleet_full_access" on public."locked_formula_snapshots" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."learner_profiles" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "grade_level" integer default 0,
  "board" text,
  "language" text
);

alter table public."learner_profiles" enable row level security;
drop policy if exists "fleet_full_access" on public."learner_profiles";
create policy "fleet_full_access" on public."learner_profiles" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."learner_interests" (
  "id" text primary key default gen_random_uuid()::text,
  "learner_profile_id" text,
  "interest" text,
  "weight" double precision default 0
);

alter table public."learner_interests" enable row level security;
drop policy if exists "fleet_full_access" on public."learner_interests";
create policy "fleet_full_access" on public."learner_interests" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."learner_preferences" (
  "id" text primary key default gen_random_uuid()::text,
  "learner_profile_id" text,
  "language" text,
  "difficulty_preference" text,
  "explanation_style" text
);

alter table public."learner_preferences" enable row level security;
drop policy if exists "fleet_full_access" on public."learner_preferences";
create policy "fleet_full_access" on public."learner_preferences" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."learner_performance_snapshots" (
  "id" text primary key default gen_random_uuid()::text,
  "learner_profile_id" text,
  "concept_id" text,
  "quiz_attempt_id" text,
  "score" double precision default 0,
  "total_questions" integer default 0,
  "correct_count" integer default 0,
  "time_spent_seconds" integer default 0,
  "timestamp" timestamptz
);

alter table public."learner_performance_snapshots" enable row level security;
drop policy if exists "fleet_full_access" on public."learner_performance_snapshots";
create policy "fleet_full_access" on public."learner_performance_snapshots" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."learning_sessions" (
  "id" text primary key default gen_random_uuid()::text,
  "learner_profile_id" text,
  "module_id" text,
  "started_at" timestamptz default now(),
  "ended_at" timestamptz,
  "duration_seconds" integer default 0
);

alter table public."learning_sessions" enable row level security;
drop policy if exists "fleet_full_access" on public."learning_sessions";
create policy "fleet_full_access" on public."learning_sessions" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."personalized_modules" (
  "id" text primary key default gen_random_uuid()::text,
  "learner_profile_id" text,
  "concept_id" text,
  "title" text,
  "interest_context" text,
  "current_version_id" text,
  "created_at" timestamptz default now()
);

alter table public."personalized_modules" enable row level security;
drop policy if exists "fleet_full_access" on public."personalized_modules";
create policy "fleet_full_access" on public."personalized_modules" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."personalized_module_versions" (
  "id" text primary key default gen_random_uuid()::text,
  "module_id" text,
  "version" integer default 0,
  "content" text,
  "prompt_used" text,
  "generated_at" timestamptz default now(),
  "is_active" boolean default true
);

alter table public."personalized_module_versions" enable row level security;
drop policy if exists "fleet_full_access" on public."personalized_module_versions";
create policy "fleet_full_access" on public."personalized_module_versions" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."generated_explanations" (
  "id" text primary key default gen_random_uuid()::text,
  "module_id" text,
  "explanation" text,
  "interest_context" text,
  "validated" boolean default false
);

alter table public."generated_explanations" enable row level security;
drop policy if exists "fleet_full_access" on public."generated_explanations";
create policy "fleet_full_access" on public."generated_explanations" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."generated_examples" (
  "id" text primary key default gen_random_uuid()::text,
  "module_id" text,
  "title" text,
  "example" text,
  "interest_context" text
);

alter table public."generated_examples" enable row level security;
drop policy if exists "fleet_full_access" on public."generated_examples";
create policy "fleet_full_access" on public."generated_examples" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."generated_quizzes" (
  "id" text primary key default gen_random_uuid()::text,
  "module_id" text,
  "title" text,
  "difficulty_level" text,
  "created_at" timestamptz default now()
);

alter table public."generated_quizzes" enable row level security;
drop policy if exists "fleet_full_access" on public."generated_quizzes";
create policy "fleet_full_access" on public."generated_quizzes" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."quiz_questions" (
  "id" text primary key default gen_random_uuid()::text,
  "quiz_id" text,
  "question_text" text,
  "options" text[],
  "correct_index" integer default 0,
  "explanation" text,
  "difficulty_score" double precision default 0,
  "learning_objective" text
);

alter table public."quiz_questions" enable row level security;
drop policy if exists "fleet_full_access" on public."quiz_questions";
create policy "fleet_full_access" on public."quiz_questions" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."quiz_attempts" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "quiz_id" text,
  "score" double precision default 0,
  "total_questions" integer default 0,
  "correct_count" integer default 0,
  "time_spent_seconds" integer default 0,
  "completed_at" timestamptz default now(),
  "synced" boolean default false
);

alter table public."quiz_attempts" enable row level security;
drop policy if exists "fleet_full_access" on public."quiz_attempts";
create policy "fleet_full_access" on public."quiz_attempts" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."quiz_answers" (
  "id" text primary key default gen_random_uuid()::text,
  "attempt_id" text,
  "question_id" text,
  "selected_index" integer default 0,
  "is_correct" boolean default false
);

alter table public."quiz_answers" enable row level security;
drop policy if exists "fleet_full_access" on public."quiz_answers";
create policy "fleet_full_access" on public."quiz_answers" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."concept_mastery" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "concept_id" text,
  "mastery_score" double precision default 0,
  "confidence" double precision default 0,
  "attempts_count" integer default 0,
  "correct_count" integer default 0,
  "last_attempt_at" timestamptz,
  "next_review_at" timestamptz
);

alter table public."concept_mastery" enable row level security;
drop policy if exists "fleet_full_access" on public."concept_mastery";
create policy "fleet_full_access" on public."concept_mastery" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."adaptive_recommendations" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "concept_id" text,
  "reason" text,
  "priority" integer default 0,
  "created_at" timestamptz default now(),
  "dismissed_at" timestamptz
);

alter table public."adaptive_recommendations" enable row level security;
drop policy if exists "fleet_full_access" on public."adaptive_recommendations";
create policy "fleet_full_access" on public."adaptive_recommendations" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."learning_paths" (
  "id" text primary key default gen_random_uuid()::text,
  "learner_profile_id" text,
  "goal_concept_ids" text[],
  "module_sequence" text[],
  "completed_module_ids" text[],
  "current_module_index" integer default 0,
  "recommended_interest" text,
  "status" text,
  "created_at" timestamptz default now(),
  "updated_at" timestamptz default now()
);

alter table public."learning_paths" enable row level security;
drop policy if exists "fleet_full_access" on public."learning_paths";
create policy "fleet_full_access" on public."learning_paths" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."adaptive_rules" (
  "id" text primary key default gen_random_uuid()::text,
  "condition" jsonb,
  "action" jsonb,
  "weight" double precision default 0,
  "applicable_concepts" text[],
  "created_at" timestamptz default now(),
  "updated_at" timestamptz default now()
);

alter table public."adaptive_rules" enable row level security;
drop policy if exists "fleet_full_access" on public."adaptive_rules";
create policy "fleet_full_access" on public."adaptive_rules" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."personalization_logs" (
  "id" text primary key default gen_random_uuid()::text,
  "learner_profile_id" text,
  "concept_id" text,
  "module_id" text,
  "strategy" text,
  "interest" text,
  "effectiveness_score" double precision default 0,
  "created_at" timestamptz default now()
);

alter table public."personalization_logs" enable row level security;
drop policy if exists "fleet_full_access" on public."personalization_logs";
create policy "fleet_full_access" on public."personalization_logs" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."gamification_profiles" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "total_xp" integer default 0,
  "level" integer default 0,
  "current_streak" integer default 0,
  "longest_streak" integer default 0,
  "streakId" text
);

alter table public."gamification_profiles" enable row level security;
drop policy if exists "fleet_full_access" on public."gamification_profiles";
create policy "fleet_full_access" on public."gamification_profiles" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."xp_events" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "profile_id" text,
  "amount" integer default 0,
  "source" text,
  "description" text,
  "created_at" timestamptz default now()
);

alter table public."xp_events" enable row level security;
drop policy if exists "fleet_full_access" on public."xp_events";
create policy "fleet_full_access" on public."xp_events" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."badges" (
  "id" text primary key default gen_random_uuid()::text,
  "code" text,
  "name" text,
  "description" text,
  "xp_reward" integer default 0,
  "icon_url" text
);

alter table public."badges" enable row level security;
drop policy if exists "fleet_full_access" on public."badges";
create policy "fleet_full_access" on public."badges" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."student_badges" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "badge_id" text,
  "awarded_at" timestamptz default now(),
  "gamificationProfileId" text
);

alter table public."student_badges" enable row level security;
drop policy if exists "fleet_full_access" on public."student_badges";
create policy "fleet_full_access" on public."student_badges" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."streaks" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "current_count" integer default 0,
  "longest_count" integer default 0,
  "last_activity_at" timestamptz default now()
);

alter table public."streaks" enable row level security;
drop policy if exists "fleet_full_access" on public."streaks";
create policy "fleet_full_access" on public."streaks" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."classrooms" (
  "id" text primary key default gen_random_uuid()::text,
  "school_id" text,
  "teacher_id" text,
  "name" text,
  "grade_level" integer default 0,
  "section" text,
  "is_active" boolean default true
);

alter table public."classrooms" enable row level security;
drop policy if exists "fleet_full_access" on public."classrooms";
create policy "fleet_full_access" on public."classrooms" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."class_enrollments" (
  "id" text primary key default gen_random_uuid()::text,
  "class_id" text,
  "student_id" text
);

alter table public."class_enrollments" enable row level security;
drop policy if exists "fleet_full_access" on public."class_enrollments";
create policy "fleet_full_access" on public."class_enrollments" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."parent_student_links" (
  "id" text primary key default gen_random_uuid()::text,
  "parent_id" text,
  "student_id" text,
  "relationship" text,
  "created_at" timestamptz default now()
);

alter table public."parent_student_links" enable row level security;
drop policy if exists "fleet_full_access" on public."parent_student_links";
create policy "fleet_full_access" on public."parent_student_links" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."teacher_insights" (
  "id" text primary key default gen_random_uuid()::text,
  "class_id" text,
  "student_id" text,
  "concept_id" text,
  "insight_type" text,
  "message" text,
  "created_at" timestamptz default now()
);

alter table public."teacher_insights" enable row level security;
drop policy if exists "fleet_full_access" on public."teacher_insights";
create policy "fleet_full_access" on public."teacher_insights" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."parent_reports" (
  "id" text primary key default gen_random_uuid()::text,
  "parent_id" text,
  "student_id" text,
  "report_period" text,
  "generated_at" timestamptz default now(),
  "content" text,
  "pdf_url" text
);

alter table public."parent_reports" enable row level security;
drop policy if exists "fleet_full_access" on public."parent_reports";
create policy "fleet_full_access" on public."parent_reports" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."prompt_templates" (
  "id" text primary key default gen_random_uuid()::text,
  "name" text,
  "description" text,
  "current_version_id" text,
  "created_at" timestamptz default now()
);

alter table public."prompt_templates" enable row level security;
drop policy if exists "fleet_full_access" on public."prompt_templates";
create policy "fleet_full_access" on public."prompt_templates" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."prompt_template_versions" (
  "id" text primary key default gen_random_uuid()::text,
  "template_id" text,
  "version" integer default 0,
  "system_prompt" text,
  "user_prompt_template" text,
  "variables" text[],
  "approved_by_id" text,
  "is_active" boolean default true,
  "created_at" timestamptz default now()
);

alter table public."prompt_template_versions" enable row level security;
drop policy if exists "fleet_full_access" on public."prompt_template_versions";
create policy "fleet_full_access" on public."prompt_template_versions" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."ai_provider_configs" (
  "id" text primary key default gen_random_uuid()::text,
  "provider" text,
  "model_name" text,
  "api_key_env_var" text,
  "base_url" text,
  "is_active" boolean default true,
  "priority" integer default 0,
  "max_tokens" integer default 0,
  "temperature" double precision default 0
);

alter table public."ai_provider_configs" enable row level security;
drop policy if exists "fleet_full_access" on public."ai_provider_configs";
create policy "fleet_full_access" on public."ai_provider_configs" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."ai_generation_logs" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "template_id" text,
  "provider" text,
  "model" text,
  "prompt" text,
  "response" text,
  "token_usage" integer default 0,
  "cost" double precision default 0,
  "duration_ms" integer default 0,
  "status" text,
  "error_message" text,
  "created_at" timestamptz default now()
);

alter table public."ai_generation_logs" enable row level security;
drop policy if exists "fleet_full_access" on public."ai_generation_logs";
create policy "fleet_full_access" on public."ai_generation_logs" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."safety_evaluations" (
  "id" text primary key default gen_random_uuid()::text,
  "log_id" text,
  "module_id" text,
  "passed" boolean default false,
  "violations" text[],
  "evaluated_at" timestamptz default now()
);

alter table public."safety_evaluations" enable row level security;
drop policy if exists "fleet_full_access" on public."safety_evaluations";
create policy "fleet_full_access" on public."safety_evaluations" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."human_review_items" (
  "id" text primary key default gen_random_uuid()::text,
  "content" text,
  "content_type" text,
  "submitted_by_id" text,
  "status" text,
  "reviewed_by_id" text,
  "submitted_at" timestamptz default now(),
  "reviewed_at" timestamptz,
  "priority" text,
  "category" text,
  "concept_id" text,
  "assigned_to_id" text,
  "revision_requested" boolean default false,
  "locked_content_violation" text,
  "safety_check_id" text
);

alter table public."human_review_items" enable row level security;
drop policy if exists "fleet_full_access" on public."human_review_items";
create policy "fleet_full_access" on public."human_review_items" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."content_approvals" (
  "id" text primary key default gen_random_uuid()::text,
  "review_item_id" text,
  "approved_by_id" text,
  "decision" text,
  "comment" text,
  "decided_at" timestamptz default now()
);

alter table public."content_approvals" enable row level security;
drop policy if exists "fleet_full_access" on public."content_approvals";
create policy "fleet_full_access" on public."content_approvals" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."teacher_feedback" (
  "id" text primary key default gen_random_uuid()::text,
  "review_item_id" text,
  "reported_by_id" text,
  "comment" text,
  "status" text,
  "created_at" timestamptz default now(),
  "resolved_at" timestamptz
);

alter table public."teacher_feedback" enable row level security;
drop policy if exists "fleet_full_access" on public."teacher_feedback";
create policy "fleet_full_access" on public."teacher_feedback" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."review_discussions" (
  "id" text primary key default gen_random_uuid()::text,
  "review_item_id" text,
  "author_id" text,
  "parent_id" text,
  "content" text,
  "created_at" timestamptz default now()
);

alter table public."review_discussions" enable row level security;
drop policy if exists "fleet_full_access" on public."review_discussions";
create policy "fleet_full_access" on public."review_discussions" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."vidyaai_audit_logs" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "school_id" text,
  "action" text,
  "resource" text,
  "resource_id" text,
  "details" text,
  "ip_address" text,
  "user_agent" text,
  "created_at" timestamptz default now()
);

alter table public."vidyaai_audit_logs" enable row level security;
drop policy if exists "fleet_full_access" on public."vidyaai_audit_logs";
create policy "fleet_full_access" on public."vidyaai_audit_logs" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."refresh_tokens" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "token_hash" text,
  "expires_at" timestamptz,
  "revoked_at" timestamptz,
  "replaced_by_token_id" text,
  "last_used_at" timestamptz,
  "created_at" timestamptz default now()
);

alter table public."refresh_tokens" enable row level security;
drop policy if exists "fleet_full_access" on public."refresh_tokens";
create policy "fleet_full_access" on public."refresh_tokens" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."otp_requests" (
  "id" text primary key default gen_random_uuid()::text,
  "email" text,
  "user_id" text,
  "school_id" text,
  "token_hash" text,
  "metadata" text,
  "expires_at" timestamptz,
  "consumed_at" timestamptz,
  "created_at" timestamptz default now()
);

alter table public."otp_requests" enable row level security;
drop policy if exists "fleet_full_access" on public."otp_requests";
create policy "fleet_full_access" on public."otp_requests" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."notifications" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "type" text,
  "title" text,
  "message" text,
  "read" boolean default false,
  "action_url" text,
  "created_at" timestamptz default now()
);

alter table public."notifications" enable row level security;
drop policy if exists "fleet_full_access" on public."notifications";
create policy "fleet_full_access" on public."notifications" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."device_sessions" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "device_id" text,
  "platform" text,
  "push_token" text,
  "last_active_at" timestamptz
);

alter table public."device_sessions" enable row level security;
drop policy if exists "fleet_full_access" on public."device_sessions";
create policy "fleet_full_access" on public."device_sessions" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."downloaded_lessons" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "module_id" text,
  "downloaded_at" timestamptz default now(),
  "file_url" text,
  "file_size" integer default 0,
  "expires_at" timestamptz
);

alter table public."downloaded_lessons" enable row level security;
drop policy if exists "fleet_full_access" on public."downloaded_lessons";
create policy "fleet_full_access" on public."downloaded_lessons" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."offline_sync_events" (
  "id" text primary key default gen_random_uuid()::text,
  "user_id" text,
  "entity_type" text,
  "entity_id" text,
  "operation" text,
  "payload" text,
  "retry_count" integer default 0,
  "error_message" text,
  "synced_at" timestamptz default now(),
  "created_at" timestamptz default now()
);

alter table public."offline_sync_events" enable row level security;
drop policy if exists "fleet_full_access" on public."offline_sync_events";
create policy "fleet_full_access" on public."offline_sync_events" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."sync_conflicts" (
  "id" text primary key default gen_random_uuid()::text,
  "offline_event_id" text,
  "server_data" text,
  "conflict_type" text,
  "resolved" boolean default false,
  "resolution" text,
  "resolved_at" timestamptz,
  "created_at" timestamptz default now()
);

alter table public."sync_conflicts" enable row level security;
drop policy if exists "fleet_full_access" on public."sync_conflicts";
create policy "fleet_full_access" on public."sync_conflicts" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."request_logs" (
  "id" text primary key default gen_random_uuid()::text,
  "method" text,
  "path" text,
  "status_code" integer default 0,
  "duration_ms" integer default 0,
  "user_id" text,
  "created_at" timestamptz default now()
);

alter table public."request_logs" enable row level security;
drop policy if exists "fleet_full_access" on public."request_logs";
create policy "fleet_full_access" on public."request_logs" for all
  to anon, authenticated, service_role using (true) with check (true);

create table if not exists public."platform_settings" (
  "id" text primary key default gen_random_uuid()::text,
  "value" jsonb
);

alter table public."platform_settings" enable row level security;
drop policy if exists "fleet_full_access" on public."platform_settings";
create policy "fleet_full_access" on public."platform_settings" for all
  to anon, authenticated, service_role using (true) with check (true);

-- Common lookup indexes
create index if not exists "users_email_idx" on public."vidyaai_users" ("email");
create index if not exists "users_role_idx" on public."vidyaai_users" ("role");
create index if not exists "users_school_id_idx" on public."vidyaai_users" ("school_id");
create index if not exists "users_auth_id_idx" on public."vidyaai_users" ("auth_id");
create index if not exists "learner_profiles_user_id_idx" on public."learner_profiles" ("user_id");
create index if not exists "classrooms_teacher_id_idx" on public."classrooms" ("teacher_id");
create index if not exists "class_enrollments_student_id_idx" on public."class_enrollments" ("student_id");
create index if not exists "notifications_user_id_idx" on public."notifications" ("user_id");
create index if not exists "human_review_items_status_idx" on public."human_review_items" ("status");
create index if not exists "request_logs_created_at_idx" on public."request_logs" ("created_at");
