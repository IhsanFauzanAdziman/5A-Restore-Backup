Skenario pengujian bagian 3, Verifikasi Integritas (SHA-256)

Skenarionya adalah sebagai berikut:
- Uji positif (Arsip asli):
  `./scripts/verifikasi.sh tests/arsip_dummy.tar.gz tests/arsip_dummy.sha256`
  Dimana hasil yang diharapkan adalah Pesan `[SUKSES]` dan exit status `0`.

- Uji negatif (Arsip rusak/diubah):
  `./scripts/verifikasi.sh tests/arsip_rusak.tar.gz tests/arsip_dummy.sha256`
  Dimana hasil yang diharapkan adalah Pesan `[GAGAL]` dan exit status `4`.
