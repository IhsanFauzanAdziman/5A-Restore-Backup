# 5A-Restore-Backup

**Project 5A, Sistem Otomasi Backup dan Pemulihan Data Linux**  
**Kelas A, Kelompok 1**  
Mata Kuliah Sistem Operasi & Praktikum Sistem Operasi  
Program Studi S1 Sistem Informasi, Fakultas Ilmu Komputer, UPN "Veteran" Jakarta  
Dosen Pengampu: **Boby Suryo Prakoso S.T., M.Kom.**

--------------------
## 1. Deskripsi Proyek
Project 5A, Sistem Otomasi Backup dan Pemulihan Data Linux merupakan sebuah unit kerja yang membutuhkan pencadangan dokumen dan dapat diperiksa integritasnya serta dipulihkan ketika data hilang atau berubah. Proyek ini memiliki beberapa kumpulan skrip *Bash* untuk mengotomatisasi pencadangan direktori pada lingkungan Linux dengan alur: validasi direktori sumber dan parameter, pembuatan arsip terkompresi `.tar.gz` berstempel waktu (*timestamp*), pembuatan serta verifikasi integritas menggunakan *checksum* SHA-256, pengujian pemulihan (*restore*) ke direktori uji, serta penguncian proses simultan menggunakan `flock` dan pencatatan *log*. Container Docker juga digunakan dengan *bind mount read-only* (`:ro`) untuk membuktikan isolasi akses *baca-saja* atau *read-only* terhadap laporan dan berkas cadangan. Terdapat beberapa fitur utama didalamnya, diantaranya:
1. **Validasi & Pengarsipan Otomatis**, dimana validasi dilakukan pada direktori sumber dan tujuan serta pembuatan arsip terkompresi (`.tar.gz`) berstempel waktu.
2. **Verifikasi Integritas Data**, dimana pemeriksaan keutuhan berkas cadangan menggunakan `sha256sum` (`scripts/verifikasi.sh`) sebelum proses pemulihan dijalankan.
3. **Sinkronisasi & Proteksi Sistem**, dimana penguncian proses (`flock`) dilakukan untuk mencegah eksekusi ganda (*race condition*), pembatasan izin akses berkas (*permission*), serta pengamatan beban kerja pada dua ukuran beban uji.
4. **Sinkronisasi, *Logging*, & Audit Docker**, dimana *backup* utama dilakukan dengan penguncian proses (`flock`) untuk mencegah *race condition*, pencatatan *log*, serta pengujian isolasi akses baca-saja melalui Docker *bind mount read-only*.

Proyek ini dikerjakan secara berkelompok oleh Kelompok 1 yang beranggotakan 5 orang dengan pembagian secara berurutan sesuai yang telah dibagikan. Setiap anggota bertanggung jawab atas pekerjaan masing-masing sesuai pada tabel anggota dibawah.

--------------------
## 2. Anggota kelompok & Matriks pembagian tugas
| Anggota | Nama | NIM | Komponen / Tanggung Jawab | Skrip | Dokumentasi & Bukti |
| :---: | :--- | :---: | :--- | :--- | :--- |
| **1** | Ezra Sianturi | `2510512032` | Validasi sumber, tujuan, izin akses, dan parameter | [`scripts/validasi.sh`](scripts/validasi.sh) | [Laporan Uji](docs/Pengujian_Validasi_Ezra.md) · [Evidence](evidence/Bagian_1_Validasi_Ezra.txt) |
| **2** | Ihsan Fauzan Adziman | `2510512028` | Pembuatan arsip `.tar.gz` dan pembangkitan *checksum* SHA-256 | [`scripts/buat_arsip.sh`](scripts/buat_arsip.sh) | [Folder Docs](docs/) · [Folder Evidence](evidence/) |
| **3** | Andika Alif Rachmanto | `2510512002` | Verifikasi integritas data dan validasi kecocokan *checksum* SHA-256 | [`scripts/verifikasi.sh`](scripts/verifikasi.sh) | [Laporan Uji](docs/Pengujian_Integritas_Andika%20Alif) · [Evidence](evidence/) |
| **4** | Joan Azhim Satyaguna | `2510512026` | Pemulihan data (*restore*) otomatis ke direktori uji | [`scripts/restore.sh`](scripts/restore.sh) | [Laporan Uji](docs/Pengujian_Restore_Joan.md) · [Evidence](evidence/Bagian_4_Restore_Joan) |
| **5** | Rafi Rei Riordan | `2410512204` | Orkestrasi `backup.sh`, *lock* (`flock`), *logging*, dan aktivitas Docker | [`scripts/backup.sh`](scripts/backup.sh) | [Laporan Uji](docs/Pengujian_Rei.md) · [Evidence](evidence/Bagian_5_Rei) |

--------------------
## 3. Alur Arsitektur Sistem
Seluruh modul dirancang sebagai rantai kerja berurutan dengan validasi *exit status* disetiap tahap seperti berikut:

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
```
--------------------
## 4. Matriks Skenario Pengujian
| No. | Penanggung Jawab | Skenario Positif | Skenario Negatif |
| :---: | :--- | :--- | :--- |
| **1** | Anggota 1 (Ezra) | Menjalankan `validasi.sh` dengan parameter lengkap dan direktori sumber yang valid serta dapat dibaca. | Menjalankan `validasi.sh` dengan parameter kosong, direktori sumber tidak ditemukan, atau tujuan *read-only*. |
| **2** | Anggota 2 (Ihsan) | Menjalankan `buat_arsip.sh` pada direktori sumber valid untuk membuat arsip `.tar.gz` dan `.sha256`. | Menjalankan `buat_arsip.sh` dengan sumber tidak valid atau direktori tujuan tanpa izin tulis. |
| **3** | Anggota 3 (Andika) | Memverifikasi arsip cadangan asli menggunakan `verifikasi.sh` dengan berkas *checksum* SHA-256 yang sesuai. | Memverifikasi arsip yang telah rusak/dimodifikasi (`arsip_rusak.tar.gz`) menggunakan `verifikasi.sh`. |
| **4** | Anggota 4 (Joan) | Menjalankan `restore.sh` menggunakan arsip yang lolos verifikasi SHA-256 menuju direktori uji. | Menjalankan `restore.sh` memakai arsip korup/gagal verifikasi atau mengarah ke direktori sumber asli. |
| **5** | Anggota 5 (Rei) | Menjalankan orkestrasi `backup.sh` secara tunggal dan membaca direktori *backup* dari kontainer Docker *mount* `:ro`. | Menjalankan dua proses `backup.sh` secara bersamaan dan mencoba menulis berkas ke *mount* `:ro` di dalam Docker. |

--------------------
## 5. Hasil Pengujian
| No. | Hasil Positif | Hasil Negatif | Status | Bukti |
| :---: | :--- | :--- | :---: | :---: |
| **1** | Parameter dan izin direktori tervalidasi.<br>`Exit 0`. | Validasi gagal dan proses dihentikan dengan pesan *error*.<br>`Exit != 0`. | ✅ Lulus | [Log](evidence/Bagian_1_Validasi_Ezra.txt) |
| **2** | Arsip `.tar.gz` berstempel waktu dan `.sha256` terbentuk utuh.<br>`Exit 0`. | Pembuatan arsip ditolak tanpa menghasilkan arsip korup.<br>`Exit != 0`. | ✅ Lulus | [Evidence](evidence/) |
| **3** | *Checksum* SHA-256 cocok (`HASIL: LULUS`).<br>`Exit 0`. | *Checksum* berbeda terdeteksi (`HASIL: GAGAL`), *restore* dibatalkan.<br>`Exit 4`. | ✅ Lulus | [Log](evidence/) |
| **4** | Berkas terekstrak ke direktori uji dan isi identik dengan sumber.<br>`Exit 0`. | Ekstraksi ditolak sebelum berjalan karena arsip tidak valid.<br>`Exit != 0`. | ✅ Lulus | [Log](evidence/Bagian_4_Restore_Joan) |
| **5** | *Lock* `flock` diperoleh, *log* tercatat, kontainer membaca berkas.<br>`Exit 0`. | Eksekusi ganda ditolak `flock`; penulisan Docker ditolak (`Read-only file system`). | ✅ Lulus | [Log](evidence/Bagian_5_Rei) |
