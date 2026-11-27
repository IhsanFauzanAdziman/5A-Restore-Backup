#!/usr/bin/env bash
# buat_arsip.sh - Membuat arsip .tar.gz berstempel waktu
# Penanggung jawab : Ihsan Fauzan Adziman
# Pemakaian        : ./scripts/buat_arsip.sh <sumber> <tujuan>
# Exit status      : 0 sukses
#                    1 parameter salah
#                    2 sumber invalid
#                    3 tujuan tidak dapat ditulis
#                    4 tar gagal
#                    5 checksum gagal

set -u

LOG_FILE="${LOG_FILE:-logs/backup.log}"

log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%F %T') [$1] $2" | tee -a "$LOG_FILE" >&2
}

# Validasi jumlah parameter
if [ $# -ne 2 ]; then
    log ERROR "Pemakaian: $0 <sumber> <tujuan>"
    exit 1
fi

SUMBER="$1"
TUJUAN="$2"

# Validasi sumber
if [ ! -d "$SUMBER" ] || [ ! -r "$SUMBER" ]; then
    log ERROR "Sumber tidak tersedia atau tidak terbaca: $SUMBER"
    exit 2
fi

# Validasi tujuan
if [ ! -d "$TUJUAN" ] || [ ! -w "$TUJUAN" ] || [ ! -x "$TUJUAN" ]; then
    log ERROR "Tujuan tidak dapat ditulis: $TUJUAN"
    exit 3
fi

# Membuat nama arsip dengan timestamp
NAMA="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
ARSIP="$TUJUAN/$NAMA"

# Membuat arsip
if tar -czf "$ARSIP" \
    -C "$(dirname "$SUMBER")" \
    "$(basename "$SUMBER")" 2>/dev/null; then

    # Membatasi akses arsip
    if ! chmod 600 "$ARSIP"; then
        rm -f "$ARSIP"
        log ERROR "Gagal mengatur permission arsip"
        exit 4
    fi

    # Membuat checksum SHA-256
    if sha256sum "$ARSIP" > "$ARSIP.sha256"; then

        # Membatasi akses checksum
        if ! chmod 600 "$ARSIP.sha256"; then
            rm -f "$ARSIP" "$ARSIP.sha256"
            log ERROR "Gagal mengatur permission checksum"
            exit 5
        fi

        log INFO "Arsip berhasil dibuat: $ARSIP"
        log INFO "Checksum berhasil dibuat: $ARSIP.sha256"

        echo "$ARSIP"
        exit 0

    else
        rm -f "$ARSIP" "$ARSIP.sha256"
        log ERROR "Gagal membuat checksum"
        exit 5
    fi

else
    rm -f "$ARSIP"
    log ERROR "tar gagal membuat arsip: $ARSIP"
    exit 4
fi
