-- Jalankan sekali di Supabase: SQL Editor > New query > Run
create table if not exists public.hitunglot_state (
  code text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.hitunglot_state enable row level security;
-- Tidak ada policy: tabel tidak bisa dibaca/ditulis langsung. Akses hanya lewat 2 fungsi di bawah.

create or replace function public.hitunglot_get_state(p_code text)
returns jsonb language sql security definer set search_path = public as $$
  select data from public.hitunglot_state where code = p_code
$$;

create or replace function public.hitunglot_set_state(p_code text, p_data jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if length(p_code) < 32 then raise exception 'kode tidak valid'; end if;
  if pg_column_size(p_data) > 500000 then raise exception 'data terlalu besar'; end if;
  insert into public.hitunglot_state(code, data, updated_at)
  values (p_code, p_data, now())
  on conflict (code) do update set data = excluded.data, updated_at = now();
end $$;

revoke all on function public.hitunglot_get_state(text) from public;
revoke all on function public.hitunglot_set_state(text, jsonb) from public;
grant execute on function public.hitunglot_get_state(text) to anon;
grant execute on function public.hitunglot_set_state(text, jsonb) to anon;
