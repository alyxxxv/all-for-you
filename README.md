# All For You · Wedding Vendor Tracker

Aplikasi web untuk mencatat vendor lamaran dan pernikahan: kategori, harga, kontak, pricelist (JPG/PDF), portofolio, profil IG, dan status deal.

- **Hosting:** Vercel (gratis, paket Hobby)
- **Database, file, dan login:** Supabase (gratis)
- **Akses:** siapa pun yang punya link bisa **melihat** tanpa login. Hanya email yang terdaftar di tabel `editors` yang bisa **menambah, mengubah, dan menghapus**.

```
all-for-you/
├── index.html          ← aplikasinya (HTML + CSS + JS, tanpa build)
├── config.js           ← isi URL dan key Supabase di sini
├── supabase/
│   └── schema.sql      ← tabel, hak akses, bucket file, daftar editor
└── README.md
```

Total waktu setup sekitar 20–30 menit. Lebih nyaman dikerjakan dari laptop.

---

## Langkah 1 — Buat database di Supabase

1. Buka **supabase.com**, klik **Start your project**, lalu daftar atau login (bisa pakai akun GitHub).
2. Klik **New project**.
   - Name: `all-for-you`
   - Database password: buat password dan simpan baik-baik.
   - Region: **Southeast Asia (Singapore)** supaya cepat dari Indonesia.
   - Plan: Free.
3. Tunggu sampai project selesai dibuat (1–2 menit).
4. Buka **SQL Editor** di menu kiri, lalu **New query**.
5. Buka file `supabase/schema.sql`, salin semua isinya, lalu tempel ke SQL Editor.
   - Di bagian paling bawah (**5. Daftarkan editor**), pastikan email kamu benar. Kalau calon juga ikut mengedit, hapus tanda `--` di baris email calon dan isi emailnya.
6. Klik **Run**. Harus muncul "Success. No rows returned".

> File ini aman dijalankan ulang. Kalau nanti mau menambah editor, cukup jalankan:
> `insert into public.editors (email) values ('email@contoh.com');`

## Langkah 2 — Buat akun login untuk editor

1. Buka **Authentication → Users**, lalu **Add user → Create new user**.
2. Isi email (harus sama dengan yang ada di tabel `editors`) dan password.
3. Centang **Auto Confirm User**, lalu **Create user**.
4. Ulangi untuk calon kalau dia ikut mengedit.
5. **Disarankan:** buka **Authentication → Sign In / Providers → Email**, matikan **Allow new users to sign up**, lalu simpan. Jadi tidak ada orang lain yang bisa membuat akun sendiri. Hak edit juga tetap dikunci oleh tabel `editors`, jadi ini lapisan pengaman kedua.

## Langkah 3 — Ambil URL dan key Supabase

1. Buka **Project Settings → API** (di beberapa versi dashboard namanya **API Keys** / **Data API**).
2. Salin:
   - **Project URL**, contohnya `https://abcdefgh.supabase.co`
   - **anon public key** atau **publishable key**
3. Buka `config.js` lalu ganti nilainya:

```js
window.ALL_FOR_YOU_CONFIG = {
  supabaseUrl: "https://abcdefgh.supabase.co",
  supabaseAnonKey: "eyJhbGciOi...",     // atau sb_publishable_...
  bucket: "vendor-files"
};
```

> Key ini memang aman ditaruh di file publik. Yang boleh dilakukan pengunjung diatur oleh aturan Row Level Security di `schema.sql`.
> **Jangan** pernah menaruh `service_role` / `secret` key di file ini.

## Langkah 4 — Upload ke GitHub

1. Buka **github.com**, login, lalu **New repository**.
   - Name: `all-for-you`
   - Boleh **Private**.
   - Klik **Create repository**.
2. Di halaman repo, klik **uploading an existing file** (atau **Add file → Upload files**).
3. Seret semua isi folder ini: `index.html`, `config.js`, `README.md`, dan folder `supabase`.
4. Klik **Commit changes**.

## Langkah 5 — Deploy di Vercel

1. Buka **vercel.com**, lalu **Sign Up** dengan akun GitHub dan pilih paket **Hobby** (gratis).
2. Klik **Add New… → Project**, lalu pilih repo `all-for-you` dan klik **Import**.
   - Kalau repo-nya tidak muncul, klik **Adjust GitHub App Permissions** dan izinkan repo tersebut.
3. Di halaman konfigurasi:
   - **Framework Preset:** Other
   - **Build Command:** kosongkan
   - **Output Directory:** kosongkan
4. Klik **Deploy**. Dalam ±30 detik kamu dapat link seperti `https://all-for-you-xxxx.vercel.app`.
5. (Opsional) Ganti link supaya lebih mudah diingat: **Settings → Domains**, edit domain `.vercel.app`, misalnya jadi `allforyou-aliyya.vercel.app`.

### Mengubah aplikasi nanti

Edit file langsung di GitHub (klik file → ikon pensil → **Commit changes**). Vercel akan deploy ulang otomatis dalam beberapa detik.

---

## Cara pakai

- **Kamu dan calon:** buka link → **Masuk untuk edit** → login dengan email dan password dari Langkah 2.
- **Orang tua, calon mertua, WO:** cukup kirim link-nya. Mereka bisa melihat semua vendor, pricelist, portofolio, dan daftar deal tanpa login.
- **Biar terasa seperti aplikasi di HP:** buka link di Chrome → menu ⋮ → **Add to Home screen**.
- Perubahan dari satu HP langsung muncul di HP lain yang sedang membuka aplikasi.

## Catatan penting

- **Data bisa dilihat siapa pun yang punya link.** Itu termasuk harga dan nomor WA vendor. Halaman ini sudah diatur agar tidak muncul di Google, tapi jangan bagikan link ke tempat umum dan jangan simpan data pribadi sensitif.
- **Batas file:** maksimal 20 MB per file, format JPG, PNG, WebP, atau PDF. Foto besar dari HP otomatis dikecilkan sebelum diunggah.
- **Paket gratis Supabase** bisa menjeda project yang lama tidak dipakai. Kalau aplikasi tiba-tiba tidak bisa memuat data, buka dashboard Supabase dan klik **Restore project**. Datanya tetap aman.
- **Instagram:** feed IG asli tidak bisa ditampilkan di website lain karena diblokir Instagram. Pop-up IG menampilkan data dan foto yang kamu simpan (foto profil, posts, followers, bio, dan foto portofolio). Tombol "Feed lengkap" membuka Instagram aslinya.

## Struktur data (untuk referensi)

Tabel `public.vendors`, satu baris per vendor:

| Kolom | Tipe | Isi |
|---|---|---|
| `category`, `name`, `ig`, `phone` | text | Info dasar |
| `price_min`, `price_max` | bigint | Kisaran harga (Rupiah) |
| `status` | text | `baru` · `nego` · `kandidat` · `deal` · `batal` |
| `ig_name`, `ig_category`, `ig_posts`, `ig_followers`, `ig_bio` | text | Data pop-up IG |
| `deal_for` | text[] | `{lamaran}`, `{nikah}`, atau keduanya |
| `deal_price`, `dp_amount` | bigint | Harga deal dan DP |
| `deal_date` | date | Tanggal deal |
| `files` | jsonb | `[{id, name, type, kind: doc\|portfolio\|avatar, size}]`, `id` = path di bucket `vendor-files` |
| `created_at`, `updated_at` | timestamptz | `updated_at` diperbarui otomatis oleh trigger |

Contoh query rekap di SQL Editor:

```sql
-- total deal per acara
select unnest(deal_for) as acara, count(*) as vendor, sum(deal_price) as total, sum(dp_amount) as dp
from public.vendors where status = 'deal'
group by 1;
```
