# 5A-Restore-Backup

Sistem Otomasi Backup dan Pemulihan Data Linux (5A)
**Kelas A, Kelompok 1**  
Program Studi S1 Sistem Informasi | Fakultas Ilmu Komputer, UPN Veteran Jakarta  
Mata Kuliah Sistem Operasi & Praktikum Sistem Operasi

## 1. Deskripsi Proyek
Proyek ini merupakan implementasi sistem otomasi pencadangan (*backup*), verifikasi integritas data, dan pemulihan (*restore*) berbasis *Bash shell script* pada lingkungan Linux. Sistem dibangun untuk memastikan dokumen penting dapat diarsipkan secara otomatis dengan identitas waktu, diperiksa keasliannya menggunakan *checksum* SHA-256, dilindungi dari bentrokan proses bersamaan menggunakan mekanisme penguncian (`flock`), serta diuji isolasi aksesnya melalui kontainer Docker.

### Fitur Utama
1. **Validasi & Pengarsipan Otomatis:** Validasi direktori sumber dan tujuan serta pembuatan arsip terkompresi (`.tar.gz`) berstempel waktu.
2. **Verifikasi Integritas Data:** Pemeriksaan keutuhan berkas cadangan menggunakan `sha256sum` sebelum proses pemulihan dijalankan.
3. **Sinkronisasi & Proteksi Sistem:** Penguncian proses (`flock`) untuk mencegah eksekusi ganda (*race condition*), pembatasan izin akses berkas (*permission*), serta pengujian pada dua ukuran beban uji.
4. **Pemulihan & Audit Laporan:** Ekstraksi pemulihan (*restore*) ke direktori uji, pencatatan *log* eksekusi, serta verifikasi pembacaan laporan melalui Docker *bind mount read-only*.

---

## 2. Alur Arsitektur Sistem
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
