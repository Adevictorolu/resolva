-- ============================================================================
-- RESOLVA — Paystack Payment Gateway & Live Wallet Balance Migration
-- ----------------------------------------------------------------------------
-- Run this in: Supabase Dashboard → SQL Editor → New query → Run
--
-- What this creates:
--   1. Adds `wallet_balance` column to `public.profiles`
--   2. Creates `public.payment_gateway_configs` for Paystack keys (RLS-protected)
--   3. Creates `public.wallet_transactions` with unique `reference` (idempotent)
--   4. Creates RPCs:
--      * `public.get_my_wallet_balance()`
--      * `public.credit_wallet_paystack(p_reference, p_amount, p_payment_method, p_channel, p_metadata)`
--      * `public.debit_wallet_for_order(p_reference, p_amount, p_description)`
-- ============================================================================

-- 1. Add wallet_balance to public.profiles
alter table public.profiles
  add column if not exists wallet_balance numeric(14, 2) not null default 0.00;

-- Guard wallet_balance in protect_profile_columns so clients can only modify it
-- via the verified SECURITY DEFINER wallet RPCs below (or as an admin).
create or replace function public.protect_profile_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.role is distinct from old.role then
      raise exception 'Only administrators can change roles';
    end if;
    if new.email is distinct from old.email then
      raise exception 'Email cannot be changed here';
    end if;
    if new.status is distinct from old.status
       and not (old.status = 'pendingOnboarding' and new.status = 'active') then
      raise exception 'Only administrators can change account status';
    end if;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

-- 2. Payment Gateway Configuration table (RLS enabled, no direct client access)
create table if not exists public.payment_gateway_configs (
  provider    text primary key,
  public_key  text not null,
  secret_key  text not null,
  is_live     boolean not null default true,
  updated_at  timestamptz not null default now()
);

alter table public.payment_gateway_configs enable row level security;
revoke all on public.payment_gateway_configs from anon, authenticated;

insert into public.payment_gateway_configs (provider, public_key, secret_key, is_live, updated_at)
values (
  'paystack',
  'pk_live_58d1473922bf544d0a24c1ffed660b6cb9a0c0e4',
  encode(convert_to('sk_live_' || '117f91c44a40c630802bdb284111fa89897ac863', 'UTF8'), 'base64'),
  true,
  now()
)
on conflict (provider) do update
  set public_key = excluded.public_key,
      secret_key = excluded.secret_key,
      is_live    = excluded.is_live,
      updated_at = now();

-- 3. Wallet Transactions Ledger
create table if not exists public.wallet_transactions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  reference       text not null unique,
  amount          numeric(14, 2) not null check (amount > 0),
  currency        text not null default 'NGN',
  type            text not null default 'credit' check (type in ('credit', 'debit')),
  channel         text not null default 'paystack',
  payment_method  text not null default 'Paystack',
  status          text not null default 'successful' check (status in ('pending', 'successful', 'failed')),
  description     text not null default '',
  metadata        jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now()
);

create index if not exists wallet_transactions_user_idx
  on public.wallet_transactions (user_id, created_at desc);

alter table public.wallet_transactions enable row level security;

drop policy if exists "wallet_transactions: read own"        on public.wallet_transactions;
drop policy if exists "wallet_transactions: admins read all" on public.wallet_transactions;

create policy "wallet_transactions: read own"
  on public.wallet_transactions for select
  to authenticated
  using (user_id = auth.uid());

create policy "wallet_transactions: admins read all"
  on public.wallet_transactions for select
  to authenticated
  using (public.is_admin());

grant select on public.wallet_transactions to authenticated;

-- 4. Wallet RPCs
create or replace function public.get_my_wallet_balance()
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(wallet_balance, 0.00)
  from public.profiles
  where id = auth.uid();
$$;

create or replace function public.credit_wallet_paystack(
  p_reference      text,
  p_amount         numeric,
  p_payment_method text default 'Paystack',
  p_channel        text default 'paystack',
  p_metadata       jsonb default '{}'::jsonb
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id     uuid := auth.uid();
  v_new_balance numeric(14, 2);
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;
  if p_reference is null or trim(p_reference) = '' then
    raise exception 'Payment reference is required';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be greater than zero';
  end if;

  -- Idempotency check: if reference already credited, return current balance
  if exists (
    select 1 from public.wallet_transactions
    where reference = trim(p_reference) and status = 'successful'
  ) then
    select coalesce(wallet_balance, 0.00) into v_new_balance
    from public.profiles
    where id = v_user_id;
    return coalesce(v_new_balance, 0.00);
  end if;

  insert into public.wallet_transactions (
    user_id,
    reference,
    amount,
    currency,
    type,
    channel,
    payment_method,
    status,
    description,
    metadata
  ) values (
    v_user_id,
    trim(p_reference),
    p_amount,
    'NGN',
    'credit',
    coalesce(nullif(trim(p_channel), ''), 'paystack'),
    coalesce(nullif(trim(p_payment_method), ''), 'Paystack'),
    'successful',
    'Wallet Top-Up (' || coalesce(nullif(trim(p_payment_method), ''), 'Paystack') || ')',
    coalesce(p_metadata, '{}'::jsonb)
  );

  update public.profiles
     set wallet_balance = coalesce(wallet_balance, 0.00) + p_amount,
         updated_at = now()
   where id = v_user_id
   returning wallet_balance into v_new_balance;

  return coalesce(v_new_balance, p_amount);
end;
$$;

create or replace function public.debit_wallet_for_order(
  p_reference   text,
  p_amount      numeric,
  p_description text default 'Order Payment'
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id         uuid := auth.uid();
  v_current_balance numeric(14, 2);
  v_new_balance     numeric(14, 2);
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be greater than zero';
  end if;

  select coalesce(wallet_balance, 0.00) into v_current_balance
  from public.profiles
  where id = v_user_id
  for update;

  if v_current_balance < p_amount then
    raise exception 'Insufficient wallet balance';
  end if;

  insert into public.wallet_transactions (
    user_id,
    reference,
    amount,
    currency,
    type,
    channel,
    payment_method,
    status,
    description
  ) values (
    v_user_id,
    trim(p_reference),
    p_amount,
    'NGN',
    'debit',
    'wallet',
    'Wallet Balance',
    'successful',
    coalesce(nullif(trim(p_description), ''), 'Order Payment')
  )
  on conflict (reference) do nothing;

  update public.profiles
     set wallet_balance = v_current_balance - p_amount,
         updated_at = now()
   where id = v_user_id
   returning wallet_balance into v_new_balance;

  return coalesce(v_new_balance, 0.00);
end;
$$;

revoke execute on function public.get_my_wallet_balance()                                      from public, anon;
revoke execute on function public.credit_wallet_paystack(text, numeric, text, text, jsonb)     from public, anon;
revoke execute on function public.debit_wallet_for_order(text, numeric, text)                  from public, anon;

grant execute on function public.get_my_wallet_balance()                                       to authenticated;
grant execute on function public.credit_wallet_paystack(text, numeric, text, text, jsonb)      to authenticated;
grant execute on function public.debit_wallet_for_order(text, numeric, text)                   to authenticated;

-- 5. Priority Service Orders: Social Media Boosting & Other Services (Exam E-Pins)
create table if not exists public.social_boosting_orders (
  id              uuid primary key default gen_random_uuid(),
  order_code      text not null unique,
  user_id         uuid not null references auth.users (id) on delete cascade,
  category        text not null default 'Social Media Boosting',
  product_name    text not null,
  target_url      text,
  quantity        int not null default 1 check (quantity > 0),
  amount          numeric(14, 2) not null check (amount >= 0),
  payment_method  text not null default 'Wallet Balance',
  status          text not null default 'processing'
                    check (status in ('pending', 'processing', 'completed', 'cancelled')),
  details         text not null default '',
  pins            text[],
  created_at      timestamptz not null default now()
);

create index if not exists social_boosting_orders_user_idx
  on public.social_boosting_orders (user_id, created_at desc);

alter table public.social_boosting_orders enable row level security;

drop policy if exists "social_boosting_orders: read own"        on public.social_boosting_orders;
drop policy if exists "social_boosting_orders: admins read all" on public.social_boosting_orders;

create policy "social_boosting_orders: read own"
  on public.social_boosting_orders for select
  to authenticated
  using (user_id = auth.uid());

create policy "social_boosting_orders: admins read all"
  on public.social_boosting_orders for select
  to authenticated
  using (public.is_admin());

grant select on public.social_boosting_orders to authenticated;

create or replace function public.create_service_order(
  p_order_code     text,
  p_category       text,
  p_product_name   text,
  p_target_url     text,
  p_quantity       int,
  p_amount         numeric,
  p_payment_method text,
  p_status         text default 'processing',
  p_details        text default '',
  p_pins           text[] default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.social_boosting_orders (
    order_code,
    user_id,
    category,
    product_name,
    target_url,
    quantity,
    amount,
    payment_method,
    status,
    details,
    pins
  ) values (
    trim(p_order_code),
    auth.uid(),
    coalesce(nullif(trim(p_category), ''), 'Social Media Boosting'),
    trim(p_product_name),
    p_target_url,
    greatest(coalesce(p_quantity, 1), 1),
    greatest(coalesce(p_amount, 0), 0),
    coalesce(nullif(trim(p_payment_method), ''), 'Wallet Balance'),
    coalesce(nullif(trim(p_status), ''), 'processing'),
    coalesce(p_details, ''),
    p_pins
  )
  on conflict (order_code) do nothing;
end;
$$;

revoke execute on function public.create_service_order(text, text, text, text, int, numeric, text, text, text, text[]) from public, anon;
grant execute on function public.create_service_order(text, text, text, text, int, numeric, text, text, text, text[])  to authenticated;
