
# Dokumentasi Pengujian Restore - Joan

## 1. Identitas Pengujian

- Nama: Joan
- Bagian: 4 - Restore
- Proyek: 5A - Sistem Otomasi Backup dan Pemulihan Data Linux
- Lingkungan: Ubuntu Linux pada VirtualBox
- Tanggal pengujian: 24 November 2026

## 2. Tujuan Pengujian

Memastikan script restore.sh dapat memulihkan
arsip backup yang valid serta menolak arsip
yang mengalami perubahan atau kerusakan.

## 3. Pengujian Positif

### Skenario
Memulihkan arsip backup yang memiliki checksum
sesuai dengan file checksum yang disediakan.

### Perintah
./scripts/restore.sh tests/arsip_dummy.tar.gz tests/arsip_dummy.sha256 hasil_restore_joan_positif_2

### Hasil
- Verifikasi SHA-256 berhasil.
- Checksum tercatat dan aktual cocok.
- Proses ekstraksi berhasil.
- File data_dummy.txt berhasil dipulihkan.
- Exit status Restore: 0.

### Pemeriksaan isi file
Perintah cmp menghasilkan exit status 1
karena file sumber berukuran 41 byte dengan
line ending CRLF, sedangkan hasil ekstraksi
berukuran 40 byte dengan line ending LF.

Setelah dibandingkan menggunakan diff
--strip-trailing-cr, hasilnya exit status 0.
Isi teks kedua file sama setelah perbedaan
karakter CR di akhir baris diabaikan.

### Kesimpulan
Pengujian positif berhasil. Arsip valid
dapat dipulihkan ke direktori tujuan.

## 4. Pengujian Negatif

### Skenario
Menguji pemulihan menggunakan arsip rusak
dengan checksum milik arsip asli.

### Perintah
./scripts/restore.sh tests/arsip_rusak.tar.gz tests/arsip_dummy.sha256 hasil_restore_joan_negatif

### Hasil
- Checksum tercatat dan aktual berbeda.
- Script verifikasi mendeteksi perubahan arsip.
- Proses Restore dibatalkan.
- Direktori tujuan tidak dibuat.
- Tidak terjadi ekstraksi.
- Exit status Restore: 5.
- Pesan kegagalan tercatat pada restore.log.

### Kesimpulan
Pengujian negatif berhasil. Sistem menolak
arsip yang integritasnya tidak sesuai.

## 5. Kesimpulan Umum

Script restore.sh berhasil menjalankan proses
pemulihan terhadap arsip yang valid dan menolak
arsip yang checksum-nya tidak cocok.

Integrasi dengan verifikasi.sh berhasil
dilakukan menggunakan mekanisme SHA-256.

Pengujian positif dan negatif telah dilakukan
pada lingkungan Ubuntu Linux VirtualBox.
