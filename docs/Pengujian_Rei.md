# Pengujian Bagian 5: Lock, Log, Laporan, dan Docker

**Penanggung jawab:** Rafi Rei Riordan / 2410512204
**Proyek:** 5A - Sistem Otomasi Backup dan Pemulihan Data Linux
**Branch:** `rei/lock-log-docker`
**File utama:** `scripts/backup.sh`

---

## 1. Deskripsi Komponen

`scripts/backup.sh` adalah orkestrator yang menjalankan seluruh pipeline secara berurutan dan menambahkan tiga hal di atasnya:

| Fitur | Implementasi |
|---|---|
| **Lock** | `exec 200>"$LOCK_FILE"` lalu `flock -n 200`. Jika lock sudah dipegang proses lain, script berhenti dengan **exit 10**. |
| **Log** | Fungsi `log <LEVEL> <pesan>` menulis `[waktu] [LEVEL] [pid=...] pesan` ke `logs/backup.log` dan ke layar. Variabel `LOG_FILE` di-`export` agar script lain ikut menulis ke file yang sama. |
| **Laporan** | Fungsi `tulis_laporan` menulis nama arsip, waktu, SHA-256, hasil verifikasi, dan hasil restore ke `reports/laporan_<waktu>.txt` (izin `600`), dengan salinan `laporan_terbaru.txt`. Laporan juga ditulis saat proses **gagal**. |
| **Docker** | Container membaca folder `reports/` lewat bind mount read-only (`-v "$(pwd)/reports:/data:ro"`). |

**Alur pipeline:**

```
Lock (flock) -> validasi.sh -> buat_arsip.sh -> checksum SHA-256
             -> verifikasi.sh -> restore.sh -> laporan
```

**Exit status tambahan:**

| Kode | Arti |
|---|---|
| 0 | Sukses |
| 1 | Parameter salah |
| 10 | Lock gagal, backup lain sedang berjalan |
| 11 | Gagal membuat checksum |
| lainnya | Diteruskan dari tahap yang gagal (validasi, arsip, verifikasi, restore) |

---

## 2. Skenario Pengujian

### Uji 1 (Positif): Satu proses backup berjalan penuh

**Perintah:**
```bash
mkdir -p /tmp/src /tmp/dst
echo halo > /tmp/src/a.txt
./scripts/backup.sh /tmp/src /tmp/dst
echo "exit=$?"
cat reports/laporan_terbaru.txt
```

**Hasil:**
- Lock diperoleh (`pid=5149`), validasi, arsip, checksum, verifikasi, dan restore berhasil.
- Arsip: `backup_20261125_091739.tar.gz`
- SHA-256: `dec53de469bb285d9eae89d0395d198db0fb3ada51ba45047fc7158dc598b911`
- Laporan: Status `SUKSES`, Verifikasi `LOLOS`, Restore `BERHASIL`.
- **Exit status: 0**

**Bukti:** `evidence/Bagian_5_Rei/[nama file screenshot]`

---

### Uji 2 (Negatif): Dua proses backup berjalan bersamaan

**Perintah** (satu baris):
```bash
BACKUP_DELAY=10 ./scripts/backup.sh /tmp/src /tmp/dst & sleep 1; ./scripts/backup.sh /tmp/src /tmp/dst; rc=$?; echo "exit=$rc"; wait
```

`BACKUP_DELAY=10` menahan proses pertama selama 10 detik setelah mengambil lock, sehingga proses kedua dijalankan saat lock masih dipegang.

**Hasil:**

| Proses | PID | Hasil |
|---|---|---|
| Pertama | 5677 | Mendapat lock pada 09:30:27, selesai dengan sukses (`Backup selesai`) |
| Kedua | 5709 | Ditolak pada 09:30:28: `Backup lain sedang berjalan (lock: /tmp/backup.lock). Proses ditolak.` |

- **Exit status proses kedua: 10**
- Proses pertama tidak terganggu dan hanya menghasilkan satu arsip.

**Bukti log:**
```bash
grep -E "Lock diperoleh|Backup lain|Backup selesai" logs/backup.log | tail -n 6
```

**Bukti:** `evidence/Bagian_5_Rei/[nama file screenshot]`

---

### Uji 3 (Positif): Container Docker membaca laporan (mount read-only)

**Perintah:**
```bash
docker run --rm -v "$(pwd)/reports:/data:ro" alpine cat /data/laporan_terbaru.txt
```

**Hasil:** [isi laporan tampil di terminal container. Tulis ringkasan hasil aslimu di sini.]

**Bukti:** `evidence/Bagian_5_Rei/[nama file screenshot]`

---

### Uji 4 (Negatif): Penulisan lewat mount read-only ditolak

**Perintah:**
```bash
docker run --rm -v "$(pwd)/reports:/data:ro" alpine sh -c 'echo x > /data/test.txt'
echo "exit=$?"
ls reports/
```

**Hasil:** [salin pesan error aslimu, seharusnya `Read-only file system`]
- **Exit status:** [isi sesuai hasilmu, biasanya 1]
- File `reports/test.txt` **tidak terbentuk** di host.

**Bukti konfigurasi mount:**
```bash
docker run -d --name uji_ro -v "$(pwd)/reports:/data:ro" alpine sleep 60
docker inspect uji_ro --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} | RW={{.RW}}{{end}}'
docker rm -f uji_ro
```
Hasil: `RW=false` [cocokkan dengan outputmu].

**Bukti:** `evidence/Bagian_5_Rei/[nama file screenshot]`

---

## 3. Ringkasan Hasil

| No | Skenario | Jenis | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| 1 | Satu proses backup penuh | Positif | Exit 0, laporan terbentuk | [Lulus] |
| 2 | Dua proses bersamaan | Negatif | Proses kedua exit 10, proses pertama sukses | [Lulus] |
| 3 | Container membaca laporan | Positif | Isi laporan tampil | [Lulus] |
| 4 | Container menulis ke mount `:ro` | Negatif | `Read-only file system`, exit non-nol | [Lulus] |

---

## 4. Analisis Teori Sistem Operasi

### 4.1 Critical Section dan Race Condition

*Critical section* adalah bagian program yang mengakses sumber daya bersama dan tidak boleh dijalankan lebih dari satu proses pada saat yang sama. Dalam proyek ini, sumber daya bersamanya adalah **direktori tujuan backup**, **file log**, dan **file laporan**.

Tanpa pengunci, dua proses `backup.sh` yang berjalan bersamaan bisa:
- membuat arsip dengan nama yang sama jika dimulai pada detik yang sama (nama arsip memakai stempel waktu sampai detik), sehingga saling menimpa;
- menulis file checksum yang tidak cocok dengan arsipnya;
- mencampur baris log sehingga urutan kejadian sulit dibaca.

Kondisi ketika hasil akhir bergantung pada urutan eksekusi proses yang tidak dapat diprediksi disebut **race condition**. Mutual exclusion pada `backup.sh` diselesaikan dengan `flock`: hanya satu proses yang berhasil memegang lock, dan proses lain gagal langsung (`-n`, *non-blocking*) lalu keluar dengan exit 10. Pada Uji 2, proses pertama (pid 5677) memegang lock, sedangkan proses kedua (pid 5709) ditolak dalam waktu satu detik.

Perlu dicatat bahwa pengecekan "apakah ada backup lain?" dan pengambilan lock dilakukan oleh `flock` sebagai **satu operasi atomik** di kernel. Cara manual seperti `if [ ! -f lock ]; then touch lock; fi` rentan terhadap celah antara pengecekan dan pembuatan file (*time-of-check to time-of-use*), sehingga dua proses masih bisa lolos bersamaan.

### 4.2 Sinkronisasi Proses: Advisory Lock

`flock` termasuk **advisory lock**: kernel tidak memaksa proses lain untuk mematuhinya. Lock hanya efektif jika semua pihak sama-sama memeriksanya. Artinya:
- Dua pemanggilan `backup.sh` saling terlindungi, karena sama-sama memanggil `flock` pada `LOCK_FILE` yang sama.
- Pengguna yang menjalankan `buat_arsip.sh` secara langsung (tanpa lewat `backup.sh`) **tidak** terlindungi oleh lock.

Karakteristik penting lainnya: lock terikat pada *file descriptor* (fd 200) milik proses. Ketika proses selesai atau mati (termasuk karena `kill` atau crash), kernel menutup fd dan melepaskan lock secara otomatis. Dengan demikian tidak ada *stale lock* (lock yang tertinggal karena proses mati), yang menjadi kelemahan cara berbasis file penanda biasa.

### 4.3 Proses dan Sistem Berkas

Setiap pemanggilan script menjadi satu proses dengan PID sendiri. `backup.sh` membuat proses anak untuk tiap tahap (`validasi.sh`, `buat_arsip.sh`, `verifikasi.sh`, `restore.sh`) dan membaca *exit status*-nya melalui `$?`. Exit status inilah mekanisme komunikasi hasil antarproses pada pipeline, sehingga kegagalan di satu tahap menghentikan tahap berikutnya dan dicatat ke laporan.

File lock berada di `/tmp/backup.lock`. File itu hanya berfungsi sebagai titik temu bagi proses-proses yang saling berkoordinasi, sedangkan penguncian sebenarnya dikelola kernel melalui tabel lock pada inode file tersebut. Karena `/tmp` dapat diakses semua pengguna, `LOCK_FILE` bisa diubah lewat variabel lingkungan jika diperlukan.

### 4.4 I/O dan Logging

Fungsi `log()` melakukan I/O ganda: menulis ke layar (stderr) dan menambahkan baris ke `logs/backup.log` memakai `tee -a`. Mode *append* membuat setiap penulisan dilakukan di akhir file, sehingga log dari beberapa proses tidak saling menimpa. Pencatatan PID pada setiap baris membuat log dapat ditelusuri per proses, misalnya untuk membedakan proses yang mendapat lock dengan yang ditolak (Uji 2).

Pembuatan arsip dan checksum adalah operasi I/O berat (membaca banyak file, menulis arsip terkompresi, lalu membaca arsip itu lagi untuk menghitung SHA-256), sehingga waktu eksekusinya terutama ditentukan oleh kecepatan disk. Pada Uji 2, satu proses dengan `BACKUP_DELAY=10` membutuhkan sekitar 12 detik secara total.

### 4.5 Proteksi dan Isolasi

Proteksi diterapkan di dua lapis:

1. **Izin berkas.** Arsip dibuat dengan `chmod 600` oleh `buat_arsip.sh`. File checksum dan laporan juga `chmod 600`, sehingga hanya pemilik yang dapat membaca dan menulis. Pengguna lain di sistem tidak dapat membaca isi backup.
2. **Mount read-only pada Docker.** Opsi `:ro` pada bind mount membuat kernel menolak setiap operasi tulis pada mount itu dengan error `EROFS` (*Read-only file system*), bahkan jika proses di dalam container berjalan sebagai root. Penolakan ini ditegakkan pada lapisan VFS kernel, bukan oleh aplikasi, sehingga tidak dapat dilewati dari dalam container.

Container juga hanya melihat folder `reports/` yang di-*mount*, bukan seluruh sistem berkas host. Ini menerapkan prinsip *least privilege*: container diberi akses minimum (baca saja, satu folder) untuk kebutuhan membaca laporan. Isolasi tampilan sistem berkas ini didukung oleh *mount namespace* pada Linux.

### 4.6 Penggunaan CPU dan Memori selama Pengarsipan

[Bagian ini opsional untuk bagianmu, karena fokusnya ada di proses pengarsipan. Jika kelompokmu mengukurnya, isi dengan hasil nyata. Contoh cara mengukur:]

```bash
/usr/bin/time -v ./scripts/backup.sh /tmp/src /tmp/dst 2>&1 | grep -E "Elapsed|Maximum resident|Percent of CPU"
```

[Tempel hasilnya di sini, lalu bandingkan dua ukuran data uji (kecil dan besar). Secara teori, kompresi gzip bersifat CPU-bound, sedangkan pembacaan file dan penulisan arsip bersifat I/O-bound. Memori yang dipakai `tar` dan `gzip` relatif kecil dan tetap, karena data diproses dalam aliran (*stream*) per blok.]

---

## 5. Kesimpulan

1. `flock` berhasil menjamin *mutual exclusion*: dari dua proses backup bersamaan, satu berjalan dan satu ditolak dengan exit 10.
2. Lock dilepas otomatis oleh kernel saat proses berakhir, sehingga tidak meninggalkan lock yang menggantung.
3. Log berformat `waktu, level, PID` dan laporan otomatis (nama arsip, waktu, SHA-256, hasil verifikasi) memudahkan audit, termasuk saat proses gagal.
4. Bind mount read-only memungkinkan container membaca laporan tanpa dapat mengubahnya, ditegakkan oleh kernel.

**Keterbatasan:** `flock` bersifat advisory, jadi hanya melindungi proses yang memakai `backup.sh`. Lock file di `/tmp` juga hanya berlaku pada satu mesin, bukan antar-mesin.
