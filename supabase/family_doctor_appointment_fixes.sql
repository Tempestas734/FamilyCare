create extension if not exists btree_gist;

drop index if exists public.medecins_user_id_unique_idx;
drop index if exists public.medecin_etablissements_unique_idx;
drop index if exists public.medecin_etablissements_unique_medecin_etablissement;

drop trigger if exists trg_check_appointment_against_indisponibilites
on public.appointments;

drop trigger if exists trg_audit_appointments
on public.appointments;

alter table public.family_medecins enable row level security;
alter table public.medecins enable row level security;
alter table public.users enable row level security;
alter table public.etablissements enable row level security;
alter table public.medecin_etablissements enable row level security;
alter table public.medecin_horaires_semaine enable row level security;
alter table public.medecin_horaire_intervalles enable row level security;
alter table public.medecin_indisponibilites enable row level security;
alter table public.appointments enable row level security;

drop policy if exists family_medecins_select_authenticated on public.family_medecins;
create policy family_medecins_select_authenticated
on public.family_medecins
for select
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medecins.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medecins_insert_authenticated on public.family_medecins;
create policy family_medecins_insert_authenticated
on public.family_medecins
for insert
to authenticated
with check (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medecins.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists family_medecins_delete_authenticated on public.family_medecins;
create policy family_medecins_delete_authenticated
on public.family_medecins
for delete
to authenticated
using (
  family_id in (select public.current_user_family_ids())
  or exists (
    select 1
    from public.families f
    where f.id = family_medecins.family_id
      and f.created_by_user_id = auth.uid()
  )
);

drop policy if exists medecins_select_authenticated on public.medecins;
drop policy if exists "Anyone can read medecins" on public.medecins;
drop policy if exists medecins_select_all on public.medecins;
drop policy if exists medecins_select_accessible on public.medecins;
create policy medecins_select_authenticated
on public.medecins
for select
to authenticated
using (true);

drop policy if exists "Medecin can update his profile" on public.medecins;
drop policy if exists medecins_update_self_or_admin on public.medecins;
create policy medecins_update_self_authenticated
on public.medecins
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists users_select_doctor_public_info on public.users;
create policy users_select_doctor_public_info
on public.users
for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.medecins m
    where m.user_id = users.id
  )
);

drop policy if exists etablissements_select_active on public.etablissements;
create policy etablissements_select_active
on public.etablissements
for select
to authenticated
using (actif = true);

drop policy if exists medecin_etablissements_select_active on public.medecin_etablissements;
create policy medecin_etablissements_select_active
on public.medecin_etablissements
for select
to authenticated
using (actif = true);

drop policy if exists horaires_semaine_select_authenticated on public.medecin_horaires_semaine;
create policy horaires_semaine_select_authenticated
on public.medecin_horaires_semaine
for select
to authenticated
using (is_active = true);

drop policy if exists horaire_intervalles_select_authenticated on public.medecin_horaire_intervalles;
create policy horaire_intervalles_select_authenticated
on public.medecin_horaire_intervalles
for select
to authenticated
using (true);

drop policy if exists medecin_indisponibilites_select_authenticated on public.medecin_indisponibilites;
create policy medecin_indisponibilites_select_authenticated
on public.medecin_indisponibilites
for select
to authenticated
using (true);

drop policy if exists appointments_select_slots_authenticated on public.appointments;
create policy appointments_select_slots_authenticated
on public.appointments
for select
to authenticated
using (
  status in ('pending', 'confirmed', 'follow_up_planned')
);

drop policy if exists appointments_family_select_authenticated on public.appointments;
create policy appointments_family_select_authenticated
on public.appointments
for select
to authenticated
using (
  requested_by_type = 'family'
  and requested_by_id in (select public.current_user_family_ids())
);

drop policy if exists appointments_family_insert_authenticated on public.appointments;
create policy appointments_family_insert_authenticated
on public.appointments
for insert
to authenticated
with check (
  requested_by_type = 'family'
  and requested_by_id in (select public.current_user_family_ids())
  and created_by_user_id = auth.uid()
  and exists (
    select 1
    from public.family_patients fp
    where fp.family_id = appointments.requested_by_id
      and fp.patient_id = appointments.patient_id
      and fp.can_view_appointments = true
  )
);

drop policy if exists appointments_family_update_authenticated on public.appointments;
create policy appointments_family_update_authenticated
on public.appointments
for update
to authenticated
using (
  requested_by_type = 'family'
  and requested_by_id in (select public.current_user_family_ids())
)
with check (
  requested_by_type = 'family'
  and requested_by_id in (select public.current_user_family_ids())
  and exists (
    select 1
    from public.family_patients fp
    where fp.family_id = appointments.requested_by_id
      and fp.patient_id = appointments.patient_id
      and fp.can_view_appointments = true
  )
);
