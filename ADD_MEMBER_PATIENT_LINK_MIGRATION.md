# Add Member Patient Link Migration

## Objectif

Rectifier l'ecran d'ajout de membre famille pour gerer deux parcours :

- lier un membre famille a un patient global deja existant
- creer un nouveau patient global puis le lier au membre famille

## Fichiers modifies

- `lib/services/healthsync_service.dart`
- `lib/screens/family/add_member_screen.dart`
- `supabase/family_member_patient_link_fixes.sql`

## Nouvelles fonctions ajoutees

Dans `lib/services/healthsync_service.dart` :

- `findExistingPatient({String? patientId, String? cin, String? barcodeValue})`
- `createFamilyMember({required String familyId, required String fullName, required String relationshipRole, DateTime? birthDate, String? bloodType, double? weightKg})`
- `createPatientFromFamilyMember({required String fullName, DateTime? birthDate, String? gender, String? phone, String? email, String? bloodGroup, String? cin})`
- `linkPatientToFamilyMember({required String familyId, required String familyMemberId, required String patientId, String? relationship})`
- `addFamilyMemberWithExistingPatient({required String familyId, required String fullName, required String relationshipRole, required String patientId, DateTime? birthDate, String? bloodType, double? weightKg})`
- `addFamilyMemberWithNewPatient({required String familyId, required String fullName, required String relationshipRole, DateTime? birthDate, String? gender, String? phone, String? email, String? bloodType, double? weightKg, String? cin})`

## Option 1 : patient existant

Logique appliquee :

1. l'utilisateur choisit le mode `Patient deja existant`
2. il saisit `patient_id`, `CIN` ou `barcode_value`
3. Flutter appelle `findExistingPatient`
4. si un patient est trouve, l'ecran affiche sa carte resume
5. Flutter cree le `family_member`
6. Flutter cree ou met a jour la liaison `family_patients`

Regles :

- au moins un des champs de recherche doit etre renseigne
- aucun nouveau patient n'est cree dans ce mode
- si le patient est deja lie au meme membre, un message clair est renvoye

## Option 2 : nouveau patient

Logique appliquee :

1. l'utilisateur choisit le mode `Nouveau patient`
2. Flutter cree d'abord le `family_member`
3. Flutter cree ensuite une ligne dans `patients`
4. Flutter laisse la base generer `barcode_value`
5. `patient_code` est rempli seulement si la CIN est saisie
6. Flutter cree la liaison `family_patients`
7. l'ecran affiche le `barcode_value` genere

Regles :

- `full_name` obligatoire
- `relationship_role` obligatoire
- `CIN` optionnelle
- en cas de conflit sur la CIN, l'utilisateur est redirige vers le mode patient existant

## Ecran Flutter

`add_member_screen.dart` contient maintenant :

- un selecteur de mode `Patient deja existant / Nouveau patient`
- un formulaire de recherche de patient existant
- une carte resultat patient
- un formulaire de creation de nouveau patient
- une saisie manuelle du `barcode_value`
- un TODO explicite pour le scan camera

## SQL ajoute

`supabase/family_member_patient_link_fixes.sql` contient :

- normalisation de `patient_code`
- generation automatique de `barcode_value`
- trigger `trg_patients_defaults`
- ajout/verrouillage de `family_patients.family_member_id`
- index et contraintes utiles sur `family_patients`

## Tests manuels a faire

1. Ajouter membre avec patient existant par `patient_id`
2. Ajouter membre avec patient existant par `CIN`
3. Ajouter membre avec patient existant par `barcode_value` manuel
4. Ajouter membre avec patient existant par scan camera si disponible plus tard
5. Ajouter membre nouveau patient sans `CIN`
6. Ajouter membre nouveau patient avec `CIN`
7. Verifier `family_members`
8. Verifier `patients`
9. Verifier `family_patients`
10. Verifier `barcode_value` genere
11. Verifier `patient_code` null si pas de `CIN`
12. Verifier `patient_code` rempli si `CIN` saisie
13. Verifier que les rendez-vous utilisent `patient_id` via `family_patients`

## Verification a faire cote base

- verifier les policies RLS `patients`
- verifier les policies RLS `family_members`
- verifier les policies RLS `family_patients`
- verifier que le trigger `set_patient_defaults()` est bien actif
