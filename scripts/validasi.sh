#!/usr/bin/env bash
# validasi.sh - Validasi sumber dan parameter backup
# Penanggung jawab: Ezra Sianturi
# Pemakaian: ./scripts/validasi.sh <sumber> <tujuan>

set -u

LOG_FILE="${LOG_FILE:-logs/validasi.log}"

log() {
mkdir -p "$(dirname "$LOG_FILE")"
echo "$(date '+%F %T') [$1] $2" | tee -a "$LOG_FILE" >&2
}

# Memeriksa jumlah parameter
if [ "$#" -ne 2 ]; then
log ERROR "Parameter harus terdiri dari sumber dan tujuan."
echo "Pemakaian: $0 <sumber> <tujuan>" >&2
exit 1
fi

SUMBER="$1"
TUJUAN="$2"

# Memeriksa keberadaan dan akses sumber
if [ ! -d "$SUMBER" ] || [ ! -r "$SUMBER" ]; then
log ERROR "Sumber tidak tersedia atau tidak terbaca: $SUMBER"
exit 2
fi

# Memeriksa apakah sumber kosong 
if [ -z "$(ls -A -- "$SUMBER" 2>/dev/null)" ]; then
log ERROR "Direktori sumber kosong: $SUMBER"
exit 3
fi

# Memeriksa direktori root
SUMBER_ABS=$(realpath -e -- "$SUMBER") || exit 2

if [ "$SUMBER_ABS" = "/" ]; then
log ERROR "Direktori root tidak boleh dijadikan sumber."
exit 4
fi

# Memeriksa apakah tujuan berada di dalam sumber
TUJUAN_ABS=$(realpath -m -- "$TUJUAN") || exit 5

case "$TUJUAN_ABS/" in
"$SUMBER_ABS/"*)
log ERROR "Tujuan tidak boleh berada di dalam sumber."
exit 5
;;
esac

log INFO "Validasi sumber dan parameter berhasil."
log INFO "Sumber: $SUMBER_ABS"
log INFO "Tujuan: $TUJUAN_ABS"

exit 0
