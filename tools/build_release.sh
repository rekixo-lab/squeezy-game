#!/usr/bin/env bash
# Signed Play Store .aab banata hai + saare checks. Password chupke se poochta hai (screen par nahi dikhta,
# log mein nahi jaata; bundletool ke liye sirf ek private temp file (chmod 600) jo script khatam hote hi delete hoti hai).
#   bash tools/build_release.sh            -> sirf build + checks
#   bash tools/build_release.sh --install  -> saath mein USB se jude phone par install bhi
set -euo pipefail
cd "$(dirname "$0")/.."

KS="${KS:-$HOME/keys/squeezy-upload.jks}"
ALIAS="${ALIAS:-upload}"
JDK="${JDK:-$HOME/.local/opt/jdk-17.0.21+9}"
GODOT="${GODOT:-$(command -v godot)}"
BT_JAR="${BT_JAR:-$HOME/.local/opt/bundletool/bundletool.jar}"
SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
ZA="$SDK/build-tools/36.1.0/zipalign"
PRESET="Android Release (Play Store AAB)"
OUT="build/squeezy_game.aab"
BT="$JDK/bin/java -jar $BT_JAR"

[ -f "$KS" ] || { echo "Keystore nahi mila: $KS"; exit 1; }
read -r -s -p "Keystore password: " KSPASS; echo
PASSFILE="$(mktemp)"; chmod 600 "$PASSFILE"
trap 'rm -f "$PASSFILE"; unset KSPASS GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD' EXIT
printf '%s' "$KSPASS" > "$PASSFILE"

# Password sahi hai? (galat ho to yahin ruk jao)
"$JDK/bin/keytool" -list -keystore "$KS" -storepass:file "$PASSFILE" -alias "$ALIAS" > /dev/null \
  || { echo "Password ya alias galat hai."; exit 1; }

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KS"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$KSPASS"
mkdir -p build
rm -f "$OUT"
echo "== Export (kuch minute lagenge)..."
"$GODOT" --headless --path . --install-android-build-template --export-release "$PRESET" "$OUT" > build/export.log 2>&1 \
  || { echo "Export fail. build/export.log dekho."; exit 1; }
unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
[ -s "$OUT" ] || { echo "AAB nahi bana. build/export.log dekho."; exit 1; }

echo "== bundletool validate"
$BT validate --bundle "$OUT" > /dev/null && echo "OK"
echo "== Manifest"
$BT dump manifest --bundle "$OUT" > build/manifest.xml
grep -oE '(versionCode|versionName|package)="[^"]*"' build/manifest.xml | sort -u
bash tools/check_manifest.sh build/manifest.xml release || { echo "Manifest check FAIL"; exit 1; }
echo "== Signature"
"$JDK/bin/jarsigner" -verify "$OUT" | grep -q "jar verified" && echo "jar verified (OK)"
"$JDK/bin/keytool" -printcert -jarfile "$OUT" | grep -E "Owner|SHA256:" | head -2

echo "== APKs + 16 KB alignment"
rm -rf build/apks build/test.apks
CONNECTED=()
if [ "${1:-}" = "--install" ]; then CONNECTED=(--connected-device --adb "$SDK/platform-tools/adb"); fi
$BT build-apks --bundle "$OUT" --output build/test.apks "${CONNECTED[@]}" \
  --ks "$KS" --ks-key-alias "$ALIAS" --ks-pass "file:$PASSFILE" > /dev/null
mkdir -p build/apks && unzip -q -o build/test.apks -d build/apks
fail=0
for f in build/apks/splits/*.apk; do "$ZA" -c -P 16 4 "$f" || { echo "FAIL zipalign: $f"; fail=1; }; done
[ "$fail" = 0 ] && echo "zipalign -P 16: OK"

if [ "${1:-}" = "--install" ]; then
  echo "== Phone par install"
  $BT install-apks --apks build/test.apks --adb "$SDK/platform-tools/adb" && echo "Install OK"
fi
echo
echo "DONE: $OUT"
