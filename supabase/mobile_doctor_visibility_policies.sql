alter table public.medecins enable row level security;
alter table public.users enable row level security;
alter table public.etablissements enable row level security;
alter table public.medecin_etablissements enable row level security;
alter table public.medecin_horaires_semaine enable row level security;
alter table public.medecin_horaire_intervalles enable row level security;
alter table public.medecin_indisponibilites enable row level security;
alter table public.appointments enable row level security;

drop policy if exists medecins_select_authenticated on public.medecins;
create policy medecins_select_authenticated
on public.medecins
for select
to authenticated
using (true);

drop policy if exists users_select_doctor_public_info on public.users;
create policy users_select_doctor_public_info
on public.users
for select
to authenticated
using (true);

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
