# PORTOFOLIO
## Proyek 5A – Otomasi Backup dan Pemulihan Data Linux

### 1. Identitas

| Keterangan | Informasi |
|---|---|
| Nama | Ihsan Fauzan Adziman |
| NIM | 2510512028 |
| Kelompok | 1 |
| Mata Kuliah | Sistem Operasi dan Praktikum Sistem Operasi |
| Institusi | UPN Veteran Jakarta |
| Repository | [5A-Restore-Backup](https://github.com/IhsanFauzanAdziman/5A-Restore-Backup) |
| Branch | `Ihsan/arsip` |
| Peran | Anggota 2 – Pembuatan Arsip |

### 2. Deskripsi Proyek

Proyek 5A merupakan proyek pengembangan sistem otomasi backup dan pemulihan data pada sistem operasi Linux. Sistem ini dirancang untuk membantu proses pencadangan data secara terstruktur melalui penggunaan shell scripting.

Dalam proyek ini, saya bertanggung jawab pada bagian pembuatan arsip. Bagian tersebut berfungsi mengemas direktori sumber menjadi file arsip berformat `.tar.gz`, memberikan nama berdasarkan waktu pembuatan, serta menghasilkan checksum SHA-256 untuk membantu pemeriksaan integritas arsip.

### 3. Kontribusi dan Tanggung Jawab

Kontribusi saya dalam proyek ini meliputi:

1. Mengembangkan script `scripts/buat_arsip.sh` untuk membuat arsip direktori sumber.
2. Mengimplementasikan kompresi menggunakan perintah `tar` dengan format `.tar.gz`.
3. Menambahkan timestamp pada nama arsip agar setiap hasil backup memiliki identitas waktu.
4. Mengimplementasikan pembuatan checksum menggunakan `sha256sum`.
5. Menambahkan validasi direktori sumber dan direktori tujuan.
6. Menerapkan permission `600` pada file arsip dan checksum untuk membatasi akses.
7. Menambahkan pencatatan aktivitas dan kesalahan melalui log.
8. Mengimplementasikan exit status untuk membedakan kondisi keberhasilan dan kegagalan proses.

### 4. Implementasi

File utama yang menjadi tanggung jawab saya:

` scripts/buat_arsip.sh `

Script menerima dua parameter:

```bash
./scripts/buat_arsip.sh tests output
```

Penjelasan implementasi:

| Fitur | Penjelasan |
|---|---|
| Validasi sumber | Memastikan direktori sumber tersedia dan dapat dibaca. |
| Validasi tujuan | Memastikan direktori tujuan tersedia dan dapat ditulis. |
| Pembuatan arsip | Menggunakan `tar -czf` untuk membuat arsip `.tar.gz`. |
| Timestamp | Menggunakan `date` untuk menghasilkan nama arsip berdasarkan tanggal dan waktu. |
| Checksum | Menggunakan `sha256sum` untuk menghasilkan file pemeriksaan integritas. |
| Permission | Menggunakan `chmod 600` untuk membatasi akses file. |
| Logging | Mencatat informasi proses dan kesalahan ke file log. |
| Exit status | Memberikan kode status sesuai kondisi proses. |

### 5. Skenario Pengujian

Pengujian dirancang untuk memastikan fungsi pembuatan arsip berjalan sesuai kebutuhan.

**A. Pengujian Positif**

Tujuan: Memastikan script dapat membuat arsip dan checksum dari direktori sumber yang valid.

Perintah:

```bash
mkdir -p tests output
echo "Dokumen pertama" > tests/dokumen1.txt
echo "Dokumen kedua" > tests/dokumen2.txt
chmod +x scripts/buat_arsip.sh
ARSIP=$(./scripts/buat_arsip.sh tests output)
STATUS=$?
echo "Status: $STATUS"
echo "Arsip: $ARSIP"
ls -lh output/
sha256sum -c "$ARSIP.sha256"
```

Indikator keberhasilan:
- File `.tar.gz` terbentuk.
- File `.sha256` terbentuk.
- Nama arsip memiliki timestamp.
- Exit status bernilai `0`.
- Verifikasi checksum menampilkan `OK`.

**B. Pengujian Negatif**

Tujuan: Memastikan script dapat menangani direktori tujuan yang tidak memiliki izin tulis.

Persiapan dan perintah:

```bash
mkdir -p output-readonly
chmod 555 output-readonly
./scripts/buat_arsip.sh tests output-readonly
echo "Status: $?"
```

Indikator keberhasilan:
- Program menampilkan pesan kesalahan.
- Proses pembuatan arsip dihentikan.
- Exit status bernilai `3`.
- Tidak terdapat arsip baru pada direktori tujuan.

Pengujian permission dilakukan menggunakan akun pengguna biasa, bukan root.

**Status pengujian:** ✅ Lulus [Evidence](https://github.com/IhsanFauzanAdziman/5A-Restore-Backup/blob/9d6f2fd6836955a6a1ef37ba2358ba0d7f03e538/evidence/Bagian_2_Arsip%20dan%20Checksum_Ihsan.md)
.

### 6. Konsep Sistem Operasi yang Diterapkan

Beberapa konsep sistem operasi yang diterapkan dalam bagian ini adalah:

- **File System:** Pengelolaan direktori sumber dan direktori tujuan sebagai lokasi penyimpanan data.
- **File Permission:** Pengaturan hak akses menggunakan perintah `chmod`.
- **Input/Output:** Proses membaca file dari direktori sumber dan menulis hasil arsip ke direktori tujuan.
- **Process Management:** Eksekusi perintah eksternal seperti `tar`, `sha256sum`, dan `chmod` melalui shell.
- **Shell Scripting:** Otomasi serangkaian perintah Linux menggunakan Bash.
- **Data Integrity:** Pemeriksaan integritas arsip menggunakan checksum SHA-256.

### 7. Hasil dan Pembelajaran

Melalui pengerjaan bagian pembuatan arsip, saya mempelajari bagaimana proses pencadangan data dapat diotomatisasi menggunakan Bash pada Linux. Saya juga memahami penggunaan perintah `tar`, `sha256sum`, `chmod`, serta mekanisme validasi dan penanganan kesalahan.

Selain implementasi program, saya memperoleh pemahaman mengenai pentingnya permission, integritas data, dan pencatatan aktivitas dalam proses backup.

### 8. Dokumentasi dan Referensi Pengerjaan

- Repository utama: https://github.com/IhsanFauzanAdziman/5A-Restore-Backup
- Branch pengerjaan: `Ihsan/arsip`
- Script utama: `scripts/buat_arsip.sh`
- Dokumentasi pengujian: `evidence/Bagian_2_Arsip dan Checksum_Ihsan.md` 

---

**Penanggung Jawab:**  
Ihsan Fauzan Adziman  
Anggota 2 – Pembuatan Arsip
