create or replace function public.is_valid_days_of_week(days smallint[])
returns boolean
language sql
immutable
as $$
  select coalesce(bool_and(d between 0 and 6), true)
  from unnest(days) as d
$$;

alter table public.family_medications enable row level security;
alter table public.family_medication_plans enable row level security;
alter table public.family_medication_doses enable row level security;

alter table public.family_medication_plans
add column if not exists created_by uuid null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_medication_plans_created_by_fkey'
      and conrelid = 'public.family_medication_plans'::regclass
  ) then
    alter table public.family_medication_plans
    add constraint family_medication_plans_created_by_fkey
    foreign key (created_by) references auth.users(id);
  end if;
end
$$;

alter table public.family_medication_doses
add column if not exists family_id uuid null;

alter table public.family_medication_doses
add column if not exists plan_id uuid null;

alter table public.family_medication_doses
add column if not exists medication_id uuid null;

alter table public.family_medication_doses
add column if not exists member_id uuid null;

alter table public.family_medication_doses
add column if not exists scheduled_date date null;

alter table public.family_medication_doses
add column if not exists scheduled_time time without time zone null;

alter table public.family_medication_doses
add column if not exists taken boolean not null default false;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'family_medication_doses'
      and column_name = 'family_medication_id'
  ) then
    execute $sql$
      update public.family_medication_doses d
      set medication_id = coalesce(d.medication_id, d.family_medication_id)
      where d.medication_id is null
        and d.family_medication_id is not null
    $sql$;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'family_medication_doses'
      and column_name = 'family_member_id'
  ) then
    execute $sql$
      update public.family_medication_doses d
      set member_id = coalesce(d.member_id, d.family_member_id)
      where d.member_id is null
        and d.family_member_id is not null
    $sql$;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'family_medication_doses'
      and column_name = 'status'
  ) then
    execute $sql$
      update public.family_medication_doses d
      set taken = case when d.status = 'taken' then true else d.taken end
      where d.status is not null
    $sql$;
  end if;
end
$$;

update public.family_medication_doses d
set family_id = coalesce(d.family_id, fm.family_id)
from public.family_medications fm
where fm.id = coalesce(d.medication_id, null)
  and d.family_id is null;

update public.family_medication_doses d
set scheduled_date = coalesce(d.scheduled_date, d.scheduled_at::date),
    scheduled_time = coalesce(d.scheduled_time, d.scheduled_at::time)
where d.scheduled_at is not null
  and (d.scheduled_date is null or d.scheduled_time is null);

update public.family_medication_doses d
set plan_id = (
  select p.id
  from public.family_medication_plans p
  where p.family_id = d.family_id
    and p.medication_id = d.medication_id
    and p.member_id = d.member_id
    and d.scheduled_date >= p.start_date
    and (p.end_date is null or d.scheduled_date <= p.end_date)
  order by p.created_at desc
  limit 1
)
where d.plan_id is null
  and d.family_id is not null
  and d.medication_id is not null
  and d.member_id is not null
  and d.scheduled_date is not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_medication_doses_family_id_fkey'
      and conrelid = 'public.family_medication_doses'::regclass
  ) then
    alter table public.family_medication_doses
    add constraint family_medication_doses_family_id_fkey
    foreign key (family_id) references public.families(id) on delete cascade;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_medication_doses_plan_id_fkey'
      and conrelid = 'public.family_medication_doses'::regclass
  ) then
    alter table public.family_medication_doses
    add constraint family_medication_doses_plan_id_fkey
    foreign key (plan_id) references public.family_medication_plans(id) on delete cascade;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_medication_doses_medication_id_fkey'
      and conrelid = 'public.family_medication_doses'::regclass
  ) then
    alter table public.family_medication_doses
    add constraint family_medication_doses_medication_id_fkey
    foreign key (medication_id) references public.family_medications(id) on delete cascade;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_medication_doses_member_id_fkey'
      and conrelid = 'public.family_medication_doses'::regclass
  ) then
    alter table public.family_medication_doses
    add constraint family_medication_doses_member_id_fkey
    foreign key (member_id) references public.family_members(id) on delete cascade;
  end if;
end
$$;

create index if not exists idx_medication_doses_family_date
on public.family_medication_doses (family_id, scheduled_date);

create index if not exists idx_medication_doses_member_date
on public.family_medication_doses (member_id, scheduled_date);

create index if not exists idx_medication_doses_plan
on public.family_medication_doses (plan_id);

create unique index if not exists family_medication_doses_unique_instance
on public.family_medication_doses (plan_id, member_id, scheduled_date, scheduled_time)
where plan_id is not null
  and member_id is not null
  and scheduled_date is not null
  and scheduled_time is not null;

drop trigger if exists trg_medication_doses_updated_at on public.family_medication_doses;
drop trigger if exists trg_family_medication_doses_updated_at on public.family_medication_doses;

create trigger trg_medication_doses_updated_at
before update on public.family_medication_doses
for each row execute function public.set_updated_at();

drop policy if exists family_medications_select_policy on public.family_medications;
create policy family_medications_select_policy
on public.family_medications
for select
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medications.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medications_insert_policy on public.family_medications;
create policy family_medications_insert_policy
on public.family_medications
for insert
to authenticated
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medications.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medications_update_policy on public.family_medications;
create policy family_medications_update_policy
on public.family_medications
for update
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medications.family_id
      and f.created_by_user_id = auth.uid()
  )
)
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medications.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medications_delete_policy on public.family_medications;
create policy family_medications_delete_policy
on public.family_medications
for delete
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medications.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medication_plans_select_policy on public.family_medication_plans;
create policy family_medication_plans_select_policy
on public.family_medication_plans
for select
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_plans.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medication_plans_insert_policy on public.family_medication_plans;
create policy family_medication_plans_insert_policy
on public.family_medication_plans
for insert
to authenticated
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_plans.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medication_plans_update_policy on public.family_medication_plans;
create policy family_medication_plans_update_policy
on public.family_medication_plans
for update
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_plans.family_id
      and f.created_by_user_id = auth.uid()
  )
)
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_plans.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medication_plans_delete_policy on public.family_medication_plans;
create policy family_medication_plans_delete_policy
on public.family_medication_plans
for delete
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_plans.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medication_doses_select_policy on public.family_medication_doses;
create policy family_medication_doses_select_policy
on public.family_medication_doses
for select
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_doses.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medication_doses_insert_policy on public.family_medication_doses;
create policy family_medication_doses_insert_policy
on public.family_medication_doses
for insert
to authenticated
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_doses.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medication_doses_update_policy on public.family_medication_doses;
create policy family_medication_doses_update_policy
on public.family_medication_doses
for update
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_doses.family_id
      and f.created_by_user_id = auth.uid()
  )
)
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_doses.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medication_doses_delete_policy on public.family_medication_doses;
create policy family_medication_doses_delete_policy
on public.family_medication_doses
for delete
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medication_doses.family_id
      and f.created_by_user_id = auth.uid()
  )
);
