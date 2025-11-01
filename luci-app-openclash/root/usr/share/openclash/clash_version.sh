#!/bin/bash
. /usr/share/openclash/uci.sh

set_lock() {
   exec 884>"/tmp/lock/openclash_clash_version.lock" 2>/dev/null
   flock -x 884 2>/dev/null
}

del_lock() {
   flock -u 884 2>/dev/null
   rm -rf "/tmp/lock/openclash_clash_version.lock" 2>/dev/null
}

set_lock

DOWNLOAD_FILE="/tmp/clash_last_version"

# Path binary Clash
CLASH_META="/etc/openclash/core/clash_meta"
CLASH_BINARY="/etc/openclash/core/clash"
CLASH_TUN="/etc/openclash/core/clash_tun"

# Fungsi untuk mendapatkan versi
get_clash_version() {
   local binary="$1"
   if [ -f "$binary" ] && [ -x "$binary" ]; then
      # Coba berbagai cara mendapatkan versi
      local ver=$("$binary" -v 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
      if [ -z "$ver" ]; then
         ver=$("$binary" -version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
      fi
      if [ -z "$ver" ]; then
         ver=$("$binary" 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
      fi
      echo "$ver"
   fi
}

# Deteksi core yang aktif dari config
CORE_TYPE=$(uci_get_config "core_type" || echo "0")

# 0=auto, 1=TUN, 2=Meta, 3=Game
case "$CORE_TYPE" in
   1)
      CORE_VERSION=$(get_clash_version "$CLASH_TUN")
      CORE_NAME="clash_tun"
      ;;
   2)
      CORE_VERSION=$(get_clash_version "$CLASH_META")
      CORE_NAME="clash_meta"
      ;;
   *)
      # Auto detect: cek Meta dulu, lalu TUN, lalu Premium
      if [ -f "$CLASH_META" ]; then
         CORE_VERSION=$(get_clash_version "$CLASH_META")
         CORE_NAME="clash_meta"
      elif [ -f "$CLASH_TUN" ]; then
         CORE_VERSION=$(get_clash_version "$CLASH_TUN")
         CORE_NAME="clash_tun"
      elif [ -f "$CLASH_BINARY" ]; then
         CORE_VERSION=$(get_clash_version "$CLASH_BINARY")
         CORE_NAME="clash"
      fi
      ;;
esac

# Simpan ke file dengan format yang mirip aslinya
if [ -n "$CORE_VERSION" ]; then
   cat > "$DOWNLOAD_FILE" << EOF
${CORE_VERSION}
# Update check disabled - ${CORE_NAME}
EOF
else
   cat > "$DOWNLOAD_FILE" << EOF
unknown
# No core installed or version not detected
EOF
fi

del_lock
