# Dokumentasi Pengujian Validasi Sumber dan Parameter

**Nama:** Ezra Sianturi  
**Peran:** Anggota 1 – Validasi Sumber dan Parameter

## Hasil Pengujian

| No. | Skenario Pengujian | Hasil yang Diharapkan | Status |
|-----|--------------------|-----------------------|--------|
| 1 | Sumber dan tujuan valid | Validasi berhasil, exit status 0 | Berhasil |
| 2 | Sumber tidak tersedia | Validasi ditolak, exit status 2 | Berhasil |
| 3 | Parameter kurang dari 2 | Validasi ditolak, exit status 1 | Berhasil |
| 4 | Direktori sumber kosong | Validasi ditolak, exit status 3 | Berhasil |
| 5 | Tujuan berada di dalam sumber | Validasi ditolak, exit status 5 | Berhasil |

## Kesimpulan

Berdasarkan lima skenario pengujian, script validasi berhasil
menjalankan pemeriksaan sumber dan tujuan backup sesuai dengan
parameter yang telah ditentukan. Seluruh pengujian positif dan
negatif menghasilkan exit status yang sesuai dengan harapan
