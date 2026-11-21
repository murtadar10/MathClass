-- سجل المختبر: إعداد قاعدة البيانات (Supabase → SQL Editor → الصق الملف كاملًا → Run)
-- لا تنسونا من صالح دعائكم

-- 1) قائمة البريد المسموح لها بإنشاء حساب (أنت تضيف بريد كل معلم هنا)
create table if not exists allowed_emails (email text primary key);
alter table allowed_emails enable row level security;  -- لا سياسات = لا وصول من المتصفح
insert into allowed_emails values ('murtadar13@gmail.com') on conflict do nothing;

create or replace function check_allowed_email() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from allowed_emails where lower(email) = lower(new.email)) then
    raise exception 'email not allowed';
  end if;
  return new;
end $$;

drop trigger if exists t_check_allowed_email on auth.users;
create trigger t_check_allowed_email before insert on auth.users
for each row execute function check_allowed_email();

-- 2) الجداول
create table if not exists classes (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  name text not null, created_at timestamptz default now());

create table if not exists students (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  class_id uuid not null references classes on delete cascade,
  name text not null, seat int, created_at timestamptz default now());

create table if not exists attendance (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  student_id uuid not null references students on delete cascade,
  day date not null, status text not null check (status in ('a','l','e')),
  unique (student_id, day));

create table if not exists records (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  student_id uuid not null references students on delete cascade,
  kind text not null check (kind in ('v','a')),
  title text not null, points int not null check (points > 0),
  day date not null, note text, created_at timestamptz default now());

create table if not exists plans (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  day date not null, topic text, goals text, activities text, homework text,
  unique (owner, day));

-- 3) عزل بيانات كل معلم عن غيره
do $$ declare t text; begin
  foreach t in array array['classes','students','attendance','records','plans'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists own on %I', t);
    execute format('create policy own on %I for all using (owner = auth.uid()) with check (owner = auth.uid())', t);
  end loop;
end $$;
