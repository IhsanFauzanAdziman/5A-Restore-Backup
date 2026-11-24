#!/usr/bin/env bash

# ==================================================
# Nama Script : restore.sh
# Deskripsi   : Pemulihan data dari arsip backup
# Penanggung Jawab : Joan
# Proyek      : 5A - Sistem Otomasi Backup dan
#               Pemulihan Data Linux
#
# Penggunaan:
# ./scripts/restore.sh <arsip> <checksum> <tujuan>
#
# Exit Status:
# 0 = Restore berhasil
# 1 = Parameter salah
# 2 = Arsip tidak tersedia
# 3 = File checksum tidak tersedia
# 4 = Script verifikasi tidak tersedia
# 5 = Verifikasi gagal / arsip rusak
# 6 = Direktori tujuan bermasalah
# 7 = Ekstraksi gagal
# ==================================================

set -u

# 1. Deklarasi variabel
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

VERIFIKASI="$SCRIPT_DIR/verifikasi.sh"
LOG_FILE="${LOG_FILE:-$PROJECT_DIR/logs/restore.log}"

# 2. Fungsi pencatatan log
log() {
    local LEVEL="$1"
    shift

    mkdir -p -- "$(dirname -- "$LOG_FILE")"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LEVEL] $*" \
        | tee -a "$LOG_FILE"
}

# 3. Validasi jumlah parameter
if [ "$#" -ne 3 ]; then
    log ERROR "Penggunaan: $0 <arsip> <checksum> <tujuan>"
    exit 1
fi

ARSIP="$1"
FILE_CHECKSUM="$2"
TUJUAN="$3"

# 4. Validasi dependensi
for CMD in tar sha256sum awk date tee find; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        log ERROR "Perintah $CMD tidak tersedia."
        exit 4
    fi
done

# 5. Validasi file arsip
if [ ! -f "$ARSIP" ] || [ ! -r "$ARSIP" ]; then
    log ERROR "Arsip tidak ditemukan atau tidak dapat dibaca: $ARSIP"
    exit 2
fi

# 6. Validasi file checksum
if [ ! -f "$FILE_CHECKSUM" ] || \
   [ ! -r "$FILE_CHECKSUM" ] || \
   [ ! -s "$FILE_CHECKSUM" ]; then

    log ERROR "File checksum tidak ditemukan atau kosong."
    exit 3
fi

# 7. Validasi script verifikasi
if [ ! -f "$VERIFIKASI" ] || [ ! -r "$VERIFIKASI" ]; then
    log ERROR "Script verifikasi tidak ditemukan."
    exit 4
fi

# 8. Verifikasi integritas SHA-256
log INFO "Memulai verifikasi integritas arsip."

bash "$VERIFIKASI" "$ARSIP" "$FILE_CHECKSUM"
STATUS_VERIFIKASI=$?

if [ "$STATUS_VERIFIKASI" -ne 0 ]; then
    log ERROR "Verifikasi gagal. Restore dibatalkan."
    exit 5
fi

log INFO "Checksum cocok. Arsip dinyatakan valid."

# 9. Memeriksa format arsip TAR.GZ
if ! tar -tzf "$ARSIP" >/dev/null 2>&1; then
    log ERROR "Format arsip TAR.GZ tidak valid."
    exit 5
fi

# 10. Memeriksa keamanan path dalam arsip
PATH_TIDAK_AMAN=0

while IFS= read -r ENTRY; do
    case "$ENTRY" in
        /*|..|../*|*/../*|*/..)
            log ERROR "Path tidak aman ditemukan: $ENTRY"
            PATH_TIDAK_AMAN=1
            break
            ;;
    esac
done < <(tar -tzf "$ARSIP")

if [ "$PATH_TIDAK_AMAN" -ne 0 ]; then
    log ERROR "Restore dibatalkan demi keamanan."
    exit 5
fi

# 11. Validasi direktori tujuan
if [ -L "$TUJUAN" ] || \
   { [ -e "$TUJUAN" ] && [ ! -d "$TUJUAN" ]; }; then

    log ERROR "Tujuan bukan direktori biasa."
    exit 6
fi

if ! mkdir -p -- "$TUJUAN"; then
    log ERROR "Direktori tujuan gagal dibuat."
    exit 6
fi

if [ ! -w "$TUJUAN" ]; then
    log ERROR "Direktori tujuan tidak dapat ditulis."
    exit 6
fi

# Mencegah penimpaan data yang sudah ada
if [ -n "$(find "$TUJUAN" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    log ERROR "Direktori tujuan harus kosong."
    exit 6
fi

# 12. Melakukan proses pemulihan data
log INFO "Memulai proses ekstraksi arsip."

if tar -xzf "$ARSIP" -C "$TUJUAN" \
    --no-same-owner --no-same-permissions; then

    log INFO "Restore berhasil."
    log INFO "Arsip       : $ARSIP"
    log INFO "Lokasi hasil: $TUJUAN"

    exit 0

else
    log ERROR "Proses ekstraksi gagal."
    exit 7
fi
