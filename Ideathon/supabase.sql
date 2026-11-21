-- Civicly database setup. Run in the Supabase SQL editor.
create extension if not exists pgcrypto;

create type public.app_role as enum ('citizen', 'admin');
create type public.complaint_status as enum ('Submitted', 'Under Review', 'In Progress', 'Resolved', 'Rejected');
create type public.complaint_category as enum ('Road Damage', 'Water Leakage', 'Garbage', 'Pollution', 'Drainage', 'Other');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  email text not null,
  role public.app_role not null default 'citizen',
  created_at timestamptz not null default now()
);

create table public.complaints (
  id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  category public.complaint_category not null,
  description text not null check (char_length(description) between 15 and 1200),
  media_url text,
  location text not null check (char_length(location) between 1 and 180),
  urgency_level integer not null default 0 check (urgency_level between 0 and 3),
  affected_people integer not null default 0 check (affected_people between 0 and 3),
  duration_level integer not null default 0 check (duration_level between 0 and 3),
  severity_score integer generated always as (
    least(100, greatest(0,
      (case category
        when 'Road Damage' then 24
        when 'Water Leakage' then 22
        when 'Garbage' then 15
        when 'Pollution' then 25
        when 'Drainage' then 22
        else 10
      end) + urgency_level * 13 + affected_people * 8 + duration_level * 7
    ))
  ) stored,
  severity_level text generated always as (
    case when least(100, greatest(0,
      (case category
        when 'Road Damage' then 24
        when 'Water Leakage' then 22
        when 'Garbage' then 15
        when 'Pollution' then 25
        when 'Drainage' then 22
        else 10
      end) + urgency_level * 13 + affected_people * 8 + duration_level * 7
    )) >= 70 then 'High'
    when least(100, greatest(0,
      (case category
        when 'Road Damage' then 24
        when 'Water Leakage' then 22
        when 'Garbage' then 15
        when 'Pollution' then 25
        when 'Drainage' then 22
        else 10
      end) + urgency_level * 13 + affected_people * 8 + duration_level * 7
    )) >= 40 then 'Medium'
    else 'Low' end
  ) stored,
  assigned_department text not null,
  status public.complaint_status not null default 'Submitted',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index complaints_created_at_idx on public.complaints (created_at desc);
create index complaints_user_id_idx on public.complaints (user_id);
create index complaints_status_idx on public.complaints (status);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin') $$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$ begin
  insert into public.profiles(id, name, email)
  values(new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)), new.email);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.complaints enable row level security;

-- Do not inherit broad default grants. Access below is granted explicitly.
revoke all on public.profiles from public, anon, authenticated;
revoke all on public.complaints from public, anon, authenticated;
grant select on public.profiles to authenticated;
grant update (name) on public.profiles to authenticated;
grant select on public.complaints to authenticated;
grant insert (id, user_id, title, category, description, media_url, location, urgency_level, affected_people, duration_level, assigned_department, status) on public.complaints to authenticated;
grant update (title, description, media_url, location, status, assigned_department) on public.complaints to authenticated;
grant delete on public.complaints to authenticated;

create policy "Users can read their own profile" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "Users can update their own profile name" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "Citizens and admins can read authorized complaints" on public.complaints
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "Citizens can create own complaints" on public.complaints
  for insert to authenticated with check (user_id = auth.uid() and status = 'Submitted' and assigned_department = case category
    when 'Road Damage' then 'Public Works Department'
    when 'Water Leakage' then 'Water Supply Department'
    when 'Garbage' then 'Sanitation Department'
    when 'Pollution' then 'Pollution Control Department'
    when 'Drainage' then 'Drainage Department'
    else 'Municipal Services Department' end);
create policy "Citizens can update own complaint content" on public.complaints
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Admins can update complaint management fields" on public.complaints
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Admins can delete complaints" on public.complaints
  for delete to authenticated using (public.is_admin());

-- Public dashboard view deliberately omits user_id, description, media path, and all contact data.
-- It is owner-rights so anonymous visitors can read only this projection while the base table stays private.
create or replace view public.public_complaints with (security_barrier = true, security_invoker = false) as
  select id, title, category, location, severity_score, severity_level, assigned_department, status, created_at, updated_at
  from public.complaints;
revoke all on public.public_complaints from public, anon, authenticated;
grant select on public.public_complaints to anon, authenticated;

-- Enforce field-level ownership even when a citizen updates their own report.
create or replace function public.guard_complaint_update()
returns trigger language plpgsql security definer set search_path = ''
as $$ begin
  if not public.is_admin() then
    if old.user_id <> auth.uid() then raise exception 'You may only edit your own report'; end if;
    if new.status is distinct from old.status
      or new.assigned_department is distinct from old.assigned_department
      or new.category is distinct from old.category
      or new.urgency_level is distinct from old.urgency_level
      or new.affected_people is distinct from old.affected_people
      or new.duration_level is distinct from old.duration_level
      or new.user_id is distinct from old.user_id
      or new.created_at is distinct from old.created_at then
      raise exception 'Only administrators may change report status, department, or triage';
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;
create trigger guard_complaint_update before update on public.complaints
for each row execute procedure public.guard_complaint_update();

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('complaint-media','complaint-media',false,26214400,array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','audio/mpeg','audio/mp4','audio/wav','audio/webm'])
on conflict (id) do nothing;
create policy "Users can upload their own evidence" on storage.objects
  for insert to authenticated with check (bucket_id = 'complaint-media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Owners and admins can read evidence" on storage.objects
  for select to authenticated using (bucket_id = 'complaint-media' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
create policy "Owners and admins can delete evidence" on storage.objects
  for delete to authenticated using (bucket_id = 'complaint-media' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- Promote a trusted account to administrator manually after registering:
-- update public.profiles set role = 'admin' where email = 'admin@example.org';
