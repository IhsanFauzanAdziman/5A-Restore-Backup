# Portofolio Proyek Akhir Sistem Operasi
- Nama: Andika Alif Rachmanto
- NIM: 2510512002
- Kelas: A
- Kelompok: 1
- Topik / Paket: Paket 5A - Backup & Restore Otomatis
- Peran & Sub-tugas: Anggota 3 - Verifikasi Integritas Arsip (Checksum SHA-256)
- Repository Utama Kelompok: https://github.com/IhsanFauzanAdziman/5A-Restore-Backup
- Repository Fork Pribadi: https://github.com/dikalifnew/5A-Restore-Backup

## Ringkasan Kontribusi Teknis
- Daftar berkas yang saya buat/ubah yaitu:
  - `scripts/verifikasi.sh`
  - `tests/data_dummy.txt` (beserta arsip uji `arsip_dummy.tar.gz`, `arsip_rusak.tar.gz`, dan berkas checksum)
  - `evidence/` (tangkapan layar pengujian terminal dan catatan `verifikasi.log`)
  - `README.md` (dokumentasi penggunaan dan pengujian modul verifikasi)
- Ringkasan alur kerja modul yang saya kerjakan:
  1. Menerima parameter berkas arsip `.tar.gz` dan berkas referensi *checksum* SHA-256 sebelum tahap *restore* dijalankan.
  2. Menghitung ulang nilai *hash* SHA-256 dari arsip target menggunakan utilitas `sha256sum` dan membandingkannya dengan nilai referensi.
  3. Menampilkan status `[SUKSES]` dengan *exit status* `0` apabila *checksum* cocok, sehingga arsip dinyatakan aman untuk dipulihkan.
  4. Menampilkan status `[GAGAL]` dengan *exit status* `4` apabila *checksum* tidak cocok (arsip korup/berubah) dan menghentikan proses agar data rusak tidak menimpa sistem.
  5. Mencatat setiap hasil verifikasi beserta stempel waktu (*timestamp*) ke dalam berkas `verifikasi.log` sebagai jejak audit.

## Bukti Skenario Pengujian
- Skenario positif yang saya jalankan:
  - **Perintah:** Menjalankan `./scripts/verifikasi.sh` terhadap arsip valid `tests/arsip_dummy.tar.gz` lalu memeriksa status keluaran dengan `echo $?`.
  - **Hasil:** Keluaran terminal menampilkan pesan `[SUKSES]`, nilai *checksum* SHA-256 cocok dengan referensi, dan *exit status* bernilai `0`.
  - **Bukti:** Tangkapan layar eksekusi terminal dan catatan log tersimpan di folder `evidence/`.
- Skenario negatif/gagal yang saya jalankan:
  - **Perintah:** Menjalankan `./scripts/verifikasi.sh` terhadap arsip yang telah dimodifikasi/rusak (`tests/arsip_rusak.tar.gz`) lalu memeriksa `echo $?` dan isi `verifikasi.log`.
  - **Hasil:** Keluaran terminal menampilkan pesan `[GAGAL]`, nilai *checksum* tidak cocok, *exit status* bernilai `4`, proses *restore* ditolak, dan kegagalan tercatat di `verifikasi.log`.
  - **Bukti:** Tangkapan layar eksekusi terminal dan isi `verifikasi.log` tersimpan di folder `evidence/`.

## Pemetaan Konsep Teori SO
1. **Sistem Berkas dan Integritas Data**, yaitu Menjamin keutuhan berkas pada level *filesystem* melalui verifikasi *cryptographic hash* (SHA-256) untuk mendeteksi perubahan bit atau korupsi data sebelum operasi penulisan ulang (*restore*) dilakukan.
2. **Manajemen Proses dan *Exit Status***, dengan memanfaatkan mekanisme *exit code* (`0` untuk sukses, `4` untuk gagal integritas) sebagai standar komunikasi antar-proses (*inter-process signaling*) agar skrip orkestrator kelompok dapat mengambil keputusan secara otomatis.
3. **Sistem I/O dan *Logging***, dengan mengelola aliran *standard output* (`stdout`) dan pengalihan (*redirection*) ke berkas `verifikasi.log` untuk kebutuhan pencatatan aktivitas dan penelusuran kesalahan (*troubleshooting*).

## Refleksi Individu
Melalui pengerjaan modul verifikasi integritas arsip (`scripts/verifikasi.sh`) pada Paket 5A ini, saya memahami bagaimana fungsi *hash* kriptografis SHA-256 bekerja secara praktis di lingkungan Linux untuk menjamin keutuhan data cadangan sebelum proses pemulihan (*restore*) dijalankan. Perubahan sekecil apa pun pada isi berkas terbukti menghasilkan perubahan nilai *hash* secara menyeluruh (*avalanche effect*), sehingga sistem dapat mendeteksi korupsi data maupun manipulasi arsip secara akurat.

Selain aspek teknis pemrograman Bash, pengelolaan kode keluar (*exit status* `0` untuk arsip valid dan `4` untuk arsip rusak), serta pencatatan riwayat audit ke `verifikasi.log`, proyek ini juga melatih kedisiplinan saya dalam menerapkan alur kerja kolaborasi Git menggunakan *branch* terpisah agar kontribusi individu terdokumentasi dengan rapi tanpa mengganggu kode utama tim.
