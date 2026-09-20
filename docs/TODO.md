# TODO List — POS Laravel Mobile (Flutter)

Checklist pengembangan aplikasi mobile POS. Tandai `[x]` jika selesai, `[/]` jika sedang dikerjakan.

---

## Phase 0: Foundation — Backend API + Flutter Setup

### Backend Laravel (REST API)

- [x] Install & konfigurasi Laravel Sanctum untuk token auth
  - [x] `composer require laravel/sanctum`
  - [x] `php artisan install:api`
  - [x] Tambah `HasApiTokens` trait ke model `User`
  - [x] Konfigurasi `config/sanctum.php`
  - [x] Konfigurasi `config/cors.php` untuk akses mobile
- [x] Buat `routes/api.php` dengan prefix `/api/v1/`
- [x] Buat folder `app/Http/Controllers/Api/V1/`
- [x] **Auth API**
  - [x] `AuthController@login` — POST `/auth/login`
  - [x] `AuthController@logout` — POST `/auth/logout`
  - [x] `AuthController@me` — GET `/auth/me`
- [x] **POS API**
  - [x] `PosApiController@products` — GET `/pos/products`
  - [x] `PosApiController@calculateCart` — POST `/pos/calculate-cart`
  - [x] `PosApiController@checkout` — POST `/pos/checkout`
  - [x] `PosApiController@holdTransaction` — POST `/pos/hold`
  - [x] `PosApiController@getHeldTransactions` — GET `/pos/held-list`
  - [x] `PosApiController@recallHeldTransaction` — POST `/pos/recall/{id}`
  - [x] `PosApiController@voidSale` — POST `/pos/void/{sale}`
- [x] **Shift API**
  - [x] `ShiftApiController@current` — GET `/shifts/current`
  - [x] `ShiftApiController@open` — POST `/shifts/open`
  - [x] `ShiftApiController@close` — POST `/shifts/{id}/close`
  - [x] `ShiftApiController@addExpense` — POST `/shifts/{id}/expenses`
  - [x] `ShiftApiController@deleteExpense` — DELETE `/shifts/{id}/expenses/{eid}`
- [x] **Master Data API**
  - [x] `MasterDataApiController@categories` — GET `/categories`
  - [x] `MasterDataApiController@warehouses` — GET `/warehouses`
  - [x] `MasterDataApiController@customers` — GET/POST `/customers`
  - [x] `MasterDataApiController@customerGroups` — GET `/customer-groups`
  - [x] `MasterDataApiController@units` — GET `/units`
  - [x] `MasterDataApiController@tables` — GET `/tables`
  - [x] `MasterDataApiController@modifiers` — GET `/modifiers`
  - [x] `MasterDataApiController@receiptSettings` — GET `/settings/receipt`
- [x] Tulis API tests (`tests/Feature/Api/`)
  - [x] Test auth login/logout/me (`tests/Feature/Api/AuthApiTest.php`)
  - [x] Test POS checkout flow & calculate cart (`tests/Feature/Api/PosApiTest.php`)
- [x] Jalankan semua tests — PASS

### Flutter Project Setup

- [x] Buat Flutter project: `flutter create --org com.poslaravel --project-name poslaravelmobile .`
- [x] Setup folder structure (`core/`, `features/pos/`, `data/`, `shared/`)
- [x] Tambah dependencies di `pubspec.yaml` (`dio`, `shared_preferences`, `provider`, `google_fonts`, `intl`, `lucide_icons`)
- [x] Setup Dio HTTP client + auth interceptor (`lib/core/api/api_client.dart`)
- [x] Setup App theme (`lib/core/theme/app_theme.dart` & `app_colors.dart` with Plus Jakarta Sans & brand orange palette)
- [x] Setup currency formatter helper (`lib/core/utils/currency_formatter.dart`)
- [x] Setup Pos Workstation Screen initial mockup (`lib/features/pos/screens/pos_workstation_screen.dart`)
- [x] Build & test — `flutter analyze` & `flutter test` PASS (0 errors)

---

## Phase 1: Auth + POS Kasir + Shift + Offline

### Auth

- [x] Halaman Login
  - [x] UI: logo, input email, input password, tombol login
  - [x] Provider: `AuthProvider` — login, logout, check token, server URL switcher
  - [x] Repository: `AuthRepository` — call API + simpan token di SharedPreferences
  - [x] Auto-redirect ke POS jika token valid
- [x] Logout flow (revoke token + clear local storage)
- [x] Auth state & server configuration modal

### POS Kasir — Tablet / Mobile Mode

- [x] `PosWorkstationScreen` responsif (tablet split & mobile)
- [x] **Panel Kiri — Produk**
  - [x] Kategori horizontal chips/tabs
  - [x] Grid produk dengan nama, harga IDR, stok realtime
  - [x] Search bar (live search nama/kode/barcode + clear button)
  - [x] Tap produk → tambah ke keranjang
- [x] **Panel Kanan — Keranjang**
  - [x] Daftar item keranjang (nama, qty stepper +/- dengan subtotal)
  - [x] Tombol kosongkan keranjang
  - [x] Ringkasan: subtotal, grand total
  - [x] Tombol BAYAR & Modal Pembayaran (Tunai, QRIS, Transfer, Debit) + Uang Pas & Pecahan Cepat
  - [x] Dialog struk pembayaran berhasil (dengan Faktur & Kembalian)
- [x] **Header bar & Shift Management**
  - [x] Identitas toko + Kasir
  - [x] Dialog Buka Shift (Modal Awal Kas)
  - [x] Dialog Kas Keluar (Expense) + Live Badge total di header
  - [x] Dialog Tutup Shift (Ekspektasi kas vs Fisik kas aktual + hitung selisih)
  - [x] Hold & Recall transaksi tertunda
  - [ ] Avatar kasir

### POS Kasir — Mobile Mode

- [x] Bottom navigation: Produk, Keranjang, Riwayat, Menu
- [x] Tab Produk: grid 2 kolom + search + kategori
- [x] Tab Keranjang: modern cart bottom sheet + bayar
- [x] Floating badge keranjang (jumlah item + total)

### Pembayaran

- [x] Payment bottom sheet / page
  - [x] Pilih service type: Take Away (default) / Dine In / Delivery
  - [x] Pilih meja (jika Dine In) & counter pengunjung
  - [x] Tombol Hold transaksi langsung di proses pembayaran
  - [x] Pilih metode: Tunai, QRIS, Transfer, Piutang
  - [x] Input nominal uang diterima (Tunai)
  - [x] Smart cash presets (Uang Pas + pembulatan cerdas)
  - [x] Hitung & tampilkan kembalian
  - [x] Input catatan faktur transaksi
  - [x] Tombol Proses Pembayaran / Selesaikan Transaksi
- [x] Receipt / struk digital setelah transaksi selesai
- [x] Reset keranjang setelah checkout

### Shift Kasir

- [ ] Modal buka shift (pilih gudang, input modal awal)
- [ ] Wajib buka shift sebelum bisa transaksi
- [ ] Halaman / bottom sheet Kas Keluar
  - [ ] Input nominal, pilih kategori, catatan
  - [ ] Daftar riwayat kas keluar shift aktif
  - [ ] Hapus kas keluar
- [ ] Badge total kas keluar di header
- [ ] Modal tutup shift
  - [ ] Ringkasan: modal awal, omset tunai, kas keluar, kas sistem
  - [ ] Input kas fisik aktual
  - [ ] Tampilkan selisih (lebih/kurang)
  - [ ] Konfirmasi tutup

### Hold & Recall

- [x] Tombol Hold → simpan keranjang + label referensi (di keranjang & proses pembayaran)
- [x] Halaman/modal daftar held transactions (Recall bar & modal)
- [x] Recall → muat keranjang kembali

### Offline Mode

- [ ] Setup `ConnectivityMonitor` (detect online/offline)
- [ ] Banner status koneksi di header (offline = merah)
- [ ] Sync produk, kategori, customer ke SQLite saat login
- [ ] Transaksi checkout → simpan ke SQLite jika offline
- [ ] Background sync saat kembali online
- [ ] Indicator jumlah transaksi pending sync
- [ ] Manual sync trigger button di settings

---

## Phase 2: Dashboard + Laporan

### Dashboard

- [ ] `DashboardPage` dengan KPI cards
  - [ ] Omset hari ini
  - [ ] Jumlah transaksi
  - [ ] Rata-rata per transaksi
  - [ ] Kas keluar hari ini
- [ ] Chart tren penjualan 7 hari (fl_chart line chart)
- [ ] Top 5 produk terlaris
- [ ] Alert stok menipis (jumlah produk di bawah minimum)

### Laporan

- [ ] Laporan Penjualan (filter tanggal, tabel, total)
- [ ] Penjualan per Produk (ranking, qty terjual, omset)
- [ ] Penjualan per Kategori
- [ ] Penjualan per Customer
- [ ] Rekap Shift Kasir (daftar shift + detail biaya + selisih)
- [ ] Laporan Arus Kas
- [ ] Laba Rugi
- [ ] Share/export PDF via WhatsApp

---

## Phase 3: Master Data CRUD

- [x] **Produk**
  - [x] List produk + search + filter kategori
  - [x] Form tambah/edit produk (nama, kode, barcode, harga beli/jual, kategori, satuan)
  - [ ] Upload foto produk (image_picker)
  - [x] Hapus produk (soft delete)
- [x] **Kategori**
  - [x] List kategori
  - [x] Form tambah/edit kategori
  - [x] Hapus kategori
- [x] **Customer**
  - [x] List customer + search
  - [x] Form tambah/edit customer
  - [x] Grup customer
- [x] **Supplier**
  - [x] List supplier + search
  - [x] Form tambah/edit supplier
- [x] **Satuan (Unit)**
  - [x] List satuan
  - [x] Form tambah/edit satuan
- [x] **Gudang/Cabang**
  - [x] List gudang
  - [x] Set default gudang
- [x] **Meja Makan (FnB)**
  - [x] List meja + status
  - [x] Form tambah/edit meja
- [x] **Diskon & Promo**
  - [x] List diskon
  - [x] Form tambah/edit diskon

---

## Phase 4: Inventory & Stock

- [x] Kartu Stok (FIFO)
  - [x] Riwayat mutasi stok lengkap (+ Masuk / - Keluar) dengan audit saldo & referensi (Penjualan, GRN, Retur, Adjustment, Transfer)
  - [x] Tab Alokasi Batch FIFO aktif (Sisa stok, Valuasi aset HPP, status/peringatan kadaluarsa)
  - [x] Tab Kartu Stok per Produk (Rincian stok per gudang & riwayat spesifik)
  - [x] Filter per gudang, kategori item (Produk/Bahan Baku), tipe mutasi, dan pencarian live
- [ ] Alert Stok Minimum
  - [ ] Daftar produk di bawah minimum stock
- [x] Stock Opname
  - [x] Buat & Edit opname (pilih gudang, tanggal, status draft / in progress)
  - [x] Input qty fisik per produk vs stok sistem & pencatatan alasan selisih
  - [x] Review detail selisih & rekonsiliasi nilai selisih
  - [x] Setujui & Posting penyesuaian stok otomatis ke mutasi inventaris & batch FIFO
- [x] Transfer Stok
  - [x] Buat transfer antar gudang (Pilihan asal & tujuan, input produk, batch FIFO opsional, form konsisten Info & Harga)
  - [x] Dispatch & receive (Kirim transfer memotong stok asal -> Terima transfer memverifikasi qty diterima & menambah stok tujuan)
- [x] Stock Adjustment
  - [x] Buat & Edit adjustment (tambah/kurang stok manual, multi-item, hitung otomatis nilai penyesuaian)
  - [x] Detail adjustment + Setujui & Posting penyesuaian stok (otomatis mutasi stok & batch FIFO) + Hapus draft

---

## Phase 5: Purchasing & Finance

### Purchasing

- [x] Purchase Order
  - [x] List PO + filter status (Semua, Draft, Terkirim, Parsial, Diterima, Dibatalkan)
  - [x] Buat & Edit PO (pilih supplier, gudang tujuan, tanggal pengiriman, tambah item produk dinamis)
  - [x] Detail PO & Update status PO (Kirim PO, Batalkan PO, Terima Barang)
- [x] Penerimaan Barang (Goods Receipt / GRN)
  - [x] List riwayat penerimaan barang
  - [x] Buat penerimaan langsung atau dari PO (otomatis mutasi stok masuk & batch FIFO)
- [x] Retur Pembelian
  - [x] List retur + search + KPI ringkasan + detail sheet + pembatalan retur (kembalikan stok)
  - [x] Buat retur pembelian (langsung pilih produk / tarik referensi GRN, alasan retur, multi item, hitung otomatis nilai retur)

### Finance

- [ ] Akun Kas/Bank
  - [ ] Daftar akun + saldo
- [ ] Arus Kas
  - [ ] List mutasi kas
  - [ ] Catat kas masuk/keluar manual
- [x] Hutang (Payables)
  - [x] Daftar invoice hutang ke supplier + ringkasan total outstanding
  - [x] Bayar hutang supplier via modal kas/bank (catat pembayaran parsial/lunas)
- [ ] Piutang (Receivables)
  - [ ] Daftar piutang dari customer
  - [ ] Terima pembayaran piutang
- [ ] Retur Penjualan
  - [ ] Cari invoice
  - [ ] Buat retur + kembalikan stok

---

## Phase 6: Polish & Production

### Print Bluetooth

- [ ] Pair printer Bluetooth di settings
- [ ] Cetak struk transaksi (format 58mm/80mm)
- [ ] Cetak slip rekap shift

### UX Polish

- [ ] Dark mode toggle
- [ ] Loading skeleton (shimmer) di semua list
- [ ] Empty state illustrations
- [ ] Error state dengan retry button
- [ ] Pull-to-refresh di semua list
- [ ] Haptic feedback pada tombol penting
- [ ] Transition & animasi halus

### Security

- [ ] Biometric lock (fingerprint/face ID)
- [ ] PIN kasir cepat (4-6 digit)
- [ ] Session timeout (auto-lock setelah idle)
- [ ] HTTPS enforcement

### Production Release

- [ ] App icon & splash screen design
- [ ] Build release APK (`flutter build apk --release`)
- [ ] Build App Bundle (`flutter build appbundle`)
- [ ] Test di device fisik (HP + Tablet)
- [ ] Setup Google Play Developer Console
- [ ] Upload ke Play Store (atau distribusi APK internal)
- [ ] Dokumentasi pengguna (cara pakai ringkas)

---

## Notes

- **P0** = Must have (harus ada di rilis pertama)
- **P1** = Should have (penting tapi bisa rilis berikutnya)
- **P2** = Nice to have (bonus, dikerjakan kalau sempat)
- Setiap phase yang selesai → commit & tag version
- Test di device fisik sebelum lanjut ke phase berikutnya
