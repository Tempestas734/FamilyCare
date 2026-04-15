-- Workout app schema (programs, exercises, sessions, stats)
-- Depends on existing tables:
-- - public.families(id)
-- - public.family_members(id, family_id, auth_user_id)

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- 1) Exercise library (shared catalog)
create table if not exists public.exercise_library (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  difficulty text,
  muscle_group text,
  equipment text,
  default_duration_sec int,
  default_reps int,
  calories_estimate int,
  met numeric(4,2),
  external_source text,
  external_id text,
  media_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint exercise_library_positive_duration check (
    default_duration_sec is null or default_duration_sec > 0
  ),
  constraint exercise_library_positive_reps check (
    default_reps is null or default_reps > 0
  ),
  constraint exercise_library_positive_calories check (
    calories_estimate is null or calories_estimate >= 0
  ),
  constraint exercise_library_met_positive check (
    met is null or met > 0
  )
);

alter table public.exercise_library
  add column if not exists equipment text,
  add column if not exists met numeric(4,2),
  add column if not exists external_source text,
  add column if not exists external_id text;

create index if not exists idx_exercise_library_category
  on public.exercise_library(category, is_active);

create unique index if not exists ux_exercise_library_external
  on public.exercise_library(external_source, external_id)
  where external_source is not null and external_id is not null;

-- Seed base exercises used by workout app UI
insert into public.exercise_library (
  name, category, difficulty, muscle_group, default_duration_sec, calories_estimate, media_url
)
values
  ('Burpees', 'Cardio', 'Haute intensite', 'full_body', 45, 12, 'https://lh3.googleusercontent.com/aida-public/AB6AXuB4Pqqudq5CVlppU10SLqqm7n3MLw8Bv3QjBAS3yvIaR3eyETAul27vX82X-P_gFXDQpuZr38Qkhy-ft9raqm3xLLtSogaC0dD9hsNWkAbe_FSEwA8h79eV1yLeyvbfdGL0jKFcXhCCvj7QolUZfA7V4qJfL6gTlV54HUoqeqiTclzwFrHCdE2Nw3Pl3hrr6Tf3D4Lcfq52F-8O8Z_d3ksbXFfmM1OgGZ_XqWvs9OCQO-Bv2DG0ZK6frn6dyBoO87OXxkZ6zO3BuTgU'),
  ('Fentes alternees', 'Jambes', 'Mobilite', 'legs', 40, 8, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDDFWZ5XqVR8FRNDUw0aLsoIYzVgUsllge-n6PNym6gdvrIG7G84itVrJ7DF6bSBhHHgwAGaHV7Q4yxoBdNqmHnaK-taMIHePMfojzW9iEDjaHq0p4cYtVU6_CNBqiJc1k8jPxVGtJdxK0e47SKYaCE3zl-9TLd8PpX_WKUOK1NYd0ps4D2Yn0u7WpOVO5FMo0zD-hbFGfmoefKJDXKxLWXd4UA1mImDJLRzH04lSegM8s4v0fSPa--lZ9fWwOcMx3b0ZV3cbQFy_o8'),
  ('Mountain Climbers', 'Abdos', 'Cardio', 'core', 40, 9, 'https://lh3.googleusercontent.com/aida-public/AB6AXuChHMswCQbFgNxQ2JcnnwiABVnlOr470-AaySk6gYAobS0wa_SBH4WLuW4wKiMInqayxCKecW2LHHXDF0AV_TYDOD3cc8Oc-zkP8RIgMlLK7CoMVz63NO4-mQXaYUIu4hEwc0NPKcnabIdsogFmfcGF2RNJBezLyLj9TsNseQlKM_VYhEpdWO5QZ2AKhKELIydkYvnH563hQGLVEHLu-E_ena9eVfRs465hDOK4oDHxLzYUer-jFm3-uen6TeOeFmoWjgnLeYrl_NEm'),
  ('Dips sur chaise', 'Bras', 'Triceps', 'arms', 35, 7, 'https://lh3.googleusercontent.com/aida-public/AB6AXuA8Cc_2rM9EOTh8V5o76e1Vt-x9fCuSK1zgJPbx6yrF0ZHLe2vPK1AOlujf4PUsH23C6jp2CYVc4J3iUUGHRERGGbJClgPt5QnB_wtbIr4qjnUdf36TOGsxBQYT9uOmvaSN4eOZ5MVuNNraOuH-8b-mOdPETbX5b_3PkJSm4yRjPWARSnkQR6UIgKQ82LyTuo_DzZGBYgtxA8AqQ5NeZwdcVvXRHMPQZeSFAleTZy1dmoxt4stG95Jn8Vt1qFWgvOZc2wN2wZ-lNkj-'),
  ('Pompes classiques', 'Bras', 'Pectoraux', 'arms', 40, 10, 'https://lh3.googleusercontent.com/aida-public/AB6AXuDDFKq-3E-F4dYK-NaRI1WeZ6BalaNhG4nEalM74GJIHOFpw3utzOj-hv-MSqP4XpOTIAXTAJ_G1r0RFslnSTZIHsLdOrgkJAC6p_uONC1A4dmlFOLHY_nhARGaDvgkF5U0QK9rqta72ik8SO-M_OVVycVuSpAJY0fot9sMp62LWnhHQqd5qO7xJ118dWctqBZphmaUJi7FSrPzYxRA19BBZlUEjxNlMXParhZ-kKUm52fKht-mkvH6ZIz15LjHcowc_iVPIFmDzGKZ')
on conflict do nothing;

-- 2) Programs
create table if not exists public.workout_programs (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  created_by_member_id uuid not null references public.family_members(id) on delete cascade,
  title text not null,
  description text,
  cover_image_url text,
  focus text,
  is_template boolean not null default false,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_workout_programs_family
  on public.workout_programs(family_id, created_at desc);

create index if not exists idx_workout_programs_creator
  on public.workout_programs(created_by_member_id, created_at desc);

drop trigger if exists trg_workout_programs_updated_at on public.workout_programs;
create trigger trg_workout_programs_updated_at
before update on public.workout_programs
for each row execute function public.set_updated_at();

-- 3) Program exercises
create table if not exists public.workout_program_exercises (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.workout_programs(id) on delete cascade,
  exercise_id uuid not null references public.exercise_library(id) on delete restrict,
  position int not null,
  duration_sec int,
  reps int,
  rest_sec int,
  notes text,
  constraint workout_program_exercises_position_positive check (position > 0),
  constraint workout_program_exercises_duration_positive check (
    duration_sec is null or duration_sec > 0
  ),
  constraint workout_program_exercises_reps_positive check (
    reps is null or reps > 0
  ),
  constraint workout_program_exercises_rest_positive check (
    rest_sec is null or rest_sec >= 0
  ),
  constraint workout_program_exercises_unique_position unique (program_id, position)
);

create index if not exists idx_workout_program_exercises_program
  on public.workout_program_exercises(program_id, position);

-- 4) Program favorites
create table if not exists public.workout_program_favorites (
  member_id uuid not null references public.family_members(id) on delete cascade,
  program_id uuid not null references public.workout_programs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (member_id, program_id)
);

create index if not exists idx_workout_program_favorites_program
  on public.workout_program_favorites(program_id);

-- 5) Sessions
create table if not exists public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  member_id uuid not null references public.family_members(id) on delete cascade,
  program_id uuid references public.workout_programs(id) on delete set null,
  source_app text not null default 'workout_app',
  started_at timestamptz not null,
  ended_at timestamptz,
  duration_minutes int,
  estimated_calories numeric(10,2),
  status text not null default 'completed',
  created_at timestamptz not null default now(),
  constraint workout_sessions_status_check check (
    status in ('planned', 'in_progress', 'completed', 'skipped')
  ),
  constraint workout_sessions_duration_non_negative check (
    duration_minutes is null or duration_minutes >= 0
  ),
  constraint workout_sessions_calories_non_negative check (
    estimated_calories is null or estimated_calories >= 0
  )
);

create index if not exists idx_workout_sessions_family_time
  on public.workout_sessions(family_id, started_at desc);

create index if not exists idx_workout_sessions_member_time
  on public.workout_sessions(member_id, started_at desc);

-- 6) Session exercises
create table if not exists public.workout_session_exercises (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_id uuid not null references public.exercise_library(id) on delete restrict,
  position int not null,
  actual_duration_sec int,
  actual_reps int,
  calories_burned numeric(10,2),
  constraint workout_session_exercises_position_positive check (position > 0),
  constraint workout_session_exercises_duration_non_negative check (
    actual_duration_sec is null or actual_duration_sec >= 0
  ),
  constraint workout_session_exercises_reps_non_negative check (
    actual_reps is null or actual_reps >= 0
  ),
  constraint workout_session_exercises_calories_non_negative check (
    calories_burned is null or calories_burned >= 0
  )
);

create index if not exists idx_workout_session_exercises_session
  on public.workout_session_exercises(session_id, position);

-- 7) Daily stats snapshot
create table if not exists public.workout_member_stats_daily (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  member_id uuid not null references public.family_members(id) on delete cascade,
  day date not null,
  total_sessions int not null default 0,
  total_minutes int not null default 0,
  total_calories numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workout_member_stats_daily_unique unique (member_id, day),
  constraint workout_member_stats_sessions_non_negative check (total_sessions >= 0),
  constraint workout_member_stats_minutes_non_negative check (total_minutes >= 0),
  constraint workout_member_stats_calories_non_negative check (total_calories >= 0)
);

drop trigger if exists trg_workout_member_stats_daily_updated_at on public.workout_member_stats_daily;
create trigger trg_workout_member_stats_daily_updated_at
before update on public.workout_member_stats_daily
for each row execute function public.set_updated_at();

-- RLS
alter table public.exercise_library enable row level security;
alter table public.workout_programs enable row level security;
alter table public.workout_program_exercises enable row level security;
alter table public.workout_program_favorites enable row level security;
alter table public.workout_sessions enable row level security;
alter table public.workout_session_exercises enable row level security;
alter table public.workout_member_stats_daily enable row level security;

-- exercise_library: authenticated users can read
drop policy if exists exercise_library_select_policy on public.exercise_library;
create policy exercise_library_select_policy
on public.exercise_library
for select
using (auth.uid() is not null and is_active = true);

drop policy if exists exercise_library_insert_policy on public.exercise_library;
create policy exercise_library_insert_policy
on public.exercise_library
for insert
with check (auth.uid() is not null);

drop policy if exists exercise_library_update_policy on public.exercise_library;
create policy exercise_library_update_policy
on public.exercise_library
for update
using (auth.uid() is not null)
with check (auth.uid() is not null);

-- workout_programs
drop policy if exists workout_programs_select_policy on public.workout_programs;
create policy workout_programs_select_policy
on public.workout_programs
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_programs.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_programs_insert_policy on public.workout_programs;
create policy workout_programs_insert_policy
on public.workout_programs
for insert
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_programs.family_id
      and fm.id = workout_programs.created_by_member_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_programs_update_policy on public.workout_programs;
create policy workout_programs_update_policy
on public.workout_programs
for update
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_programs.family_id
      and fm.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_programs.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_programs_delete_policy on public.workout_programs;
create policy workout_programs_delete_policy
on public.workout_programs
for delete
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_programs.family_id
      and fm.auth_user_id = auth.uid()
  )
);

-- workout_program_exercises
drop policy if exists workout_program_exercises_select_policy on public.workout_program_exercises;
create policy workout_program_exercises_select_policy
on public.workout_program_exercises
for select
using (
  exists (
    select 1
    from public.workout_programs p
    join public.family_members fm on fm.family_id = p.family_id
    where p.id = workout_program_exercises.program_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_program_exercises_insert_policy on public.workout_program_exercises;
create policy workout_program_exercises_insert_policy
on public.workout_program_exercises
for insert
with check (
  exists (
    select 1
    from public.workout_programs p
    join public.family_members fm on fm.family_id = p.family_id
    where p.id = workout_program_exercises.program_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_program_exercises_update_policy on public.workout_program_exercises;
create policy workout_program_exercises_update_policy
on public.workout_program_exercises
for update
using (
  exists (
    select 1
    from public.workout_programs p
    join public.family_members fm on fm.family_id = p.family_id
    where p.id = workout_program_exercises.program_id
      and fm.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.workout_programs p
    join public.family_members fm on fm.family_id = p.family_id
    where p.id = workout_program_exercises.program_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_program_exercises_delete_policy on public.workout_program_exercises;
create policy workout_program_exercises_delete_policy
on public.workout_program_exercises
for delete
using (
  exists (
    select 1
    from public.workout_programs p
    join public.family_members fm on fm.family_id = p.family_id
    where p.id = workout_program_exercises.program_id
      and fm.auth_user_id = auth.uid()
  )
);

-- workout_program_favorites
drop policy if exists workout_program_favorites_select_policy on public.workout_program_favorites;
create policy workout_program_favorites_select_policy
on public.workout_program_favorites
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.id = workout_program_favorites.member_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_program_favorites_insert_policy on public.workout_program_favorites;
create policy workout_program_favorites_insert_policy
on public.workout_program_favorites
for insert
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.id = workout_program_favorites.member_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_program_favorites_delete_policy on public.workout_program_favorites;
create policy workout_program_favorites_delete_policy
on public.workout_program_favorites
for delete
using (
  exists (
    select 1
    from public.family_members fm
    where fm.id = workout_program_favorites.member_id
      and fm.auth_user_id = auth.uid()
  )
);

-- workout_sessions
drop policy if exists workout_sessions_select_policy on public.workout_sessions;
create policy workout_sessions_select_policy
on public.workout_sessions
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_sessions.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_sessions_insert_policy on public.workout_sessions;
create policy workout_sessions_insert_policy
on public.workout_sessions
for insert
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_sessions.family_id
      and fm.id = workout_sessions.member_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_sessions_update_policy on public.workout_sessions;
create policy workout_sessions_update_policy
on public.workout_sessions
for update
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_sessions.family_id
      and fm.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_sessions.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_sessions_delete_policy on public.workout_sessions;
create policy workout_sessions_delete_policy
on public.workout_sessions
for delete
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_sessions.family_id
      and fm.auth_user_id = auth.uid()
  )
);

-- workout_session_exercises
drop policy if exists workout_session_exercises_select_policy on public.workout_session_exercises;
create policy workout_session_exercises_select_policy
on public.workout_session_exercises
for select
using (
  exists (
    select 1
    from public.workout_sessions s
    join public.family_members fm on fm.family_id = s.family_id
    where s.id = workout_session_exercises.session_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_session_exercises_insert_policy on public.workout_session_exercises;
create policy workout_session_exercises_insert_policy
on public.workout_session_exercises
for insert
with check (
  exists (
    select 1
    from public.workout_sessions s
    join public.family_members fm on fm.family_id = s.family_id
    where s.id = workout_session_exercises.session_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_session_exercises_update_policy on public.workout_session_exercises;
create policy workout_session_exercises_update_policy
on public.workout_session_exercises
for update
using (
  exists (
    select 1
    from public.workout_sessions s
    join public.family_members fm on fm.family_id = s.family_id
    where s.id = workout_session_exercises.session_id
      and fm.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.workout_sessions s
    join public.family_members fm on fm.family_id = s.family_id
    where s.id = workout_session_exercises.session_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_session_exercises_delete_policy on public.workout_session_exercises;
create policy workout_session_exercises_delete_policy
on public.workout_session_exercises
for delete
using (
  exists (
    select 1
    from public.workout_sessions s
    join public.family_members fm on fm.family_id = s.family_id
    where s.id = workout_session_exercises.session_id
      and fm.auth_user_id = auth.uid()
  )
);

-- workout_member_stats_daily
drop policy if exists workout_member_stats_daily_select_policy on public.workout_member_stats_daily;
create policy workout_member_stats_daily_select_policy
on public.workout_member_stats_daily
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_member_stats_daily.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists workout_member_stats_daily_upsert_policy on public.workout_member_stats_daily;
create policy workout_member_stats_daily_upsert_policy
on public.workout_member_stats_daily
for all
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_member_stats_daily.family_id
      and fm.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = workout_member_stats_daily.family_id
      and fm.auth_user_id = auth.uid()
  )
);
