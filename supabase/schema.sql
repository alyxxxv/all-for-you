-- =====================================================================
-- All For You · Wedding Vendor Tracker
-- Jalankan sekali di Supabase: Dashboard → SQL Editor → New query → Run
-- =====================================================================

-- ---------- 1. Daftar editor (yang boleh tambah/ubah/hapus) ----------
create table if not exists public.editors (
  email      text primary key,
  added_at   timestamptz not null default now()
);
alter table public.editors enable row level security;

-- Seseorang hanya bisa melihat apakah email-nya sendiri terdaftar
drop policy if exists "editors read own row" on public.editors;
create policy "editors read own row" on public.editors
  for select to authenticated
  using (lower(email) = lower(auth.jwt() ->> 'email'));

-- Cek apakah user yang sedang login adalah editor
create or replace function public.is_editor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.editors
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_editor() from public;
grant execute on function public.is_editor() to anon, authenticated;

-- ---------- 2. Tabel vendor ----------
create table if not exists public.vendors (
  id            uuid primary key default gen_random_uuid(),
  category      text not null default 'Lainnya',
  name          text not null,
  ig            text,
  phone         text,
  price_min     bigint check (price_min is null or price_min >= 0),
  price_max     bigint check (price_max is null or price_max >= 0),
  price_note    text,
  location      text,
  contact_name  text,
  notes         text,
  status        text not null default 'baru'
                check (status in ('baru','nego','kandidat','deal','batal')),
  -- profil IG untuk pop-up
  ig_name       text,
  ig_category   text,
  ig_posts      text,
  ig_followers  text,
  ig_bio        text,
  -- deal
  deal_for      text[] not null default '{}',   -- {'lamaran','nikah'}
  deal_price    bigint,
  dp_amount     bigint,
  deal_date     date,
  deal_note     text,
  -- file di Storage: [{id: path, name, type, kind: doc|portfolio|avatar, size}]
  files         jsonb not null default '[]'::jsonb,
  is_example    boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists vendors_category_idx on public.vendors (category);
create index if not exists vendors_status_idx   on public.vendors (status);

-- updated_at otomatis
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists vendors_touch on public.vendors;
create trigger vendors_touch
  before update on public.vendors
  for each row execute function public.touch_updated_at();

-- ---------- 3. Hak akses (Row Level Security) ----------
alter table public.vendors enable row level security;

drop policy if exists "anyone can read vendors" on public.vendors;
create policy "anyone can read vendors" on public.vendors
  for select to anon, authenticated using (true);

drop policy if exists "editors insert vendors" on public.vendors;
create policy "editors insert vendors" on public.vendors
  for insert to authenticated with check (public.is_editor());

drop policy if exists "editors update vendors" on public.vendors;
create policy "editors update vendors" on public.vendors
  for update to authenticated using (public.is_editor()) with check (public.is_editor());

drop policy if exists "editors delete vendors" on public.vendors;
create policy "editors delete vendors" on public.vendors
  for delete to authenticated using (public.is_editor());

grant select on public.vendors to anon, authenticated;
grant insert, update, delete on public.vendors to authenticated;

-- Update otomatis di layar keluarga ketika ada perubahan
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'vendors'
  ) then
    alter publication supabase_realtime add table public.vendors;
  end if;
end $$;

-- ---------- 4. Penyimpanan file (pricelist, portofolio, foto profil) ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('vendor-files', 'vendor-files', true, 20971520,
        array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "editors upload vendor files" on storage.objects;
create policy "editors upload vendor files" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'vendor-files' and public.is_editor());

drop policy if exists "editors delete vendor files" on storage.objects;
create policy "editors delete vendor files" on storage.objects
  for delete to authenticated
  using (bucket_id = 'vendor-files' and public.is_editor());

-- ---------- 5. Daftarkan editor ----------
-- Ganti dengan email kamu (dan calon, kalau ikut mengedit), lalu jalankan.
insert into public.editors (email) values
  ('aliyya.amru@gmail.com')
  -- , ('email-calon@gmail.com')
on conflict do nothing;
