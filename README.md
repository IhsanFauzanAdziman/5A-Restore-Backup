# 5A-Restore-Backup

**Project 5A, Sistem Otomasi Backup dan Pemulihan Data Linux**
**Kelas A, Kelompok 1**
Mata Kuliah Sistem Operasi & Praktikum Sistem Operasi
Program Studi S1 Sistem Informasi, Fakultas Ilmu Komputer, UPN "Veteran" Jakarta  
Dosen Pengampu: **Boby Suryo Prakoso S.T., M.Kom.**

Proyek ini dikerjakan secara berkelompok oleh 5 anggota dengan pembagian modul yang terintegrasi secara berurutan (*pipeline*).

--------------------

## 1. Deskripsi Proyek
Project 5A, Sistem Otomasi Backup dan Pemulihan Data Linux merupakan sebuah unit kerja yang membutuhkan pencadangan dokumen dan dapat diperiksa integritasnya serta dipulihkan ketika data hilang atau berubah. Proyek ini memiliki beberapa kumpulan skrip *Bash* untuk mengotomatisasi pencadangan direktori pada lingkungan Linux dengan alur: validasi direktori sumber dan parameter, pembuatan arsip terkompresi `.tar.gz` berstempel waktu (*timestamp*), pembuatan serta verifikasi integritas menggunakan *checksum* SHA-256, pengujian pemulihan (*restore*) ke direktori uji, serta penguncian proses simultan menggunakan `flock` dan pencatatan *log*. Container Docker juga digunakan dengan *bind mount read-only* (`:ro`) untuk membuktikan isolasi akses *baca-saja* atau *read-only* terhadap laporan dan berkas cadangan.

### Fitur Utama
1. **Validasi & Pengarsipan Otomatis**, dimana validasi dilakukan pada direktori sumber dan tujuan serta pembuatan arsip terkompresi (`.tar.gz`) berstempel waktu.
2. **Verifikasi Integritas Data**, dimana pemeriksaan keutuhan berkas cadangan menggunakan `sha256sum` (`scripts/verifikasi.sh`) sebelum proses pemulihan dijalankan.
3. **Sinkronisasi & Proteksi Sistem**, dimana penguncian proses (`flock`) dilakukan untuk mencegah eksekusi ganda (*race condition*), pembatasan izin akses berkas (*permission*), serta pengamatan beban kerja pada dua ukuran beban uji.
4. **Pemulihan & Audit Laporan**, dimana ekstraksi pemulihan (*restore*) diujikan ke direktori uji, pencatatan *log* eksekusi, serta verifikasi pembacaan laporan melalui Docker *bind mount read-only*.

--------------------

## 2. Anggota kelompok & Matriks pembagian tugas
| Anggota | Nama | NIM | Komponen / Tanggung Jawab | Skrip & Dokumentasi Uji |
| :---: | :--- | :---: | :--- | :--- |
| **1** | Ezra Sianturi | `2510512032` | Validasi sumber, tujuan, izin akses, dan parameter | `scripts/validasi.sh` · [Laporan Uji](docs/Pengujian_Validasi_Ezra.md) |
| **2** | Rafi Rei Riordan | `2410512204` | Pembuatan arsip `.tar.gz` dan pembangkitan *checksum* SHA-256 | `scripts/buat_arsip.sh` · [Laporan Uji](docs/Pengujian_Rei.md) |
| **3** | Andika Alif Rachmanto | `2510512002` | Verifikasi integritas data dan validasi kecocokan *checksum* SHA-256 | `scripts/verifikasi.sh` · [Laporan Uji](docs/Pengujian_Integritas_Andika_Alif.md) |
| **4** | Joan Azhim Satyaguna | `2510512026` | Pemulihan data (*restore*) otomatis ke direktori uji | `scripts/restore.sh` · [Laporan Uji](docs/Pengujian_Restore_Joan.md) |
| **5** | Ihsan Fauzan Adziman | `2510512028` | Sinkronisasi *lock* (`flock`), *logging*, laporan, dan aktivitas Docker | `scripts/backup_lock.sh` · [Folder Evidence](evidence/) |

> **Catatan:** Pastikan nama berkas di kolom *Skrip & Dokumentasi Uji* sesuai dengan nama final di folder [`scripts/`](scripts/) dan [`docs/`](docs/).

--------------------

## 3. Alur Arsitektur Sistem
Seluruh modul dirancang sebagai rantai kerja berurutan (*pipeline*) dengan validasi *exit status* di setiap tahap:

```text
[Direktori Sumber]
       │
       ▼
(1) Validasi Sumber & Parameter  ──► Gagal: Tolak & Exit Non-Nol
       │ Valid (Exit 0)
       ▼
(2) Pembuatan Arsip (.tar.gz)    ──► Gagal: Tujuan Read-Only / Error (Exit 3)
       │ Terbentuk + SHA-256
       ▼
(3) Verifikasi Integritas Arsip  ──► Gagal: Checksum Berbeda / Rusak (Exit 4)
       │ Identik (Exit 0)
       ▼
(4) Pemulihan Data (Restore)     ──► Gagal: Ditolak Sebelum Ekstrak (Exit 5)
       │ Pulih Identik (Exit 0)
       ▼
(5) Lock (flock), Log, & Laporan ──► Audit via Docker Bind Mount Read-Only

--------------------

