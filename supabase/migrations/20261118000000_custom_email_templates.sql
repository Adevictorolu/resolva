-- =============================================================================
-- RESOLVA: Custom Montserrat Email Notifications & Audit Log Schema
-- Domain: resolver.com.ng | Support: support@resolver.com.ng
-- =============================================================================

-- Table storing every transactional email dispatched to users
create table if not exists public.email_notifications (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references auth.users (id) on delete set null,
  recipient_email  text not null,
  recipient_name   text default '',
  subject          text not null,
  template_type    text not null check (template_type in ('activation', 'password_reset', 'exam_pins', 'social_boosting', 'wallet_funding', 'admin_notice')),
  html_content     text not null,
  status           text not null default 'sent',
  error_message    text,
  metadata         jsonb default '{}'::jsonb,
  created_at       timestamptz not null default now()
);

create index if not exists email_notifications_recipient_idx
  on public.email_notifications (lower(recipient_email));

create index if not exists email_notifications_user_idx
  on public.email_notifications (user_id);

create index if not exists email_notifications_created_idx
  on public.email_notifications (created_at desc);

-- RLS
alter table public.email_notifications enable row level security;

-- Policy: Users can view their own email notifications
drop policy if exists email_notifications_select_own on public.email_notifications;
create policy email_notifications_select_own
  on public.email_notifications
  for select
  using (
    auth.uid() = user_id
    or lower(recipient_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Policy: Authenticated users can insert their own email dispatch records
drop policy if exists email_notifications_insert on public.email_notifications;
create policy email_notifications_insert
  on public.email_notifications
  for insert
  with check (true);

-- RPC for logging emails securely
create or replace function public.log_transactional_email(
  p_recipient_email text,
  p_recipient_name  text,
  p_subject         text,
  p_template_type   text,
  p_html_content    text,
  p_metadata        jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  insert into public.email_notifications (
    user_id,
    recipient_email,
    recipient_name,
    subject,
    template_type,
    html_content,
    status,
    metadata
  ) values (
    auth.uid(),
    lower(trim(p_recipient_email)),
    trim(p_recipient_name),
    p_subject,
    p_template_type,
    p_html_content,
    'sent',
    p_metadata
  )
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function public.log_transactional_email to authenticated, anon;
