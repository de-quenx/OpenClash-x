#!/bin/bash
. /usr/share/openclash/uci.sh

set_lock() {
   exec 869>"/tmp/lock/openclash_version.lock" 2>/dev/null
   flock -x 869 2>/dev/null
}

del_lock() {
   flock -u 869 2>/dev/null
   rm -rf "/tmp/lock/openclash_version.lock" 2>/dev/null
}

set_lock

DOWNLOAD_FILE="/tmp/openclash_last_version"

# Deteksi versi terinstall
if [ -x "/bin/opkg" ]; then
   OP_CV=$(rm -f /var/lock/opkg.lock && opkg status luci-app-openclash 2>/dev/null |grep 'Version' |awk -F 'Version: ' '{print $2}' 2>/dev/null)
elif [ -x "/usr/bin/apk" ]; then
   OP_CV=$(apk list luci-app-openclash 2>/dev/null|grep 'installed' | grep -oE '[0-9]+(\.[0-9]+)*' | head -1 2>/dev/null)
fi

# Buat file dengan format yang benar agar tidak error
if [ -n "$OP_CV" ]; then
   cat > "$DOWNLOAD_FILE" << EOF
v${OP_CV}
# Update check disabled - current version is latest
EOF
fi

del_lock
