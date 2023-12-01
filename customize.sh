# Checking for installation environment
# Abort installation if not using Magisk
if [ "$BOOTMODE" = false ]; then
    ui_print "- Installation outside Magisk is not supported"
    ui_print "- Install this module via Magisk Manager"
    abort "- Aborting installation !!"
fi

# Detect API level
if [ "$API" -lt 26 ]; then
    abort "! Only Android 8 and newer devices are supported."
fi

# Process Monitor Tool (PMT) variables
PMT_MODULE_PATH="$NVBASE/modules/magisk_proc_monitor"
PMTURL="https://github.com/HuskyDG/zygisk_proc_monitor/releases"

# Define package and app information
PKGNAME="$(grep_prop package "$MODPATH/module.prop")"
APPNAME="YouTube"
STOCKAPPVER=$(dumpsys package $PKGNAME | awk -F= '/versionName/ {print $2; exit}')
RVAPPVER="$(grep_prop version "$MODPATH/module.prop")"
URL="https://www.apkmirror.com/apk/google-inc/youtube/youtube-$(echo -n "$RVAPPVER" | tr "." "-")-release/"

# Function to check and display a message
check_and_abort() {
  if [ "$1" -eq 0 ]; then
    ui_print "! $2"
    am start -a android.intent.action.VIEW -d "$3" &>/dev/null
    abort "! $4"
  fi
}

# Check if the app is installed
check_and_abort ! -d "/proc/1/root/data/data/$PKGNAME" "- $APPNAME app is not installed" "$URL" "Aborting installation, please install $APPNAME."

# Check Process Monitor Tool
check_and_abort ! -d "$PMT_MODULE_PATH" "! Process Monitor Tool is NOT installed" "$PMTURL" "! Install it from: $PMTURL"

# Check PMT version
PMT_VER_CODE="$(grep_prop versionCode "$PMT_MODULE_PATH/module.prop")"
check_and_abort "$PMT_VER_CODE" -lt 10 "! Process Monitor Tool v2.3 or above is required" "$PMTURL" "! Upgrade from: $PMTURL"

# Check if PMT is enabled
check_and_abort -f "$PMT_MODULE_PATH/disable" || -f "$PMT_MODULE_PATH/remove" "! Process Monitor Tool is either not enabled or will be removed." "! Enable it in Magisk beforehand."

# Check for app version mismatch
check_and_abort "$STOCKAPPVER" != "$RVAPPVER" "- Installed $APPNAME version = $STOCKAPPVER\n- $APPNAME Revanced version = $RVAPPVER\n- App Version Mismatch !!" "$URL" "Aborting installation due to version mismatch."

# Install sqlite3 plug-in for detach
ui_print "- Installing sqlite3 plug-in for detach"
mkdir "$MODPATH/bin"
unzip -oj "$MODPATH/sqlite3.zip" "$ABI/sqlite3" -d "$MODPATH/bin" &>/dev/null || abort "! Unzip failed"
chmod 755 "$MODPATH/bin/sqlite3"
rm -rf "$MODPATH/sqlite3.zip"

# Disable battery optimization for YouTube ReVanced
sleep 1
ui_print "- Disabling Battery Optimization for $APPNAME"
dumpsys deviceidle whitelist +$PKGNAME > /dev/null 2>&1

ui_print "- Installation Successful !!"
