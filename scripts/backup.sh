#!/usr/bin/env bash
# backup.sh - Orkestrator: lock (flock), log, dan laporan
# Penanggung jawab : <namamu>
# Pemakaian        : ./scripts/backup.sh <sumber> <tujuan>
# Exit status      : 0 sukses | 1 parameter salah
#                    10 lock gagal (backup lain berjalan)
#                    selain itu = exit status tahap yang gagal

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

export LOG_FILE="${LOG_FILE:-$PROJECT_DIR/logs/backup.log}"
LOCK_FILE="${LOCK_FILE:-/tmp/backup.lock}"
REPORT_DIR="${REPORT_DIR:-$PROJECT_DIR/reports}"
RESTORE_BASE="${RESTORE_BASE:-$PROJECT_DIR/restore_test}"

log() {   # log <LEVEL> <pesan>
    local level="$1"; shift
    mkdir -p -- "$(dirname -- "$LOG_FILE")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [pid=$$] $*" | tee -a "$LOG_FILE" >&2
}

if [ "$#" -ne 2 ]; then
    log ERROR "Pemakaian: $0 <sumber> <tujuan>"
    exit 1
fi
SUMBER="$1"
TUJUAN="$2"

# ---------- LOCK ----------
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    log ERROR "Backup lain sedang berjalan (lock: $LOCK_FILE). Proses ditolak."
    exit 10
fi
log INFO "Lock diperoleh"

# ---------- LAPORAN ----------
NAMA_ARSIP="-"
HASH="-"
VERIF="-"
RESTORE="-"

tulis_laporan() {   # tulis_laporan <status>
    mkdir -p -- "$REPORT_DIR"
    local f="$REPORT_DIR/laporan_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "Status      : $1"
        echo "Nama arsip  : $NAMA_ARSIP"
        echo "Waktu       : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "SHA-256     : $HASH"
        echo "Verifikasi  : $VERIF"
        echo "Restore     : $RESTORE"
    } > "$f"
    chmod 600 "$f"
    cp -- "$f" "$REPORT_DIR/laporan_terbaru.txt"
    log INFO "Laporan ditulis: $f"
}

gagal() {   # gagal <pesan> <kode>
    log ERROR "$1"
    tulis_laporan "GAGAL - $1"
    exit "$2"
}

# ---------- 1. Validasi ----------
"$SCRIPT_DIR/validasi.sh" "$SUMBER" "$TUJUAN"
rc=$?; [ $rc -ne 0 ] && gagal "Validasi gagal (exit $rc)" $rc

# (hanya untuk demo uji dua proses bersamaan)
sleep "${BACKUP_DELAY:-0}"

# ---------- 2. Arsip ----------
ARSIP="$("$SCRIPT_DIR/buat_arsip.sh" "$SUMBER" "$TUJUAN")"
rc=$?; [ $rc -ne 0 ] && gagal "Pembuatan arsip gagal (exit $rc)" $rc
NAMA_ARSIP="$(basename -- "$ARSIP")"

# ---------- 3. Checksum ----------
CHECKSUM="$ARSIP.sha256"
if ! sha256sum "$ARSIP" > "$CHECKSUM"; then
    gagal "Gagal membuat checksum" 11
fi
chmod 600 "$CHECKSUM"
HASH="$(cut -d' ' -f1 "$CHECKSUM")"
log INFO "Checksum dibuat: $CHECKSUM"

# ---------- 4. Verifikasi ----------
"$SCRIPT_DIR/verifikasi.sh" "$ARSIP" "$CHECKSUM"
rc=$?
if [ $rc -ne 0 ]; then
    VERIF="GAGAL (exit $rc)"
    gagal "Verifikasi integritas gagal" $rc
fi
VERIF="LOLOS"

# ---------- 5. Restore ke direktori uji ----------
DIR_UJI="$RESTORE_BASE/$(date +%Y%m%d_%H%M%S)"
mkdir -p -- "$DIR_UJI"
"$SCRIPT_DIR/restore.sh" "$ARSIP" "$CHECKSUM" "$DIR_UJI"
rc=$?
if [ $rc -ne 0 ]; then
    RESTORE="GAGAL (exit $rc)"
    gagal "Restore gagal" $rc
fi
RESTORE="BERHASIL ($DIR_UJI)"

tulis_laporan "SUKSES"
log INFO "Backup selesai"
exit 0
