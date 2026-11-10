-- ============================================================================
-- RESOLVA — Authentication, profiles, roles & security PIN
-- ----------------------------------------------------------------------------
-- Run this once in: Supabase Dashboard → SQL Editor → New query → Run
-- (or `supabase db push` if you use the Supabase CLI).
--
-- What it creates:
--   * public.admin_emails   – emails that are automatically granted the admin role
--   * public.profiles       – one row per auth user (name, phone, role, status, policies)
--   * public.user_security  – hashed 6-digit security PIN (never readable by clients)
--   * Trigger that creates a profile whenever someone signs up (email or Google)
--   * Row Level Security so users only see/edit their own profile, admins see all
--   * RPCs: set_security_pin, verify_security_pin, has_security_pin,
--           reset_security_pin, record_login, admin_set_user_status,
--           admin_set_user_role, admin_add_admin_email, admin_delete_user
-- ============================================================================

create extension if not exists pgcrypto with schema extensions;

-- ----------------------------------------------------------------------------
-- 1. Admin allow-list
-- ----------------------------------------------------------------------------
create table if not exists public.admin_emails (
  email      text primary key,
  created_at timestamptz not null default now()
);

alter table public.admin_emails enable row level security;
-- No direct policies: managed via SQL editor or admin RPCs below.

insert into public.admin_emails (email) values
  ('ademolavictor869@gmail.com')
on conflict (email) do nothing;

-- ----------------------------------------------------------------------------
-- 2. Profiles
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id                       uuid primary key references auth.users (id) on delete cascade,
  email                    text not null,
  full_name                text not null default '',
  phone                    text not null default '',
  avatar_url               text,
  role                     text not null default 'customer'
                             check (role in ('customer', 'admin')),
  status                   text not null default 'pendingOnboarding'
                             check (status in ('active', 'suspended', 'pendingOnboarding')),
  accepted_terms_version   text not null default '',
  accepted_privacy_version text not null default '',
  last_login_at            timestamptz,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

create index if not exists profiles_email_idx on public.profiles (lower(email));

-- ----------------------------------------------------------------------------
-- 3. Security PIN storage (bcrypt hash, no client access at all)
-- ----------------------------------------------------------------------------
create table if not exists public.user_security (
  user_id         uuid primary key references auth.users (id) on delete cascade,
  pin_hash        text not null,
  failed_attempts int  not null default 0,
  updated_at      timestamptz not null default now()
);

alter table public.user_security enable row level security;
-- No policies: accessible only through the SECURITY DEFINER functions below.

-- ----------------------------------------------------------------------------
-- 4. Helpers
-- ----------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and status <> 'suspended'
  );
$$;

-- ----------------------------------------------------------------------------
-- 5. Create a profile automatically for every new auth user
--    Works for email/password sign-up (metadata: full_name, phone) and
--    Google OAuth (metadata: full_name / name, avatar_url / picture).
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  insert into public.profiles (id, email, full_name, phone, avatar_url, role)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(nullif(meta->>'full_name', ''), nullif(meta->>'name', ''),
             split_part(coalesce(new.email, ''), '@', 1)),
    coalesce(meta->>'phone', ''),
    coalesce(meta->>'avatar_url', meta->>'picture'),
    case
      when exists (select 1 from public.admin_emails a
                   where lower(a.email) = lower(new.email))
      then 'admin' else 'customer'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Back-fill profiles for any users that existed before this migration.
insert into public.profiles (id, email, full_name, role)
select u.id,
       coalesce(u.email, ''),
       coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name',
                split_part(coalesce(u.email, ''), '@', 1)),
       case when exists (select 1 from public.admin_emails a
                         where lower(a.email) = lower(u.email))
            then 'admin' else 'customer' end
from auth.users u
on conflict (id) do nothing;

-- Promote existing users whose email is on the admin allow-list.
update public.profiles p
set role = 'admin'
from public.admin_emails a
where lower(p.email) = lower(a.email) and p.role <> 'admin';

-- ----------------------------------------------------------------------------
-- 6. Guard privileged columns: only admins (or the SQL editor) can change
--    role / status / email. Keeps updated_at fresh.
-- ----------------------------------------------------------------------------
create or replace function public.protect_profile_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- auth.uid() is null when running from the SQL editor / service role.
  if auth.uid() is not null and not public.is_admin() then
    if new.role is distinct from old.role then
      raise exception 'Only administrators can change roles';
    end if;
    if new.email is distinct from old.email then
      raise exception 'Email cannot be changed here';
    end if;
    -- Customers may only move themselves from pendingOnboarding -> active.
    if new.status is distinct from old.status
       and not (old.status = 'pendingOnboarding' and new.status = 'active') then
      raise exception 'Only administrators can change account status';
    end if;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_protect_columns on public.profiles;
create trigger profiles_protect_columns
  before update on public.profiles
  for each row execute function public.protect_profile_columns();

-- ----------------------------------------------------------------------------
-- 7. Row Level Security
-- ----------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists "profiles: read own"        on public.profiles;
drop policy if exists "profiles: admins read all" on public.profiles;
drop policy if exists "profiles: update own"      on public.profiles;
drop policy if exists "profiles: admins update"   on public.profiles;

create policy "profiles: read own"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

create policy "profiles: admins read all"
  on public.profiles for select
  to authenticated
  using (public.is_admin());

create policy "profiles: update own"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "profiles: admins update"
  on public.profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Inserts are done by the trigger only; deletes via admin_delete_user().

-- ----------------------------------------------------------------------------
-- 8. Security PIN RPCs
-- ----------------------------------------------------------------------------
create or replace function public.has_security_pin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.user_security where user_id = auth.uid());
$$;

create or replace function public.set_security_pin(pin text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  if pin !~ '^[0-9]{6}$' then
    raise exception 'PIN must be exactly 6 digits';
  end if;

  insert into public.user_security (user_id, pin_hash, failed_attempts, updated_at)
  values (auth.uid(), crypt(pin, gen_salt('bf')), 0, now())
  on conflict (user_id) do update
    set pin_hash = excluded.pin_hash, failed_attempts = 0, updated_at = now();

  -- Finishing PIN setup completes onboarding.
  update public.profiles
     set status = 'active'
   where id = auth.uid() and status = 'pendingOnboarding';
end;
$$;

create or replace function public.verify_security_pin(pin text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  stored text;
  ok     boolean;
begin
  if auth.uid() is null then
    return false;
  end if;
  select pin_hash into stored from public.user_security where user_id = auth.uid();
  if stored is null then
    return false;
  end if;
  ok := stored = crypt(pin, stored);
  update public.user_security
     set failed_attempts = case when ok then 0 else failed_attempts + 1 end
   where user_id = auth.uid();
  return ok;
end;
$$;

-- Used by the "Forgot PIN" flow after the user has re-authenticated.
create or replace function public.reset_security_pin()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.user_security where user_id = auth.uid();
$$;

-- ----------------------------------------------------------------------------
-- 9. Session / admin RPCs
-- ----------------------------------------------------------------------------
create or replace function public.record_login()
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles set last_login_at = now() where id = auth.uid();
$$;

create or replace function public.admin_set_user_status(target uuid, new_status text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Administrators only';
  end if;
  if target = auth.uid() then
    raise exception 'You cannot change your own status';
  end if;
  update public.profiles set status = new_status where id = target;
end;
$$;

create or replace function public.admin_set_user_role(target uuid, new_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_email text;
begin
  if not public.is_admin() then
    raise exception 'Administrators only';
  end if;
  if new_role not in ('customer', 'admin') then
    raise exception 'Invalid role';
  end if;
  if target = auth.uid() and new_role <> 'admin' then
    raise exception 'You cannot remove your own administrator role';
  end if;

  update public.profiles
     set role = new_role
   where id = target
   returning email into target_email;

  if target_email is not null then
    if new_role = 'admin' then
      insert into public.admin_emails (email)
      values (lower(trim(target_email)))
      on conflict (email) do nothing;
    else
      delete from public.admin_emails
       where lower(email) = lower(trim(target_email));
    end if;
  end if;
end;
$$;

create or replace function public.admin_add_admin_email(admin_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized text := lower(trim(admin_email));
begin
  if not public.is_admin() then
    raise exception 'Administrators only';
  end if;
  if normalized = '' or position('@' in normalized) = 0 then
    raise exception 'Invalid email address';
  end if;

  insert into public.admin_emails (email)
  values (normalized)
  on conflict (email) do nothing;

  update public.profiles
     set role = 'admin'
   where lower(email) = normalized;
end;
$$;

create or replace function public.admin_delete_user(target uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_admin() then
    raise exception 'Administrators only';
  end if;
  if target = auth.uid() then
    raise exception 'You cannot delete your own account';
  end if;
  delete from auth.users where id = target;  -- cascades to profiles & user_security
end;
$$;

-- ----------------------------------------------------------------------------
-- 10. Grants
-- ----------------------------------------------------------------------------
revoke all on public.user_security from anon, authenticated;
revoke all on public.admin_emails  from anon, authenticated;

grant select, update on public.profiles to authenticated;

revoke execute on function public.is_admin()                        from public, anon;
revoke execute on function public.has_security_pin()                from public, anon;
revoke execute on function public.set_security_pin(text)            from public, anon;
revoke execute on function public.verify_security_pin(text)         from public, anon;
revoke execute on function public.reset_security_pin()              from public, anon;
revoke execute on function public.record_login()                    from public, anon;
revoke execute on function public.admin_set_user_status(uuid, text) from public, anon;
revoke execute on function public.admin_set_user_role(uuid, text)   from public, anon;
revoke execute on function public.admin_add_admin_email(text)       from public, anon;
revoke execute on function public.admin_delete_user(uuid)           from public, anon;

grant execute on function public.is_admin()                        to authenticated;
grant execute on function public.has_security_pin()                to authenticated;
grant execute on function public.set_security_pin(text)            to authenticated;
grant execute on function public.verify_security_pin(text)         to authenticated;
grant execute on function public.reset_security_pin()              to authenticated;
grant execute on function public.record_login()                    to authenticated;
grant execute on function public.admin_set_user_status(uuid, text) to authenticated;
grant execute on function public.admin_set_user_role(uuid, text)   to authenticated;
grant execute on function public.admin_add_admin_email(text)       to authenticated;
grant execute on function public.admin_delete_user(uuid)           to authenticated;
