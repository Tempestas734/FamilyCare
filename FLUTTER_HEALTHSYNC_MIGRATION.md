# Flutter HealthSync Migration

## Objectif

Adapter l'application Flutter familiale pour utiliser le schema HealthSync existant, sans creer une nouvelle base et sans ajouter de profil patient avance.

## Fichiers modifies

- `lib/services/healthsync_service.dart`
- `lib/screens/family_signup_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/calendar/calendar_screen.dart`
- `lib/screens/family/family_screen.dart`
- `lib/screens/family/add_member_screen.dart`
- `lib/screens/family/edit_member_screen.dart`
- `lib/screens/family/member_profile_screen.dart`
- `lib/screens/medication/add_medication_screen.dart`
- `lib/screens/medication/manage_medications_screen.dart`
- `lib/screens/medication/medication_planning_screen.dart`
- `lib/screens/doctors/doctor_search_screen.dart`
- `lib/screens/doctors/doctor_profile_screen.dart`
- `lib/screens/doctors/doctor_list_screen.dart`
- `supabase/medications_schema.sql`
- `supabase/medication_doses_schema.sql`
- `supabase/flutter_healthsync_compatibility.sql`

## Anciennes tables remplacees

- `rendez_vous` remplacee par `appointments`
- `medecins_famille` remplacee par `family_medecins`

## Nouvelles tables utilisees

- `families`
- `family_members`
- `family_patients`
- `patients`
- `family_medications`
- `family_medication_plans`
- `family_medication_doses`
- `medecins`
- `users`
- `family_medecins`
- `appointments`

## Mappings de schema appliques

- `families.auth_user_id` -> `families.created_by_user_id`
- `families.family_id` visible -> `families.family_code`
- `family_members.auth_user_id` -> `family_members.user_id`
- `family_members.role` -> `family_members.relationship_role`
- `medecins` lit maintenant les infos personnelles via `users`
- les rendez-vous Flutter sont crees dans `appointments`

## Nouvelles requetes Supabase

- lecture du contexte famille via `family_members -> families`
- lecture des medecins via `medecins` + jointure `users`
- creation/verification du lien medecin via `family_medecins`
- lecture des rendez-vous via `appointments`
- resolution membre -> patient via `family_patients`
- creation du patient global via `patients`

## Fonctions ajoutees

Dans `lib/services/healthsync_service.dart` :

- `getCurrentFamilyContext()`
- `getFamilyMembers(String familyId)`
- `getPatientIdsForFamilyMember(String familyMemberId)`
- `getFamilyPatientLinks(String familyId)`
- `getOrCreatePatientForFamilyMember({required String familyId, required String familyMemberId})`
- `createFamilyAppointment({required String familyId, required String familyMemberId, required String medecinId, required String etablissementId, required DateTime scheduledAt, String? reason, String? notes})`
- `getDoctors()`
- `getFamilyDoctors(String familyId)`
- `ensureFamilyDoctorLink({required String familyId, required String medecinId})`
- `getFamilyAppointments(String familyId)`
- `getAppointmentsForFamilyMember({required String familyId, required String familyMemberId})`
- `getTakenAppointmentSlots({required String medecinId, required DateTime from, required DateTime to})`

## Bugs corriges

- suppression de l'usage de `auth_user_id` dans Flutter
- suppression de l'usage de `role` comme colonne SQL dans `family_members`
- suppression de l'usage direct de `medecins.first_name`, `last_name`, `email`, `telephone`
- suppression des insertions et lectures via `medecins_famille`
- suppression des insertions de rendez-vous dans `rendez_vous`
- accueil et calendrier bascules sur `appointments` + `family_patients`
- scripts SQL locaux de medicaments alignes sur `family_members.user_id`

## Tests manuels a faire

### Famille

- creer une famille
- verifier insertion dans `families.created_by_user_id`
- verifier presence d'un `family_code`
- verifier insertion membre admin dans `family_members.user_id`

### Membres

- ajouter un membre
- modifier un membre
- verifier lecture de `relationship_role`

### Patients globaux

- creer un rendez-vous pour un membre sans lien patient existant
- verifier creation d'une ligne dans `patients`
- verifier que `barcode_value` est genere par la base
- verifier que `patient_code` reste null si aucune CIN n'est saisie
- verifier creation d'une ligne dans `family_patients`

### Medecins

- rechercher un medecin
- verifier affichage du nom depuis `users`
- ajouter un medecin a la famille
- verifier insertion dans `family_medecins`

### Rendez-vous

- creer un rendez-vous depuis la fiche medecin
- verifier insertion dans `appointments`
- verifier `patient_id`, `medecin_id`, `etablissement_id`
- verifier `requested_by_type = 'family'`
- verifier `requested_by_id = family_id`
- verifier `source = 'mobile_app'`
- verifier affichage sur l'accueil
- verifier affichage dans le calendrier

### Medicaments

- creer un medicament
- creer un plan de prise
- verifier generation/lecture des doses
- verifier marquage "pris"

## Limites / verification

- `flutter analyze` n'a pas pu etre termine dans cet environnement car la commande depasse le timeout
- la verification a ete faite par migration ciblee des fichiers et par scan textuel des anciennes references de schema
