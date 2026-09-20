# Product Requirements Document (PRD)
## POS Laravel Mobile — Aplikasi Kasir & Manajemen Toko Android

**Versi**: 1.0.0
**Tanggal**: 17 September 2026
**Author**: Adam Adifa
**Platform**: Android (Tablet & Mobile)
**Framework**: Flutter + Laravel REST API (Sanctum)

---

## 1. Ringkasan Produk

Aplikasi mobile Android berbasis Flutter yang menjadi **companion app** dari sistem POS Laravel (web). Mendukung dua mode tampilan:

- **Tablet Mode (≥768dp)**: Layar kasir split-view penuh, optimal untuk tablet 10" yang diletakkan di meja kasir.
- **Mobile Mode (<768dp)**: Antarmuka ringkas untuk owner/manager memantau bisnis, serta kasir darurat dari HP.

Aplikasi ini terhubung ke backend Laravel yang sama melalui **REST API v1** dengan autentikasi **Laravel Sanctum (Bearer Token)**, dan mendukung **Offline Mode** untuk transaksi POS saat koneksi internet terputus.

---

## 2. Tujuan & Latar Belakang

### 2.1 Masalah yang Diselesaikan
| Masalah | Solusi Mobile |
|---------|---------------|
| Web POS harus buka browser, kurang responsif di tablet | App native Flutter, performa tinggi, touch-optimized |
| Kalau WiFi mati, kasir tidak bisa transaksi | Offline mode — transaksi tersimpan lokal, sync saat online |
| Owner harus buka laptop untuk cek omset | Cek dashboard & laporan langsung dari HP kapan saja |
| Cetak struk harus pakai PC + printer USB | Support printer Bluetooth thermal langsung dari tablet |
| Input stok opname harus di depan komputer | Bisa scan barcode & input stok langsung pakai HP di gudang |

### 2.2 Target Pengguna
| Persona | Kebutuhan Utama | Mode |
|---------|-----------------|------|
| **Kasir** | Transaksi cepat, input pembayaran, hold/recall, kas keluar | Tablet |
| **Owner/Manager** | Pantau omset, laporan, kelola stok & produk | Mobile |
| **Staff Gudang** | Stock opname, cek kartu stok, input adjustment | Mobile |

---

## 3. Arsitektur Sistem

```
┌─────────────────────────────────────────────────┐
│              Flutter App (Android)              │
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ UI Layer │→ │ BLoC     │→ │ Repository   │  │
│  │ (Pages,  │  │ (State   │  │ (API + Local │  │
│  │  Widgets)│  │  Mgmt)   │  │  DB switch)  │  │
│  └──────────┘  └──────────┘  └──────┬───────┘  │
│                                     │           │
│                    ┌────────────────┼────────┐  │
│                    ▼                ▼        │  │
│              ┌──────────┐    ┌───────────┐   │  │
│              │ Dio HTTP │    │ Drift     │   │  │
│              │ Client   │    │ (SQLite)  │   │  │
│              └─────┬────┘    └───────────┘   │  │
│                    │              ▲           │  │
│                    │         Sync Engine      │  │
│                    │              │           │  │
└────────────────────┼──────────────┼───────────┘
                     │              │
                     ▼              │
          ┌─────────────────────┐   │
          │  Laravel Backend    │   │
          │  REST API v1        │◄──┘
          │  (Sanctum Auth)     │
          │  ┌───────────────┐  │
          │  │ MySQL Database│  │
          │  └───────────────┘  │
          └─────────────────────┘
```

### 3.1 Tech Stack

| Layer | Teknologi | Keterangan |
|-------|-----------|------------|
| **Frontend** | Flutter 3.x (Dart) | Cross-platform, tapi fokus Android dulu |
| **State Management** | flutter_bloc (Cubit/BLoC) | Predictable, testable |
| **HTTP Client** | Dio | Interceptors, retry, timeout |
| **Local Database** | Drift (SQLite) | Offline storage, type-safe |
| **Auth Token** | flutter_secure_storage | Simpan Sanctum token terenkripsi |
| **Routing** | go_router | Declarative, deep linking |
| **Backend API** | Laravel + Sanctum | Token-based REST API |
| **Data Models** | freezed + json_serializable | Immutable, auto-generated |

### 3.2 Package Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.x
  dio: ^5.x
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  flutter_secure_storage: ^9.x
  go_router: ^14.x
  connectivity_plus: ^6.x
  intl: ^0.19.x
  google_fonts: ^6.x
  fl_chart: ^0.x
  freezed_annotation: ^2.x
  json_annotation: ^4.x
  shimmer: ^3.x
  cached_network_image: ^3.x
  image_picker: ^1.x
  permission_handler: ^11.x
  path_provider: ^2.x

dev_dependencies:
  freezed: ^2.x
  json_serializable: ^6.x
  build_runner: ^2.x
  drift_dev: ^2.x
  bloc_test: ^9.x
  mocktail: ^1.x
```

---

## 4. Fitur & Modul

### 4.1 Modul Auth & Session

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| AUTH-01 | Login (email + password → Bearer token) | P0 | ❌ |
| AUTH-02 | Auto-login (token tersimpan) | P0 | ✅ |
| AUTH-03 | Logout (revoke token) | P0 | ❌ |
| AUTH-04 | Profil user + role/permissions | P1 | ✅ (cache) |
| AUTH-05 | Biometric lock (fingerprint/face) | P2 | ✅ |
| AUTH-06 | PIN kasir cepat (4-6 digit) | P2 | ✅ |

---

### 4.2 Modul POS Kasir (CORE)

| ID | Fitur | Prioritas | Offline | Keterangan |
|----|-------|-----------|---------|------------|
| POS-01 | Grid produk dengan gambar, harga, stok | P0 | ✅ | Cache produk ke SQLite |
| POS-02 | Pencarian produk (nama/kode/barcode) | P0 | ✅ | Search lokal saat offline |
| POS-03 | Filter kategori (horizontal chips) | P0 | ✅ | |
| POS-04 | Scan barcode via kamera | P1 | ✅ | Package: mobile_scanner |
| POS-05 | Tambah item ke keranjang | P0 | ✅ | |
| POS-06 | Edit qty, hapus item, notes per item | P0 | ✅ | |
| POS-07 | Modifiers (tambahan topping, dll) | P1 | ✅ | |
| POS-08 | Hitung subtotal, diskon, grand total | P0 | ✅ | Kalkulasi lokal saat offline |
| POS-09 | Pilih customer | P0 | ✅ | Cache customer lokal |
| POS-10 | Service Type: Take Away (default) / Dine In | P0 | ✅ | |
| POS-11 | Pilih meja (Dine In) | P1 | ✅ | |
| POS-12 | Smart Cash Presets (rekomendasi uang) | P0 | ✅ | Lokal, sama seperti web |
| POS-13 | Pembayaran Tunai + hitung kembalian | P0 | ✅ | |
| POS-14 | Pembayaran QRIS/Transfer/Piutang | P0 | ✅ | |
| POS-15 | Hold keranjang + label referensi | P0 | ✅ | Simpan ke SQLite |
| POS-16 | Recall held cart | P0 | ✅ | |
| POS-17 | Void transaksi (dengan alasan) | P1 | ❌ | Harus online |
| POS-18 | Struk digital (tampilan receipt) | P0 | ✅ | |
| POS-19 | Cetak struk Bluetooth thermal | P2 | ✅ | 58mm/80mm |

#### 4.2.1 Layout Tablet Mode (≥768dp, Landscape)

```
┌──────────────────────────────────────────────────────────────┐
│ [Logo] Toko Saya  [🏬 Cabang Utama]    [💸Kas Keluar F4]  │
│                                         [🔒Tutup Shift]    │
│                                         [👤 Adam]          │
├─────────────────────────────────┬────────────────────────────┤
│ [🔍 Cari produk / scan...]     │  🛒 KERANJANG              │
│                                 │                            │
│ [Semua] [Makanan] [Minuman]    │  ┌────────────────────────┐ │
│ [Snack] [Rokok]                │  │ Nasi Goreng    x2      │ │
│                                 │  │ Rp 30.000              │ │
│ ┌────────┐ ┌────────┐ ┌──────┐│  ├────────────────────────┤ │
│ │ Produk │ │ Produk │ │ ...  ││  │ Es Teh Manis   x1      │ │
│ │ [img]  │ │ [img]  │ │      ││  │ Rp 5.000               │ │
│ │ Rp 15k │ │ Rp 20k │ │      ││  └────────────────────────┘ │
│ └────────┘ └────────┘ └──────┘│                              │
│ ┌────────┐ ┌────────┐ ┌──────┐│  Subtotal      Rp 35.000    │
│ │ Produk │ │ Produk │ │ ...  ││  Diskon        - Rp 0       │
│ │        │ │        │ │      ││  ─────────────────────────── │
│ └────────┘ └────────┘ └──────┘│  GRAND TOTAL   Rp 35.000    │
│                                 │                            │
│                                 │  [💰 BAYAR — F12]         │
├─────────────────────────────────┴────────────────────────────┤
│  📊 Shift Aktif: 08:00 • Omset: Rp 1.250.000 • 23 Trx     │
└──────────────────────────────────────────────────────────────┘
```

#### 4.2.2 Layout Mobile Mode (<768dp, Portrait)

```
┌─────────────────────┐
│ [☰] Toko Saya  [👤] │
├─────────────────────┤
│ [🔍 Cari produk...] │
│                     │
│ [Semua][Makanan]▶   │
│                     │
│ ┌────┐ ┌────┐      │
│ │Prod│ │Prod│      │
│ │15k │ │20k │      │
│ └────┘ └────┘      │
│ ┌────┐ ┌────┐      │
│ │Prod│ │Prod│      │
│ │25k │ │10k │      │
│ └────┘ └────┘      │
│                     │
│        ┌───────────┐│
│        │🛒 3 Item  ││
│        │Rp 35.000  ││
│        │[BAYAR →]  ││
│        └───────────┘│
├─────────────────────┤
│ [🏠][🛒][📋][☰]    │
│ Home Cart Riwayat   │
└─────────────────────┘
```

---

### 4.3 Modul Shift Kasir

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| SHIFT-01 | Buka shift (pilih gudang, modal awal) | P0 | ❌ |
| SHIFT-02 | Cek shift aktif saat launch app | P0 | ✅ (cache) |
| SHIFT-03 | Catat kas keluar / biaya (kategori, nominal, catatan) | P0 | ✅ |
| SHIFT-04 | Hapus kas keluar (jika salah input) | P0 | ✅ |
| SHIFT-05 | Badge total kas keluar pada header | P0 | ✅ |
| SHIFT-06 | Tutup shift + input kas fisik aktual | P0 | ❌ |
| SHIFT-07 | Ringkasan shift (modal, omset, biaya, selisih) | P0 | ❌ |
| SHIFT-08 | Cetak slip rekap shift (Bluetooth) | P2 | ✅ |

---

### 4.4 Modul Dashboard

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| DASH-01 | KPI card: Omset Hari Ini, Jumlah Transaksi, Rata-rata | P0 | ❌ |
| DASH-02 | Chart tren penjualan 7 hari terakhir (line chart) | P1 | ❌ |
| DASH-03 | Top 5 produk terlaris hari ini | P1 | ❌ |
| DASH-04 | Alert stok menipis (badge notif) | P1 | ❌ |
| DASH-05 | Ringkasan kas & saldo akun | P1 | ❌ |

---

### 4.5 Modul Laporan

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| RPT-01 | Laporan Penjualan (filter tanggal, tabel + total) | P0 | ❌ |
| RPT-02 | Penjualan per Produk (ranking, qty, omset) | P0 | ❌ |
| RPT-03 | Penjualan per Kategori | P1 | ❌ |
| RPT-04 | Penjualan per Customer | P1 | ❌ |
| RPT-05 | Rekap Shift Kasir (daftar shift, biaya, selisih) | P0 | ❌ |
| RPT-06 | Laporan Arus Kas (masuk/keluar per kategori) | P1 | ❌ |
| RPT-07 | Laba Rugi (pendapatan - HPP - biaya) | P1 | ❌ |
| RPT-08 | Laporan Stok (posisi stok per gudang) | P1 | ❌ |
| RPT-09 | Laporan Pembelian | P2 | ❌ |
| RPT-10 | Share/export laporan sebagai PDF via WhatsApp | P1 | ❌ |

---

### 4.6 Modul Master Data

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| MD-01 | CRUD Produk (nama, kode, barcode, harga, foto, kategori) | P0 | ❌ |
| MD-02 | CRUD Kategori | P0 | ❌ |
| MD-03 | CRUD Customer + Grup Customer | P1 | ❌ |
| MD-04 | CRUD Supplier | P1 | ❌ |
| MD-05 | CRUD Satuan (unit) | P1 | ❌ |
| MD-06 | Kelola Gudang/Cabang | P1 | ❌ |
| MD-07 | Kelola Meja Makan (FnB) | P2 | ❌ |
| MD-08 | CRUD Diskon & Promo | P2 | ❌ |
| MD-09 | Kelola Modifier (topping, add-on) | P2 | ❌ |

---

### 4.7 Modul Inventory & Stok

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| INV-01 | Kartu stok / riwayat pergerakan stok | P1 | ❌ |
| INV-02 | Alert stok minimum (daftar produk di bawah min) | P1 | ❌ |
| INV-03 | Stock Opname (buat, input qty fisik, approve) | P1 | ✅ (draft) |
| INV-04 | Transfer Stok antar gudang | P1 | ❌ |
| INV-05 | Stock Adjustment (penyesuaian manual) | P1 | ❌ |

---

### 4.8 Modul Purchasing & Procurement

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| PUR-01 | Buat Purchase Order ke supplier | P2 | ❌ |
| PUR-02 | Penerimaan Barang (receiving) | P2 | ❌ |
| PUR-03 | Retur Pembelian | P2 | ❌ |

---

### 4.9 Modul Keuangan

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| FIN-01 | Daftar Akun Kas/Bank + saldo | P1 | ❌ |
| FIN-02 | Catat arus kas masuk/keluar | P1 | ❌ |
| FIN-03 | Kelola Hutang (ke supplier) | P2 | ❌ |
| FIN-04 | Kelola Piutang (dari customer) | P2 | ❌ |
| FIN-05 | Retur Penjualan | P1 | ❌ |

---

### 4.10 Modul Pengaturan

| ID | Fitur | Prioritas | Offline |
|----|-------|-----------|---------|
| SET-01 | Konfigurasi URL server (first-time setup) | P0 | — |
| SET-02 | Profil toko (nama, alamat, logo, NPWP) | P1 | ❌ |
| SET-03 | Pengaturan struk (header, footer, logo) | P2 | ❌ |
| SET-04 | Pengaturan pajak & mata uang | P2 | ❌ |
| SET-05 | Dark mode toggle | P1 | ✅ |
| SET-06 | Pair printer Bluetooth | P2 | ✅ |
| SET-07 | Manual sync trigger | P0 | ✅ |

---

## 5. Offline Mode — Spesifikasi Teknis

### 5.1 Strategi Offline

| Data | Strategi | Sync Direction |
|------|----------|----------------|
| **Produk, Kategori, Customer, Unit** | Cache ke SQLite saat login & periodic refresh | Server → App (Pull) |
| **Transaksi POS (Sale)** | Simpan lokal dulu, queue untuk sync | App → Server (Push) |
| **Hold Transactions** | Simpan 100% lokal | App → Server (Push) |
| **Kas Keluar Shift** | Simpan lokal, sync saat online | App → Server (Push) |
| **Laporan, Dashboard, Stok** | Online-only, tidak di-cache | — |

### 5.2 Offline Queue & Sync Flow

```
[Transaksi Offline]
      │
      ▼
┌─────────────┐     WiFi tersedia?
│ SQLite       │────── YES ──→ POST /api/v1/sync/push
│ pending_sales│                      │
│ (status:     │                      ▼
│  'pending')  │              Server menyimpan &
└─────────────┘              mengembalikan invoice
      │                      number resmi
      │                            │
      └──── Update status ◄────────┘
             'synced' +
             real invoice_number
```

### 5.3 Conflict Resolution Rules
1. **Server selalu menang** untuk master data (produk, harga, stok).
2. **App menang** untuk transaksi pending (server terima apa adanya).
3. **Invoice number**: App generate temporary (`OFFLINE-xxxx`), server replace dengan real invoice number saat sync.
4. **Stok**: Tidak di-enforce saat offline (kasir tanggung jawab). Server validasi saat sync dan beri warning jika stok minus.

---

## 6. Backend API Requirements

### 6.1 Endpoint yang Harus Dibangun

Semua endpoint di bawah prefix `/api/v1/`, dilindungi middleware `auth:sanctum`.

#### Auth
| Method | Endpoint | Body/Params | Response |
|--------|----------|-------------|----------|
| POST | `/auth/login` | `{email, password, device_name}` | `{token, user}` |
| POST | `/auth/logout` | — | `{message}` |
| GET | `/auth/me` | — | `{user, permissions}` |

#### POS
| Method | Endpoint | Body/Params | Response |
|--------|----------|-------------|----------|
| GET | `/pos/products` | `?q=&category_id=&warehouse_id=` | `{data: [products]}` |
| POST | `/pos/calculate-cart` | `{items, customer_id, promo_code}` | `{subtotal, discount, grand_total}` |
| POST | `/pos/checkout` | `{warehouse_id, items, payment_method, ...}` | `{sale}` |
| POST | `/pos/hold` | `{reference_label, cart_payload, ...}` | `{held}` |
| GET | `/pos/held-list` | `?warehouse_id=` | `{data: [held]}` |
| POST | `/pos/recall/{id}` | — | `{data: cart_payload}` |
| POST | `/pos/void/{sale}` | `{reason}` | `{sale}` |

#### Shift
| Method | Endpoint | Body/Params | Response |
|--------|----------|-------------|----------|
| GET | `/shifts/current` | — | `{data: shift}` |
| POST | `/shifts/open` | `{warehouse_id, starting_cash, notes}` | `{data: shift}` |
| POST | `/shifts/{id}/close` | `{closing_cash, notes}` | `{data: shift}` |
| POST | `/shifts/{id}/expenses` | `{amount, category, notes}` | `{data: shift}` |
| DELETE | `/shifts/{id}/expenses/{eid}` | — | `{data: shift}` |

#### Sync (Offline)
| Method | Endpoint | Body/Params | Response |
|--------|----------|-------------|----------|
| POST | `/sync/pull` | `{last_synced_at}` | `{products, categories, customers, ...}` |
| POST | `/sync/push` | `{sales: [...], expenses: [...]}` | `{synced_sales: [{temp_id, real_id, invoice}]}` |

#### Master Data, Inventory, Finance, Reports
> Endpoint lengkap sesuai tabel di Implementation Plan. Setiap resource mengikuti pola REST standar: `GET /resource`, `POST /resource`, `PUT /resource/{id}`, `DELETE /resource/{id}`.

---

## 7. Non-Functional Requirements

| Aspek | Requirement |
|-------|-------------|
| **Performance** | Halaman POS harus render < 500ms, scroll produk 60fps |
| **Offline Storage** | SQLite max ~50MB (produk + transaksi pending) |
| **Security** | Token tersimpan di FlutterSecureStorage (encrypted). HTTPS wajib di production. |
| **Compatibility** | Android 8.0+ (API 26+), target Android 14 |
| **Screen Size** | 5" HP — 12" tablet, responsive |
| **Battery** | Tidak boleh drain baterai berlebihan (no background polling kecuali sync) |
| **Startup** | Cold start < 3 detik |

---

## 8. Design System

### 8.1 Warna Brand
| Token | Hex | Penggunaan |
|-------|-----|------------|
| `brand-500` | `#f97316` (Orange) | Primary actions, header |
| `brand-600` | `#ea580c` | Pressed/hover state |
| `brand-50` | `#fff7ed` | Light background |
| `emerald-500` | `#10b981` | Success, kembalian |
| `rose-500` | `#f43f5e` | Error, void, kas keluar |
| `slate-900` | `#0f172a` | Text primary |
| `slate-50` | `#f8fafc` | Page background |

### 8.2 Typography
- **Primary**: Plus Jakarta Sans (Google Fonts)
- **Monospace (angka)**: JetBrains Mono
- **Sizes**: Heading 20sp, Body 14sp, Caption 11sp

### 8.3 Komponen UI Kunci
- **Card produk**: Rounded 16dp, shadow subtle, gambar ratio 1:1
- **Bottom sheet**: Rounded top 24dp, drag handle
- **Button**: Rounded 14dp, height 48dp (touch target)
- **Input field**: Rounded 12dp, floating label
- **Snackbar/Toast**: Rounded 16dp, gradient background

---

## 9. Prioritas Rilis

| Release | Modul | Target |
|---------|-------|--------|
| **v0.1-alpha** | Phase 0+1: Auth, POS Kasir, Shift, Offline | Minggu 2-3 |
| **v0.2-alpha** | Phase 2: Dashboard + Laporan | Minggu 4 |
| **v0.3-beta** | Phase 3: Master Data CRUD | Minggu 5 |
| **v0.4-beta** | Phase 4: Inventory & Stock | Minggu 6 |
| **v0.5-beta** | Phase 5: Purchasing & Finance | Minggu 7 |
| **v1.0** | Phase 6: Polish, Print, Play Store | Minggu 8 |

---

## 10. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|--------|--------|---------|
| Offline sync conflict (data race) | Data duplikat/hilang | FIFO queue, server-wins untuk master data, idempotency key |
| Printer Bluetooth tidak kompatibel | Struk gagal cetak | Support ESC/POS standard, test multi-brand |
| Performa lambat di HP low-end | UX buruk | Lazy loading, pagination, image caching |
| API breaking change saat update web | App crash | API versioning (`/v1/`), backward compatibility |
| Token expired saat offline lama | Gagal sync | Refresh token flow, re-login prompt |
