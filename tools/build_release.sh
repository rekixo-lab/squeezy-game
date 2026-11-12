#!/usr/bin/env bash
# Signed Play Store .aab banata hai + saare checks.
# Upload wali EK hi file: build/upload/squeezy_game_v<versionName>_code<versionCode>.aab
# Baaki sab (log, manifest, test .apks) build/test/ mein, taaki galat file upload na ho. Password chupke se poochta hai (screen par nahi dikhta,
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
VCODE="$(sed -nE 's/^version\/code=([0-9]+)$/\1/p' export_presets.cfg | head -1)"
VNAME="$(sed -nE 's/^version\/name="([^"]+)"$/\1/p' export_presets.cfg | head -1)"
PVER="$(sed -nE 's/^config\/version="([^"]+)"$/\1/p' project.godot | head -1)"
[ -n "$VCODE" ] && [ -n "$VNAME" ] || { echo "export_presets.cfg mein version/code ya version/name nahi mila"; exit 1; }
[ "$VNAME" = "$PVER" ] || { echo "version/name ($VNAME) aur project.godot config/version ($PVER) alag hain"; exit 1; }
UP="build/upload"
T="build/test"
OUT="$UP/squeezy_game_v${VNAME}_code${VCODE}.aab"
echo "Version: $VNAME (code $VCODE)"
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
mkdir -p "$T"
rm -rf "$UP"; mkdir -p "$UP"       # upload folder mein sirf ek nayi file
echo "== Export (kuch minute lagenge)..."
"$GODOT" --headless --path . --install-android-build-template --export-release "$PRESET" "$OUT" > $T/export.log 2>&1 \
  || { echo "Export fail. $T/export.log dekho."; exit 1; }
unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
[ -s "$OUT" ] || { echo "AAB nahi bana. $T/export.log dekho."; exit 1; }

echo "== bundletool validate"
$BT validate --bundle "$OUT" > /dev/null && echo "OK"
echo "== Manifest"
$BT dump manifest --bundle "$OUT" > $T/manifest.xml
grep -oE '(versionCode|versionName|package)="[^"]*"' $T/manifest.xml | sort -u
grep -q "android:versionCode=\"$VCODE\"" $T/manifest.xml && grep -q "android:versionName=\"$VNAME\"" $T/manifest.xml \
  || { echo "FAIL: manifest ka version $VNAME/$VCODE nahi"; exit 1; }
grep -q 'android:debuggable="true"' $T/manifest.xml && { echo "FAIL: debuggable build"; exit 1; } || true
bash tools/check_manifest.sh $T/manifest.xml release || { echo "Manifest check FAIL"; exit 1; }
echo "== Signature"
"$JDK/bin/jarsigner" -verify "$OUT" | grep -q "jar verified" && echo "jar verified (OK)"
"$JDK/bin/keytool" -printcert -jarfile "$OUT" | grep -E "Owner|SHA256:" | head -2

echo "== APKs + 16 KB alignment"
rm -rf "$T/apks" "$T/test.apks"
CONNECTED=()
if [ "${1:-}" = "--install" ]; then CONNECTED=(--connected-device --adb "$SDK/platform-tools/adb"); fi
$BT build-apks --bundle "$OUT" --output "$T/test.apks" "${CONNECTED[@]}" \
  --ks "$KS" --ks-key-alias "$ALIAS" --ks-pass "file:$PASSFILE" > /dev/null
mkdir -p "$T/apks" && unzip -q -o "$T/test.apks" -d "$T/apks"
fail=0
for f in "$T"/apks/splits/*.apk; do "$ZA" -c -P 16 4 "$f" || { echo "FAIL zipalign: $f"; fail=1; }; done
[ "$fail" = 0 ] && echo "zipalign -P 16: OK"

if [ "${1:-}" = "--install" ]; then
  echo "== Phone par install"
  $BT install-apks --apks "$T/test.apks" --adb "$SDK/platform-tools/adb" && echo "Install OK"
fi
echo
sha256sum "$OUT"
echo "DONE. Play Console par SIRF ye file upload karo: $OUT"
