#!/bin/bash
. /usr/share/openclash/log.sh
. /usr/share/openclash/uci.sh

set_lock() {
   exec 878>"/tmp/lock/openclash_update.lock" 2>/dev/null
   flock -x 878 2>/dev/null
}

del_lock() {
   flock -u 878 2>/dev/null
   rm -rf "/tmp/lock/openclash_update.lock" 2>/dev/null
}

set_lock

# Create version file from locally installed version
if [ -n "$1" ] && [ "$1" != "one_key_update" ]; then
   [ ! -f "/tmp/openclash_last_version" ] && /usr/share/openclash/openclash_version.sh "$1" 2>/dev/null
elif [ -n "$2" ]; then
   [ ! -f "/tmp/openclash_last_version" ] && /usr/share/openclash/openclash_version.sh "$2" 2>/dev/null
else
   [ ! -f "/tmp/openclash_last_version" ] && /usr/share/openclash/openclash_version.sh 2>/dev/null
fi

# Log version file creation status
if [ ! -f "/tmp/openclash_last_version" ]; then
   LOG_OUT "Info: Version file created from locally installed OpenClash"
fi

# Get currently installed OpenClash version
LAST_OPVER="/tmp/openclash_last_version"
LAST_VER=$(sed -n 1p "$LAST_OPVER" 2>/dev/null |sed "s/^v//g" |tr -d "\n")

# Detect package manager and get installed version
if [ -x "/bin/opkg" ]; then
   OP_CV=$(rm -f /var/lock/opkg.lock && opkg status luci-app-openclash 2>/dev/null |grep 'Version' |awk -F 'Version: ' '{print $2}' 2>/dev/null)
elif [ -x "/usr/bin/apk" ]; then
   OP_CV=$(apk list luci-app-openclash 2>/dev/null|grep 'installed' | grep -oE '[0-9]+(\.[0-9]+)*' | head -1 2>/dev/null)
fi

# Get configuration settings (kept for compatibility but not used for downloads)
RELEASE_BRANCH=$(uci_get_config "release_branch" || echo "master")
github_address_mod=$(uci_get_config "github_address_mod" || echo 0)

# Handle one key update mode - only update core without downloading OpenClash package
if [ "$1" = "one_key_update" ]; then
   # Enable OpenClash service
   uci -q set openclash.config.enable=1
   uci -q commit openclash
   
   LOG_OUT "Info: One key update mode - updating core only"
   
   # Run core update script in background
   if [ -n "$2" ]; then
      /usr/share/openclash/openclash_core.sh "Meta" "$1" "$2" >/dev/null 2>&1 &
   else
      /usr/share/openclash/openclash_core.sh "Meta" "$1" >/dev/null 2>&1 &
   fi
   
   # Wait for core update process to complete
   wait
fi

# Display current OpenClash version information
if [ -n "$OP_CV" ]; then
   LOG_OUT "Info: OpenClash installed version: $OP_CV"
   LOG_OUT "Info: Automatic OpenClash updates are disabled"
else
   LOG_OUT "Warning: OpenClash is not installed or version cannot be detected"
fi

# Check if service restart is needed (usually set by core update)
if [ "$(uci_get_config "restart")" -eq 1 ]; then
   LOG_OUT "Info: Restarting OpenClash service..."
   # Reset restart flag
   uci -q set openclash.config.restart=0
   uci -q commit openclash
   # Restart OpenClash service in background
   /etc/init.d/openclash restart >/dev/null 2>&1 &
else
   # Clean log if no restart needed
   SLOG_CLEAN
fi

# Release lock
del_lock