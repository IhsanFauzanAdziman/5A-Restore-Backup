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

**Image yang dipakai:** `alpine:latest` (IMAGE ID `3ea06e4cb95e`, ukuran 8,43 MB)

**Hasil:** isi `reports/laporan_terbaru.txt` (status, nama arsip, waktu, SHA-256, verifikasi, restore) tampil di terminal container. **Exit status: 0** [pastikan screenshot-mu menampilkan `exit=0`].

**Bukti:** `evidence/Bagian_5_Rei/[nama file screenshot]`

---

### Uji 4 (Negatif): Penulisan lewat mount read-only ditolak

**Perintah (mencoba menambah isi file laporan yang ada):**
```bash
sha256sum reports/laporan_terbaru.txt
docker run --rm -v "$(pwd)/reports:/data:ro" alpine sh -c 'echo x >> /data/laporan_terbaru.txt'
echo "exit=$?"
sha256sum reports/laporan_terbaru.txt
```

**Hasil:**
- Pesan: `sh: can't create /data/laporan_terbaru.txt: Read-only file system`
- **Exit status: 1**
- SHA-256 `reports/laporan_terbaru.txt` **sebelum** dan **sesudah** percobaan identik:
  `5431ad89954c9b4784a0521ffbb20c2fe9106d0e86978d5816e26c0907e8c2c1`
  sehingga berkas di host terbukti tidak berubah.

**Bukti konfigurasi mount:**
```bash
docker run -d --name uji_ro -v "$(pwd)/reports:/data:ro" alpine sleep 60
docker inspect uji_ro --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} | RW={{.RW}}{{end}}'
docker rm -f uji_ro
```
Hasil yang diharapkan: `RW=false` [cocokkan dengan outputmu; hapus baris ini jika tidak menjalankan `docker inspect`].

**Bukti:** `evidence/Bagian_5_Rei/[nama file screenshot]`

---

### Uji 5: Pengukuran CPU dan Memori pada Dua Ukuran Beban

**Perintah:**
```bash
# beban kecil (1 MB)
mkdir -p /tmp/src_kecil /tmp/dst && head -c 1M /dev/urandom > /tmp/src_kecil/data.bin
/usr/bin/time -v ./scripts/backup.sh /tmp/src_kecil /tmp/dst 2>&1 | grep -E "Elapsed|Maximum resident|Percent of CPU"

# beban besar (200 MB)
mkdir -p /tmp/src_besar && head -c 200M /dev/urandom > /tmp/src_besar/data.bin
/usr/bin/time -v ./scripts/backup.sh /tmp/src_besar /tmp/dst 2>&1 | grep -E "Elapsed|Maximum resident|Percent of CPU"
```

**Hasil:**

| Beban uji | Ukuran data | Waktu (wall clock) | Penggunaan CPU | Memori maksimum (resident) |
|---|---|---|---|---|
| Kecil | 1 MB | 0,90 detik | 91% | 4.368 KB |
| Besar | 200 MB | 31,00 detik | 94% | 4.372 KB |

Data uji dibuat dari `/dev/urandom` (acak), sehingga hampir tidak bisa dikompresi. Hasil pada data nyata yang lebih mudah dikompresi bisa berbeda.

**Bukti:** `evidence/Bagian_5_Rei/[nama file screenshot]`

---

## 3. Ringkasan Hasil

| No | Skenario | Jenis | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| 1 | Satu proses backup penuh | Positif | Exit 0, laporan terbentuk | Lulus |
| 2 | Dua proses bersamaan | Negatif | Proses kedua exit 10, proses pertama sukses | Lulus |
| 3 | Container membaca laporan | Positif | Isi laporan tampil | Lulus |
| 4 | Container menulis ke mount `:ro` | Negatif | `Read-only file system`, exit non-nol, checksum host tetap | Lulus (exit 1) |
| 5 | Pengukuran CPU/memori, 2 ukuran beban | Pengamatan | Waktu, CPU, dan memori tercatat | Tercatat |

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

Pembuatan arsip dan checksum adalah operasi I/O berat (membaca banyak file, menulis arsip terkompresi, lalu membaca arsip itu lagi untuk menghitung SHA-256), sehingga waktu eksekusinya dipengaruhi kecepatan disk sekaligus kerja CPU (lihat 4.6). Pada Uji 2, satu proses dengan `BACKUP_DELAY=10` membutuhkan sekitar 12 detik secara total, termasuk jeda 10 detik yang disengaja.

### 4.5 Proteksi dan Isolasi

Proteksi diterapkan di dua lapis:

1. **Izin berkas.** Arsip dibuat dengan `chmod 600` oleh `buat_arsip.sh`. File checksum dan laporan juga `chmod 600`, sehingga hanya pemilik yang dapat membaca dan menulis. Pengguna lain di sistem tidak dapat membaca isi backup.
2. **Mount read-only pada Docker.** Opsi `:ro` pada bind mount membuat kernel menolak setiap operasi tulis pada mount itu dengan error `EROFS` (*Read-only file system*), bahkan jika proses di dalam container berjalan sebagai root. Penolakan ini ditegakkan pada lapisan VFS kernel, bukan oleh aplikasi, sehingga tidak dapat dilewati dari dalam container.

Container juga hanya melihat folder `reports/` yang di-*mount*, bukan seluruh sistem berkas host. Ini menerapkan prinsip *least privilege*: container diberi akses minimum (baca saja, satu folder) untuk kebutuhan membaca laporan. Isolasi tampilan sistem berkas ini didukung oleh *mount namespace* pada Linux.

### 4.6 Penggunaan CPU dan Memori selama Pengarsipan

Hasil pengukuran pada Uji 5 (seluruh pipeline `backup.sh`, diukur dengan `/usr/bin/time -v`):

| Beban uji | Ukuran data | Waktu | CPU | Memori maksimum |
|---|---|---|---|---|
| Kecil | 1 MB | 0,90 detik | 91% | 4.368 KB |
| Besar | 200 MB | 31,00 detik | 94% | 4.372 KB |

**Penggunaan CPU.** Pada kedua beban, proses memakai sekitar 91-94% dari satu inti CPU. Artinya selama berjalan proses hampir selalu aktif menghitung dan jarang menunggu, sehingga beban ini bersifat **CPU-bound**. Penyebab utamanya adalah kompresi `gzip` pada `tar -czf` dan penghitungan SHA-256 (`sha256sum`), yang dijalankan beberapa kali dalam pipeline karena arsip diverifikasi lagi oleh `restore.sh`. Satu proses tunggal tidak melebihi satu inti, jadi angka sekitar 90% tidak berarti CPU penuh pada mesin multi-inti.

**Waktu.** Data bertambah sekitar 200 kali lipat (1 MB menjadi 200 MB), sedangkan waktu naik sekitar 34 kali (0,90 menjadi 31 detik). Pada beban kecil, waktu didominasi biaya tetap (memulai banyak proses, validasi, jeda `sleep 1` pada restore, dan penulisan log). Pada beban besar, biaya tetap itu terlihat kecil dibanding kerja kompresi dan hash yang tumbuh seiring ukuran data.

**Memori.** Memori maksimum hampir tidak berubah (sekitar 4,3 MB) walaupun data 200 kali lebih besar. Ini sesuai sifat `tar`, `gzip`, dan `sha256sum` yang memproses data secara berkelanjutan per blok (*stream*), bukan memuat seluruh berkas ke memori. Nilai ini adalah memori maksimum satu proses terbesar (*maximum resident set size*), bukan jumlah semua proses.

**Catatan keterbatasan.** Data uji berasal dari `/dev/urandom`, yang hampir tidak bisa dikompresi. Pada data nyata yang lebih mudah dikompresi, ukuran arsip lebih kecil dan waktu penulisan bisa berbeda. Pengukuran dilakukan di mesin virtual (VirtualBox), sehingga angka absolutnya bergantung pada sumber daya VM.

---

## 5. Kesimpulan

1. `flock` berhasil menjamin *mutual exclusion*: dari dua proses backup bersamaan, satu berjalan dan satu ditolak dengan exit 10.
2. Lock dilepas otomatis oleh kernel saat proses berakhir, sehingga tidak meninggalkan lock yang menggantung.
3. Log berformat `waktu, level, PID` dan laporan otomatis (nama arsip, waktu, SHA-256, hasil verifikasi) memudahkan audit, termasuk saat proses gagal.
4. Bind mount read-only memungkinkan container membaca laporan tanpa dapat mengubahnya, ditegakkan oleh kernel.

**Keterbatasan:** `flock` bersifat advisory, jadi hanya melindungi proses yang memakai `backup.sh`. Lock file di `/tmp` juga hanya berlaku pada satu mesin, bukan antar-mesin.
