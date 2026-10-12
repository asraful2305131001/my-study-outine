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
