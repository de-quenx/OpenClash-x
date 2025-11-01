#!/bin/bash
. /lib/functions.sh
. /usr/share/openclash/openclash_ps.sh
. /usr/share/openclash/log.sh
. /usr/share/openclash/uci.sh

set_lock() {
   exec 872>"/tmp/lock/openclash_core.lock" 2>/dev/null
   flock -x 872 2>/dev/null
}

del_lock() {
   flock -u 872 2>/dev/null
   rm -rf "/tmp/lock/openclash_core.lock" 2>/dev/null
}

set_lock

# Get GitHub address modification setting (not used but kept for compatibility)
github_address_mod=$(uci_get_config "github_address_mod" || echo 0)
LOG_OUT "Info: Automatic update disabled - using installed core version"

# Get core type configuration
CORE_TYPE="$1"
C_CORE_TYPE=$(uci_get_config "core_type")
SMART_ENABLE=$(uci_get_config "smart_enable" || echo 0)
[ "$SMART_ENABLE" -eq 1 ] && CORE_TYPE="Smart"
[ -z "$CORE_TYPE" ] && CORE_TYPE="Meta"
small_flash_memory=$(uci_get_config "small_flash_memory")
CPU_MODEL=$(uci_get_config "core_version")
RELEASE_BRANCH=$(uci_get_config "release_branch" || echo "master")

# Create version file from installed core without downloading
/usr/share/openclash/clash_version.sh 2>/dev/null

if [ ! -f "/tmp/clash_last_version" ]; then
   LOG_OUT "Info: Version file created from installed core"
fi

# Set core path based on flash memory configuration
if [ "$small_flash_memory" != "1" ]; then
   meta_core_path="/etc/openclash/core/clash_meta"
   mkdir -p /etc/openclash/core
else
   meta_core_path="/tmp/etc/openclash/core/clash_meta"
   mkdir -p /tmp/etc/openclash/core
fi

# Get current installed core version
CORE_CV=$($meta_core_path -v 2>/dev/null |awk -F ' ' '{print $3}' |head -1)

# Get version from version file based on core type
if [ "$CORE_TYPE" = "Smart" ]; then
   CORE_LV=$(sed -n 2p /tmp/clash_last_version 2>/dev/null)
else
   CORE_LV=$(sed -n 1p /tmp/clash_last_version 2>/dev/null)
fi

# Check if service restart is needed
[ "$C_CORE_TYPE" = "$CORE_TYPE" ] || [ -z "$C_CORE_TYPE" ] && if_restart=1

# Check if core is installed
if [ -z "$CORE_CV" ]; then
   LOG_OUT "Warning: 【"$CORE_TYPE"】Core not installed"
   LOG_OUT "Info: Please upload core manually via WebUI"
   SLOG_CLEAN
   del_lock
   exit 0
fi

# Display installed core version information
LOG_OUT "Info: 【"$CORE_TYPE"】Core installed version: $CORE_CV"
LOG_OUT "Info: Automatic core updates are disabled"

# No download process, only check if restart is needed
if [ "$if_restart" -eq 1 ]; then
   uci -q set openclash.config.restart=1
   uci -q commit openclash
   if [ -z "$2" ] || ([ -n "$2" ] && [ "$2" != "one_key_update" ]); then
      if [ "$(unify_ps_prevent)" -eq 0 ]; then
         LOG_OUT "Info: Restarting OpenClash service..."
         uci -q set openclash.config.restart=0
         uci -q commit openclash
         /etc/init.d/openclash restart >/dev/null 2>&1 &
      fi
   fi
else
   SLOG_CLEAN
fi

del_lock