-- Canonical migration for family/member/patient access and patient identifiers.
-- Current rule:
-- - patient_code = internal patient/member identifier
-- - cin = national ID, optional (can be null for minors)

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

alter table public.patients
alter column patient_code drop not null;

alter table public.patients
drop constraint if exists patients_patient_code_key;

drop index if exists public.patients_patient_code_not_null_idx;
drop index if exists public.patients_barcode_value_idx;

create unique index if not exists patients_patient_code_unique_not_null
on public.patients(patient_code)
where patient_code is not null;

create or replace function public.set_patient_defaults()
returns trigger
language plpgsql
as $$
begin
  if new.patient_code is not null then
    new.patient_code := upper(trim(new.patient_code));
    if new.patient_code = '' then
      new.patient_code := null;
    end if;
  end if;

  if new.patient_code is null then
    new.patient_code := 'PT-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
  end if;

  if new.cin is not null then
    new.cin := upper(trim(new.cin));

    if new.cin = '' then
      new.cin := null;
    end if;
  end if;

  if new.barcode_value is null or trim(new.barcode_value) = '' then
    new.barcode_value := 'BC-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
  end if;

  return new;
end;
$$;

drop trigger if exists trg_patients_defaults on public.patients;
drop trigger if exists trg_patients_set_defaults on public.patients;
drop trigger if exists trg_audit_patients on public.patients;

create trigger trg_patients_defaults
before insert or update on public.patients
for each row execute function public.set_patient_defaults();

alter table public.family_patients
add column if not exists family_member_id uuid null;

alter table public.family_patients
drop constraint if exists family_patients_family_member_id_fkey;

alter table public.family_patients
add constraint family_patients_family_member_id_fkey
foreign key (family_member_id)
references public.family_members(id)
on delete set null;

alter table public.family_patients
drop constraint if exists family_patients_family_member_unique;

alter table public.family_patients
add constraint family_patients_family_member_unique
unique (family_id, family_member_id);

alter table public.family_patients
drop constraint if exists family_patients_member_patient_unique;

alter table public.family_patients
add constraint family_patients_member_patient_unique
unique (family_member_id, patient_id);

create index if not exists family_patients_family_member_idx
on public.family_patients(family_member_id);

create index if not exists family_patients_patient_idx
on public.family_patients(patient_id);

create index if not exists family_patients_family_idx
on public.family_patients(family_id);

create or replace function public.current_user_family_ids()
returns setof uuid
language sql
security definer
set search_path = public
as $$
  select fm.family_id
  from public.family_members fm
  where fm.user_id = auth.uid()
$$;

grant execute on function public.current_user_family_ids() to authenticated;

alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.family_patients enable row level security;
alter table public.patients enable row level security;

do $$
declare
  policy_record record;
begin
  for policy_record in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('families', 'family_members', 'family_patients', 'patients')
  loop
    execute format(
      'drop policy if exists %I on %I.%I',
      policy_record.policyname,
      policy_record.schemaname,
      policy_record.tablename
    );
  end loop;
end
$$;

create policy families_select_authenticated
on public.families
for select
to authenticated
using (
  created_by_user_id = auth.uid()
  or id in (select public.current_user_family_ids())
);

create policy families_insert_authenticated
on public.families
for insert
to authenticated
with check (created_by_user_id = auth.uid());

create policy families_update_authenticated
on public.families
for update
to authenticated
using (
  created_by_user_id = auth.uid()
  or id in (select public.current_user_family_ids())
)
with check (
  created_by_user_id = auth.uid()
  or id in (select public.current_user_family_ids())
);

create policy family_members_select_authenticated
on public.family_members
for select
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_members.family_id
      and f.created_by_user_id = auth.uid()
  )
);

create policy family_members_insert_authenticated
on public.family_members
for insert
to authenticated
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_members.family_id
      and f.created_by_user_id = auth.uid()
  )
);

create policy family_members_update_authenticated
on public.family_members
for update
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_members.family_id
      and f.created_by_user_id = auth.uid()
  )
)
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_members.family_id
      and f.created_by_user_id = auth.uid()
  )
);

create policy family_members_delete_authenticated
on public.family_members
for delete
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_members.family_id
      and f.created_by_user_id = auth.uid()
  )
);

create policy family_patients_select_authenticated
on public.family_patients
for select
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_patients.family_id
      and f.created_by_user_id = auth.uid()
  )
);

create policy family_patients_insert_authenticated
on public.family_patients
for insert
to authenticated
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_patients.family_id
      and f.created_by_user_id = auth.uid()
  )
);

create policy family_patients_update_authenticated
on public.family_patients
for update
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_patients.family_id
      and f.created_by_user_id = auth.uid()
  )
)
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_patients.family_id
      and f.created_by_user_id = auth.uid()
  )
);

create policy family_patients_delete_authenticated
on public.family_patients
for delete
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_patients.family_id
      and f.created_by_user_id = auth.uid()
  )
);

create policy patients_select_authenticated
on public.patients
for select
to authenticated
using (true);

create policy patients_insert_authenticated
on public.patients
for insert
to authenticated
with check (true);
