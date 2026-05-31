-- Review first, then execute if the rows match failed attempts.
-- هدفه حذف les membres famille créés sans patient lié.

-- 1) Inspect orphan members
select
  fm.id,
  fm.family_id,
  fm.full_name,
  fm.relationship_role,
  fm.birth_date,
  fm.created_at
from public.family_members fm
left join public.family_patients fp
  on fp.family_member_id = fm.id
where fp.id is null
order by fm.created_at desc;

-- 2) Delete orphan members
-- Uncomment only after review.
-- delete from public.family_members fm
-- where not exists (
--   select 1
--   from public.family_patients fp
--   where fp.family_member_id = fm.id
-- );
