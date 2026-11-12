#!/usr/bin/env bash
# DEVELOPMENT: debug build (Godot debug keystore, ads = Google TEST IDs) bana kar jude phone par install.
# Password nahi chahiye. Release-signed app phone par ho to pehle uninstall karna padta hai (--reinstall).
#   bash tools/install_debug.sh [--reinstall]
set -euo pipefail
cd "$(dirname "$0")/.."
JDK="${JDK:-$HOME/.local/opt/jdk-17.0.21+9}"
BT="$JDK/bin/java -jar ${BT_JAR:-$HOME/.local/opt/bundletool/bundletool.jar}"
SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
ADB="$SDK/platform-tools/adb"
PKG="com.rekixo.squeezygame"
DKS="$HOME/.local/share/godot/keystores/debug.keystore"
OUT="build/test/debug.aab"

# Wireless debugging beech mein toot jaata hai: mDNS se phir jodo. Ek hi phone do raaste
# (wifi IP + mDNS) se dikh sakta hai, isliye ek serial chun kar wahi use karo.
pick_phone() {
  local s
  s=$("$ADB" devices | awk 'NR>1 && $2=="device"{print $1; exit}')
  if [ -z "$s" ]; then
    for addr in $("$ADB" mdns services | awk '/_adb-tls-connect/{print $3}'); do
      "$ADB" connect "$addr" > /dev/null 2>&1 || true
    done
    sleep 2
    s=$("$ADB" devices | awk 'NR>1 && $2=="device"{print $1; exit}')
  fi
  [ -n "$s" ] || { echo "Koi phone nahi juda (USB debugging / Wireless debugging chalu karo)."; exit 1; }
  SERIAL="$s"; export ANDROID_SERIAL="$s"
  echo "Phone: $SERIAL"
}

mkdir -p build/test
if [ "${SKIP_EXPORT:-0}" != 1 ]; then
echo "== Debug export"
godot --headless --path . --install-android-build-template \
  --export-debug "Android Release (Play Store AAB)" "$OUT" > build/test/export_debug.log 2>&1 \
  || { echo "Export fail: build/test/export_debug.log"; exit 1; }
fi
rm -rf build/test/debug.apks build/test/device-spec.json
pick_phone
$BT get-device-spec --adb "$ADB" --device-id "$SERIAL" --output build/test/device-spec.json --overwrite > /dev/null
$BT build-apks --bundle "$OUT" --output build/test/debug.apks --device-spec build/test/device-spec.json \
  --ks "$DKS" --ks-key-alias androiddebugkey --ks-pass pass:android > /dev/null
if [ "${1:-}" = "--reinstall" ]; then
  "$ADB" uninstall --user 0 "$PKG" || true
fi
pick_phone
$BT install-apks --apks build/test/debug.apks --adb "$ADB" --device-id "$SERIAL"
"$ADB" shell pm list packages --user 0 "$PKG" | grep -q "$PKG" && echo "Install OK (debug)"
