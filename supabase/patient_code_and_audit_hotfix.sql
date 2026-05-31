-- Hotfix for already migrated environments.
-- 1) Auto-generate patient_code when missing
-- 2) Disable broken audit triggers that reference audit_logs.table_name

create extension if not exists pgcrypto;

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

drop trigger if exists trg_audit_patients on public.patients;
drop trigger if exists trg_audit_appointments on public.appointments;
