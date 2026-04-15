-- Per-dose tracking for medication plans
-- One row = one planned intake (date + time) for one member

-- 1) Table
create table if not exists public.family_medication_doses (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  plan_id uuid not null references public.family_medication_plans(id) on delete cascade,
  medication_id uuid not null references public.family_medications(id) on delete cascade,
  member_id uuid not null references public.family_members(id) on delete cascade,
  scheduled_date date not null,
  scheduled_time time not null,
  scheduled_at timestamptz, -- optional computed value in app timezone
  taken boolean not null default false,
  taken_at timestamptz,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint family_medication_doses_unique_instance unique (plan_id, member_id, scheduled_date, scheduled_time),
  constraint family_medication_doses_taken_consistency check (
    (taken = false and taken_at is null)
    or (taken = true and taken_at is not null)
  )
);

create index if not exists idx_medication_doses_family_date
  on public.family_medication_doses (family_id, scheduled_date);

create index if not exists idx_medication_doses_member_date
  on public.family_medication_doses (member_id, scheduled_date);

create index if not exists idx_medication_doses_plan
  on public.family_medication_doses (plan_id);

-- 2) updated_at trigger
drop trigger if exists trg_medication_doses_updated_at on public.family_medication_doses;
create trigger trg_medication_doses_updated_at
before update on public.family_medication_doses
for each row execute function public.set_updated_at();

-- 3) RLS
alter table public.family_medication_doses enable row level security;

drop policy if exists family_medication_doses_select_policy on public.family_medication_doses;
create policy family_medication_doses_select_policy
on public.family_medication_doses
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_doses.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medication_doses_insert_policy on public.family_medication_doses;
create policy family_medication_doses_insert_policy
on public.family_medication_doses
for insert
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_doses.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medication_doses_update_policy on public.family_medication_doses;
create policy family_medication_doses_update_policy
on public.family_medication_doses
for update
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_doses.family_id
      and fm.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_doses.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medication_doses_delete_policy on public.family_medication_doses;
create policy family_medication_doses_delete_policy
on public.family_medication_doses
for delete
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_doses.family_id
      and fm.auth_user_id = auth.uid()
  )
);

-- 4) Helper: generate dose rows from one plan on a date range
-- Supports: daily, weekly, specific_days
create or replace function public.generate_doses_for_plan(
  p_plan_id uuid,
  p_from date,
  p_to date
)
returns int
language plpgsql
security definer
as $$
declare
  v_plan record;
  v_day date;
  v_time time;
  v_inserted int := 0;
  v_dow int;
begin
  if p_from is null or p_to is null or p_to < p_from then
    raise exception 'Invalid date range';
  end if;

  select
    p.id,
    p.family_id,
    p.medication_id,
    p.member_id,
    p.frequency_type,
    p.times,
    p.days_of_week,
    p.start_date,
    p.end_date
  into v_plan
  from public.family_medication_plans p
  where p.id = p_plan_id;

  if not found then
    raise exception 'Plan not found: %', p_plan_id;
  end if;

  if v_plan.times is null or cardinality(v_plan.times) = 0 then
    return 0;
  end if;

  for v_day in
    select d::date
    from generate_series(
      greatest(p_from, v_plan.start_date),
      least(p_to, coalesce(v_plan.end_date, p_to)),
      interval '1 day'
    ) d
  loop
    v_dow := extract(dow from v_day)::int; -- 0=Sunday

    if v_plan.frequency_type = 'daily'
       or (
         v_plan.frequency_type in ('weekly', 'specific_days')
         and (
           (v_plan.days_of_week is not null and cardinality(v_plan.days_of_week) > 0 and v_dow = any(v_plan.days_of_week))
           or
           (coalesce(cardinality(v_plan.days_of_week), 0) = 0 and v_dow = extract(dow from v_plan.start_date)::int)
         )
       ) then
      foreach v_time in array v_plan.times
      loop
        insert into public.family_medication_doses (
          family_id,
          plan_id,
          medication_id,
          member_id,
          scheduled_date,
          scheduled_time
        )
        values (
          v_plan.family_id,
          v_plan.id,
          v_plan.medication_id,
          v_plan.member_id,
          v_day,
          v_time
        )
        on conflict (plan_id, member_id, scheduled_date, scheduled_time) do nothing;

        if found then
          v_inserted := v_inserted + 1;
        end if;
      end loop;
    end if;
  end loop;

  return v_inserted;
end;
$$;

-- 5) Optional backfill helper for all active plans on a range
create or replace function public.generate_doses_for_active_plans(
  p_family_id uuid,
  p_from date,
  p_to date
)
returns int
language plpgsql
security definer
as $$
declare
  v_plan_id uuid;
  v_total int := 0;
begin
  for v_plan_id in
    select id
    from public.family_medication_plans
    where family_id = p_family_id
      and status = 'active'
  loop
    v_total := v_total + public.generate_doses_for_plan(v_plan_id, p_from, p_to);
  end loop;

  return v_total;
end;
$$;
