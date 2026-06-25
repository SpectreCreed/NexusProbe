-- ============================================================
-- Email OSINT Dashboard — Supabase Database Migration
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ─── 1. Profiles (synced with auth.users) ────────────────
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text not null,
  updated_at timestamptz default timezone('utc', now()) not null,
  created_at timestamptz default timezone('utc', now()) not null
);

alter table public.profiles enable row level security;

create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ─── 2. Searches ─────────────────────────────────────────
create table if not exists public.searches (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete set null,
  email text not null,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'failed')),
  error_message text,
  results jsonb default '{}'::jsonb,
  created_at timestamptz default timezone('utc', now()) not null
);

alter table public.searches enable row level security;

create policy "Users can manage their own searches"
  on public.searches for all
  using (auth.uid() = user_id);

-- Allow unauthenticated searches (user_id = NULL)
create policy "Allow anonymous searches"
  on public.searches for insert
  with check (user_id is null);

create policy "Allow reading anonymous searches"
  on public.searches for select
  using (user_id is null);

-- Index for performance
create index if not exists searches_user_id_idx on public.searches(user_id);
create index if not exists searches_created_at_idx on public.searches(created_at desc);


-- ─── 3. Reports ──────────────────────────────────────────
create table if not exists public.reports (
  id uuid primary key default uuid_generate_v4(),
  search_id uuid references public.searches(id) on delete cascade not null,
  file_path text,
  format text not null check (format in ('pdf', 'json', 'csv')),
  created_at timestamptz default timezone('utc', now()) not null
);

alter table public.reports enable row level security;

create policy "Users can manage reports of their own searches"
  on public.reports for all
  using (
    exists (
      select 1 from public.searches
      where searches.id = reports.search_id
        and (searches.user_id = auth.uid() or searches.user_id is null)
    )
  );


-- ─── 4. Watchlists ───────────────────────────────────────
create table if not exists public.watchlists (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  email text not null,
  is_active boolean default true not null,
  last_checked_at timestamptz,
  created_at timestamptz default timezone('utc', now()) not null,
  unique (user_id, email)
);

alter table public.watchlists enable row level security;

create policy "Users can manage their own watchlist"
  on public.watchlists for all
  using (auth.uid() = user_id);
