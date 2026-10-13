-- Run this in Supabase Dashboard > SQL Editor
create table if not exists public.study_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.study_data enable row level security;
drop policy if exists "Users can read their own study data" on public.study_data;
create policy "Users can read their own study data" on public.study_data for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Users can insert their own study data" on public.study_data;
create policy "Users can insert their own study data" on public.study_data for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Users can update their own study data" on public.study_data;
create policy "Users can update their own study data" on public.study_data for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Shared DIU content and user-submitted changes. Add the owner to
-- class_routine_admins manually after creating their account (see README_SETUP.txt).
create table if not exists public.class_routine_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.class_routine_admins enable row level security;
drop policy if exists "Admins can see their own admin status" on public.class_routine_admins;
create policy "Admins can see their own admin status" on public.class_routine_admins
  for select to authenticated using (user_id = auth.uid());

create or replace function public.is_class_routine_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.class_routine_admins where user_id = auth.uid()
  );
$$;
revoke all on function public.is_class_routine_admin() from public;
grant execute on function public.is_class_routine_admin() to authenticated;

create table if not exists public.class_routine_content (
  id text primary key check (id = 'main'),
  data jsonb not null default
    '{"routine":[],"tasks":[],"teachers":[],"rooms":[],"contacts":[],"events":[],"notices":[]}'::jsonb,
  updated_at timestamptz not null default now()
);
insert into public.class_routine_content (id) values ('main') on conflict (id) do nothing;
alter table public.class_routine_content enable row level security;
drop policy if exists "Signed-in users can read shared DIU content" on public.class_routine_content;
create policy "Signed-in users can read shared DIU content" on public.class_routine_content
  for select to authenticated using (true);
drop policy if exists "Admins can manage shared DIU content" on public.class_routine_content;
create policy "Admins can manage shared DIU content" on public.class_routine_content
  for all to authenticated using (public.is_class_routine_admin())
  with check (public.is_class_routine_admin());

create table if not exists public.class_routine_requests (
  id uuid primary key default gen_random_uuid(),
  submitter_id uuid not null references auth.users(id) on delete cascade,
  submitter_name text not null default '',
  submitter_role text not null default 'Student'
    check (submitter_role in ('Student', 'CR', 'Teacher')),
  category text not null
    check (category in ('routine', 'task', 'teacher', 'room', 'contact', 'event', 'notice')),
  title text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz
);
create index if not exists class_routine_requests_submitter_created_idx
  on public.class_routine_requests (submitter_id, created_at desc);
create index if not exists class_routine_requests_status_created_idx
  on public.class_routine_requests (status, created_at desc);
alter table public.class_routine_requests enable row level security;
drop policy if exists "Users can submit their own content requests" on public.class_routine_requests;
create policy "Users can submit their own content requests" on public.class_routine_requests
  for insert to authenticated with check (
    submitter_id = auth.uid() and status = 'pending'
    and reviewed_by is null and reviewed_at is null
  );
drop policy if exists "Users can read own requests and admins can read all" on public.class_routine_requests;
create policy "Users can read own requests and admins can read all" on public.class_routine_requests
  for select to authenticated using (
    submitter_id = auth.uid() or public.is_class_routine_admin()
  );

create or replace function public.review_class_routine_request(
  p_request_id uuid,
  p_decision text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  request_row public.class_routine_requests%rowtype;
  content_key text;
begin
  if not public.is_class_routine_admin() then
    raise exception 'Only a Class Routine admin can review requests';
  end if;
  if p_decision not in ('approved', 'rejected') then
    raise exception 'Decision must be approved or rejected';
  end if;

  select * into request_row
  from public.class_routine_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Request not found';
  end if;
  if request_row.status <> 'pending' then
    raise exception 'Request has already been reviewed';
  end if;

  if p_decision = 'approved' then
    content_key := case request_row.category
      when 'routine' then 'routine'
      when 'task' then 'tasks'
      when 'teacher' then 'teachers'
      when 'room' then 'rooms'
      when 'contact' then 'contacts'
      when 'event' then 'events'
      when 'notice' then 'notices'
    end;
    update public.class_routine_content
    set data = jsonb_set(
      data,
      array[content_key],
      coalesce(data -> content_key, '[]'::jsonb) || jsonb_build_array(request_row.payload),
      true
    ),
    updated_at = now()
    where id = 'main';
  end if;

  update public.class_routine_requests
  set status = p_decision, reviewed_by = auth.uid(), reviewed_at = now()
  where id = p_request_id;
end;
$$;
revoke all on function public.review_class_routine_request(uuid, text) from public;
grant execute on function public.review_class_routine_request(uuid, text) to authenticated;

-- Optional: private bucket for course materials. Set a reasonable file-size limit in Storage settings.
insert into storage.buckets (id, name, public) values ('study-materials', 'study-materials', false)
on conflict (id) do nothing;
drop policy if exists "Users can upload own study materials" on storage.objects;
create policy "Users can upload own study materials" on storage.objects for insert to authenticated
with check (bucket_id = 'study-materials' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Users can read own study materials" on storage.objects;
create policy "Users can read own study materials" on storage.objects for select to authenticated
using (bucket_id = 'study-materials' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Users can update own study materials" on storage.objects;
create policy "Users can update own study materials" on storage.objects for update to authenticated
using (bucket_id = 'study-materials' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'study-materials' and (storage.foldername(name))[1] = auth.uid()::text);
