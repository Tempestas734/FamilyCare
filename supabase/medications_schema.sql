-- Medications: family stock + treatment planning
-- Compatible with existing tables used in app:
-- - families(id)
-- - family_members(id, family_id, auth_user_id)

-- 1) Common trigger helper for updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_valid_days_of_week(days smallint[])
returns boolean
language sql
immutable
as $$
  select coalesce(bool_and(d between 0 and 6), true)
  from unnest(days) as d
$$;

-- 2) Family medication catalog (global stock for family)
create table if not exists public.family_medications (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null,
  form text, -- syrup, tablet, capsule, etc.
  dosage_per_unit text, -- 500mg par comprime, 250mg/5ml, etc.
  stock_quantity numeric(10,2) not null default 0,
  stock_unit text not null default 'comprime', -- box, tablet, ml...
  min_stock_alert numeric(10,2) not null default 0,
  notes text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint family_medications_stock_non_negative check (stock_quantity >= 0),
  constraint family_medications_min_stock_non_negative check (min_stock_alert >= 0)
);

create index if not exists idx_family_medications_family_id
  on public.family_medications (family_id);

create index if not exists idx_family_medications_family_active
  on public.family_medications (family_id, is_active);

drop trigger if exists trg_family_medications_updated_at on public.family_medications;
create trigger trg_family_medications_updated_at
before update on public.family_medications
for each row execute function public.set_updated_at();

-- 3) Treatment planning (who + frequency + hours + duration)
create table if not exists public.family_medication_plans (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  medication_id uuid not null references public.family_medications(id) on delete cascade,
  member_id uuid not null references public.family_members(id) on delete cascade, -- for who
  intake_amount numeric(10,2), -- combien prendre a chaque prise: 1, 0.5, 10
  intake_unit text, -- comprime, ml, goutte...
  frequency_type text not null default 'daily', -- daily, weekly, interval, specific_days, as_needed
  times time[] not null default '{}', -- ex: {08:00,20:00}
  days_of_week smallint[] not null default '{}', -- 0=Sunday ... 6=Saturday (used for weekly/specific_days)
  interval_hours int, -- used for interval
  start_date date not null default current_date,
  end_date date,
  duration_days int, -- optional alternative to end_date
  instructions text,
  status text not null default 'active', -- active, paused, completed
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint family_medication_plans_freq_check check (
    frequency_type in ('daily', 'weekly', 'interval', 'specific_days', 'as_needed')
  ),
  constraint family_medication_plans_status_check check (
    status in ('active', 'paused', 'completed')
  ),
  constraint family_medication_plans_interval_positive check (
    interval_hours is null or interval_hours > 0
  ),
  constraint family_medication_plans_duration_positive check (
    duration_days is null or duration_days > 0
  ),
  constraint family_medication_plans_end_after_start check (
    end_date is null or end_date >= start_date
  ),
  constraint family_medication_plans_days_of_week_check check (
    public.is_valid_days_of_week(days_of_week)
  ),
  constraint family_medication_plans_schedule_required check (
    frequency_type = 'as_needed'
    or cardinality(times) > 0
    or interval_hours is not null
  )
);

create index if not exists idx_family_medication_plans_family_id
  on public.family_medication_plans (family_id);

create index if not exists idx_family_medication_plans_member_id
  on public.family_medication_plans (member_id);

create index if not exists idx_family_medication_plans_medication_id
  on public.family_medication_plans (medication_id);

create index if not exists idx_family_medication_plans_active
  on public.family_medication_plans (family_id, status, start_date, end_date);

drop trigger if exists trg_family_medication_plans_updated_at on public.family_medication_plans;
create trigger trg_family_medication_plans_updated_at
before update on public.family_medication_plans
for each row execute function public.set_updated_at();

-- 4) RLS
alter table public.family_medications enable row level security;
alter table public.family_medication_plans enable row level security;

-- Read access: any member of the family
drop policy if exists family_medications_select_policy on public.family_medications;
create policy family_medications_select_policy
on public.family_medications
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medications.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medication_plans_select_policy on public.family_medication_plans;
create policy family_medication_plans_select_policy
on public.family_medication_plans
for select
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_plans.family_id
      and fm.auth_user_id = auth.uid()
  )
);

-- Write access: any member of the family (can be tightened later by role)
drop policy if exists family_medications_insert_policy on public.family_medications;
create policy family_medications_insert_policy
on public.family_medications
for insert
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medications.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medications_update_policy on public.family_medications;
create policy family_medications_update_policy
on public.family_medications
for update
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medications.family_id
      and fm.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medications.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medications_delete_policy on public.family_medications;
create policy family_medications_delete_policy
on public.family_medications
for delete
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medications.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medication_plans_insert_policy on public.family_medication_plans;
create policy family_medication_plans_insert_policy
on public.family_medication_plans
for insert
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_plans.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medication_plans_update_policy on public.family_medication_plans;
create policy family_medication_plans_update_policy
on public.family_medication_plans
for update
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_plans.family_id
      and fm.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_plans.family_id
      and fm.auth_user_id = auth.uid()
  )
);

drop policy if exists family_medication_plans_delete_policy on public.family_medication_plans;
create policy family_medication_plans_delete_policy
on public.family_medication_plans
for delete
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_medication_plans.family_id
      and fm.auth_user_id = auth.uid()
  )
);
