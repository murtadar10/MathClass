-- سجل المختبر: الجزء الرابع (الواجب اليومي، نقاط المجموعات، ملاحظات السجل)
-- Supabase → SQL Editor → الصق الملف كاملًا → Run

alter table sgrades alter column value drop not null;
alter table sgrades add column if not exists note text;
alter table sgrades drop constraint if exists sgrades_comp_check;
alter table sgrades add constraint sgrades_comp_check
  check (comp in ('w1','w2','w3','part','att','hw','clean','beh','mid','note'));

alter table groups add column if not exists round_ts timestamptz default now();

create table if not exists hwlog (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  class_id uuid not null references classes on delete cascade,
  day date not null,
  student_id uuid references students on delete cascade);   -- فارغ = يوم فيه واجب، ممتلئ = طالب لم يحلّه

create table if not exists group_pts (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  group_id uuid not null references groups on delete cascade,
  points int not null, note text, created_at timestamptz default now());

do $$ declare t text; begin
  foreach t in array array['hwlog','group_pts'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists own on %I', t);
    execute format('create policy own on %I for all using (owner = auth.uid()) with check (owner = auth.uid())', t);
  end loop;
end $$;
