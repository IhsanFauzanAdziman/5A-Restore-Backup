#!/bin/bash

# =======================================================================================
# Nama Script : verifikasi.sh
# Deskripsi   : Verifikasi integritas berkas arsip menggunakan SHA-256
# Proyek      : 5A - Sistem Otomasi Backup dan Pemulihan Data Linux (Bagian 3) Kelompok 1
# =======================================================================================

# 1. Deklarasi Variabel
ARSIP="$1"
FILE_CHECKSUM="$2"
LOG_FILE="verifikasi.log"
WAKTU=$(date '+%Y-%m-%d %H:%M:%S')

# Fungsi bantu untuk mencatat log ke file
catat_log() {
    local STATUS="$1"
    local PESAN="$2"
    echo "[$WAKTU] [$STATUS] $PESAN" >> "$LOG_FILE"
}

# 2. Perulangan (Looping) untuk Validasi Dependensi Perintah Linux
for CMD in sha256sum awk date; do
    if ! command -v "$CMD" &> /dev/null; then
        echo "[ERROR] Perintah sistem '$CMD' tidak tersedia di mesin ini."
        catat_log "ERROR" "Dependensi '$CMD' tidak ditemukan."
        exit 3
    fi
done

# 3. Validasi Input Parameter (Error Handling)
if [ -z "$ARSIP" ] || [ -z "$FILE_CHECKSUM" ]; then
    echo "[ERROR] Parameter kurang!"
    echo "Cara pakai: $0 <path_file_arsip> <path_file_checksum>"
    catat_log "ERROR" "Eksekusi gagal: parameter input tidak lengkap."
    exit 1
fi

if [ ! -f "$ARSIP" ] || [ ! -r "$ARSIP" ]; then
    echo "[ERROR] Berkas arsip '$ARSIP' tidak ditemukan atau tidak dapat dibaca."
    catat_log "ERROR" "Berkas arsip '$ARSIP' tidak ditemukan/tidak terbaca."
    exit 2
fi

if [ ! -f "$FILE_CHECKSUM" ] || [ ! -s "$FILE_CHECKSUM" ]; then
    echo "[ERROR] Berkas checksum '$FILE_CHECKSUM' tidak ditemukan atau kosong."
    catat_log "ERROR" "Berkas checksum '$FILE_CHECKSUM' tidak valid."
    exit 2
fi

# 4. Pengambilan & Perbandingan Nilai Checksum SHA-256
HASH_TERCATAT=$(awk '{print $1}' "$FILE_CHECKSUM")
HASH_AKTUAL=$(sha256sum "$ARSIP" | awk '{print $1}')

echo "=========================================="
echo "Memeriksa Arsip   : $ARSIP"
echo "Checksum Tercatat : $HASH_TERCATAT"
echo "Checksum Aktual   : $HASH_AKTUAL"
echo "=========================================="

# 5. Percabangan Penentuan Kondisi Positif vs Negatif
if [ "$HASH_TERCATAT" = "$HASH_AKTUAL" ]; then
    echo "[SUKSES] Integritas terverifikasi, Arsip asli dan tidak berubah."
    catat_log "SUKSES" "Arsip '$ARSIP' lolos verifikasi (Hash cocok)."
    exit 0
else
    echo "[GAGAL] Peringatan! Checksum berbeda, Arsip telah diubah atau rusak!"
    catat_log "GAGAL" "Arsip '$ARSIP' gagal verifikasi (Hash tidak cocok)."
    exit 4
fi
