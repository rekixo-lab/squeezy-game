#!/usr/bin/env bash
# Merged manifest jaanch: target/min SDK, sirf allowlist wali permissions, sahi AdMob App ID.
#   bash tools/check_manifest.sh <manifest.xml> release|debug
set -euo pipefail
M="$1"; MODE="${2:-release}"
REAL_APP_ID="ca-app-pub-9987799703505828~4755476455"
TEST_APP_ID="ca-app-pub-3940256099942544~3347511713"
ALLOWED="android.permission.INTERNET
android.permission.ACCESS_NETWORK_STATE
android.permission.AD_ID
com.google.android.gms.permission.AD_ID
android.permission.READ_BASIC_PHONE_STATE
android.permission.WAKE_LOCK
android.permission.FOREGROUND_SERVICE
android.permission.RECEIVE_BOOT_COMPLETED
com.rekixo.squeezygame.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
fail=0
grep -q 'targetSdkVersion="36"' "$M" || { echo "FAIL: targetSdk 36 nahi"; fail=1; }
grep -q 'minSdkVersion="24"' "$M" || { echo "FAIL: minSdk 24 nahi"; fail=1; }
perms=$(grep -oE '<uses-permission[^>]*android:name="[^"]+"' "$M" | sed -E 's/.*android:name="([^"]+)".*/\1/' | sort -u)
echo "Permissions:"; echo "$perms" | sed 's/^/  /'
for p in $perms; do
  echo "$ALLOWED" | grep -qx "$p" || { echo "FAIL: allowlist se bahar permission: $p"; fail=1; }
done
want=$([ "$MODE" = release ] && echo "$REAL_APP_ID" || echo "$TEST_APP_ID")
grep -q "android:value=\"$want\"" "$M" && echo "AdMob App ID ($MODE): $want (OK)" \
  || { echo "FAIL: AdMob App ID ($MODE) $want nahi mila"; fail=1; }
exit $fail
