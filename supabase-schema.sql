-- ========================================================
-- AM VISUAL STUDIO - Supabase Database Schema
-- ========================================================

-- 1. Create a table for projects
create table public.projects (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  category text not null,
  video_url text,
  youtube_url text,
  vimeo_url text,
  thumbnail_url text,
  project_date date,
  featured boolean default false,
  published boolean default false,
  status text default 'draft' check (status in ('draft', 'published')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  owner_id uuid references auth.users(id)
);

-- 2. Create a bucket for media storage
-- (Note: Storage buckets are usually created via UI, but here is the RLS for them)
-- Name: projects-media (for mp4, thumbnails)

-- 3. Enable Row Level Security (RLS)
alter table public.projects enable row level security;

-- 4. Create Policies

-- Allow public read access to published projects
create policy "Public can view published projects"
on public.projects for select
using (published = true);

-- Allow admins (authenticated users) full access
create policy "Admins have full access"
on public.projects for all
to authenticated
using (true)
with check (true);

-- 5. Trigger for updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_updated_at
before update on public.projects
for each row
execute procedure public.handle_updated_at();

-- 6. Setup for admin user check (optional helper)
create or replace function public.is_admin()
returns boolean as $$
begin
  return (auth.role() = 'authenticated');
end;
$$ language plpgsql security definer;