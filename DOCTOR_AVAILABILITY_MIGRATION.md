# Doctor Availability Migration

## Objectif

Adapter la couche Flutter medecins pour afficher les praticiens par etablissement, lire les horaires reels, bloquer les indisponibilites et empecher la reservation des creneaux deja pris.

## Fichiers modifies

- `lib/services/healthsync_service.dart`
- `lib/screens/doctors/doctor_search_screen.dart`
- `lib/screens/doctors/doctor_profile_screen.dart`
- `lib/screens/doctors/doctor_list_screen.dart`
- `supabase/mobile_doctor_visibility_policies.sql`

## Anciennes erreurs corrigees

- utilisation de `medecins.first_name`, `last_name`, `email`, `phone`
- jointures `users!inner` qui masquaient les medecins sans ligne `users`
- absence de prise en compte des etablissements actifs du medecin
- faux creneaux generes en dur dans Flutter
- lecture des rendez-vous pris sans filtre `etablissement_id`
- creation de rendez-vous sans verification de disponibilite reelle

## Nouvelles requetes Supabase

- lecture des medecins via `medecins + users:user_id + medecin_etablissements + etablissements`
- lecture des horaires via `medecin_horaires_semaine + medecin_horaire_intervalles`
- lecture des absences via `medecin_indisponibilites`
- lecture des creneaux occupes via `appointments`
- creation du rendez-vous via `appointments`

## Nouveaux modeles

Dans `lib/services/healthsync_service.dart` :

- `DoctorEstablishment`
- `DoctorAvailabilityDay`
- `DoctorAvailabilityInterval`
- `DoctorUnavailability`
- `HealthsyncDoctor` enrichi avec `fullName`, `numeroOrdre`, `signatureName`, `establishments`

## Logique de disponibilite

1. Charger les etablissements actifs du medecin
2. Charger les jours actifs dans `medecin_horaires_semaine`
3. Charger les intervalles de chaque jour dans `medecin_horaire_intervalles`
4. Charger les indisponibilites entre `from` et `to`
5. Charger les rendez-vous deja pris sur le meme medecin et le meme etablissement
6. Construire les creneaux par pas de 15 minutes
7. Filtrer un creneau si :
   - le jour n'est pas actif
   - l'heure ne rentre dans aucun intervalle
   - une indisponibilite toute la journee couvre la date
   - une indisponibilite partielle chevauche le creneau
   - un rendez-vous existe deja sur ce creneau

## Regles de blocage

- medecin sans `users.is_active = true` : exclu
- medecin sans etablissement actif : exclu
- etablissement inactif : exclu
- aucun horaire actif : aucun creneau propose
- indisponibilite recouvrante : creneau refuse
- appointment deja pris : creneau refuse

## Ecrans modifies

- `doctor_search_screen.dart`
  - filtres par specialite et ville
  - affichage nom, specialite, note, langues, etablissement principal
  - bouton `Voir disponibilites`
  - bouton `Ajouter`

- `doctor_profile_screen.dart`
  - chargement detail medecin depuis la base
  - choix d'etablissement si plusieurs
  - affichage horaires hebdomadaires
  - affichage indisponibilites
  - calcul des creneaux disponibles
  - prise de rendez-vous depuis un membre de famille

- `doctor_list_screen.dart`
  - liste des medecins deja lies a la famille
  - ouverture de la fiche detail

## Tests manuels a faire

### Test 1 : Affichage medecins

- ouvrir recherche medecins
- verifier nom, specialite, email/telephone, etablissement, ville

### Test 2 : Filtre etablissement

- filtrer par ville
- verifier que seuls les medecins relies a un etablissement actif s'affichent

### Test 3 : Disponibilites

- ouvrir fiche medecin
- choisir etablissement
- verifier affichage des horaires hebdomadaires

### Test 4 : Indisponibilite

- creer une indisponibilite cote web
- verifier que Flutter bloque le jour/creneau

### Test 5 : Creneau deja pris

- creer un rendez-vous cote web ou Flutter
- verifier que le meme creneau n'apparait plus comme libre

### Test 6 : Creation rendez-vous

- choisir membre famille
- choisir medecin
- choisir etablissement
- choisir creneau libre
- creer rendez-vous
- verifier insertion dans `appointments` avec :
  - `source = mobile_app`
  - `requested_by_type = family`
  - `requested_by_id = family_id`
  - `patient_id` non null

## Limites

- `flutter analyze` n'a pas pu etre execute jusqu'au bout dans cet environnement
- l'UI a ete simplifiee pour fiabiliser la logique de disponibilite
- si `scheduled_end_at` est obligatoire en insert sans trigger DB, il faudra l'ajouter explicitement
