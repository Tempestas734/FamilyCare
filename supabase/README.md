## Active Scripts

Apply these scripts in this order for the current app:

1. `family_member_patient_link_fixes.sql`
2. `family_doctor_appointment_fixes.sql`
3. `family_medication_alignment_fixes.sql`

These are the canonical migrations for the current Flutter codebase.

## Identifier Rules

In `patients`:

- `patient_code`: internal patient/member identifier
- `cin`: national identity card number, optional
- `barcode_value`: generated scan identifier

This supports minors who do not yet have a `cin`.

## Legacy Scripts

These files are kept only as historical references and should not be used as the primary source of truth for new environments:

- `medications_schema.sql`
- `medication_doses_schema.sql`
- `mobile_doctor_visibility_policies.sql`

They were superseded by the `family_*_fixes.sql` scripts above.
