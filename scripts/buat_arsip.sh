#!/usr/bin/env bash
# buat_arsip.sh - Membuat arsip .tar.gz berstempel waktu
# Penanggung jawab : Anggota 2
# Pemakaian        : ./scripts/buat_arsip.sh <sumber> <tujuan>
# Exit status      : 0 sukses | 1 parameter salah | 2 sumber invalid
#                    3 tujuan tidak dapat ditulis | 4 tar gagal

set -u
LOG_FILE="${LOG_FILE:-logs/backup.log}"

log() {   # log <LEVEL> <pesan>
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%F %T') [$1] $2" | tee -a "$LOG_FILE" >&2
}

if [ $# -ne 2 ]; then
    log ERROR "Pemakaian: $0 <sumber> <tujuan>"
    exit 1
fi

SUMBER="$1"
TUJUAN="$2"

if [ ! -d "$SUMBER" ] || [ ! -r "$SUMBER" ]; then
    log ERROR "Sumber tidak tersedia atau tidak terbaca: $SUMBER"
    exit 2
fi

if [ ! -d "$TUJUAN" ] || [ ! -w "$TUJUAN" ]; then
    log ERROR "Tujuan tidak dapat ditulis: $TUJUAN"
    exit 3
fi

NAMA="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
ARSIP="$TUJUAN/$NAMA"

if tar -czf "$ARSIP" -C "$(dirname "$SUMBER")" "$(basename "$SUMBER")" 2>/dev/null; then
    chmod 600 "$ARSIP"            # pembatasan akses: hanya pemilik
    log INFO "Arsip terbentuk: $ARSIP"
    echo "$ARSIP"
    exit 0
else
    rm -f "$ARSIP"                # jangan tinggalkan arsip setengah jadi
    log ERROR "tar gagal membuat arsip: $ARSIP"
    exit 4
fi
