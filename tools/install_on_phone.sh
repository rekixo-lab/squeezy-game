#!/usr/bin/env bash
# Pehle se bana signed build/upload/*.aab (sabse naya, ya $1) ko (dobara build kiye bina) jude hue phone par install karta hai.
# Password chupke se poochta hai; sirf ek private temp file (chmod 600) mein jaata hai jo turant delete hoti hai.
#   bash tools/install_on_phone.sh
set -euo pipefail
cd "$(dirname "$0")/.."

KS="${KS:-$HOME/keys/squeezy-upload.jks}"
ALIAS="${ALIAS:-upload}"
JDK="${JDK:-$HOME/.local/opt/jdk-17.0.21+9}"
BT_JAR="${BT_JAR:-$HOME/.local/opt/bundletool/bundletool.jar}"
SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
ADB="$SDK/platform-tools/adb"
AAB="${1:-$(ls -t build/upload/*.aab 2>/dev/null | head -1)}"
PKG="com.rekixo.squeezygame"
BT="$JDK/bin/java -jar $BT_JAR"

[ -s "$AAB" ] || { echo "$AAB nahi mila. Pehle: bash tools/build_release.sh"; exit 1; }
"$ADB" get-state > /dev/null 2>&1 || { echo "Phone nahi juda / authorized nahi."; exit 1; }

read -r -s -p "Keystore password: " KSPASS; echo
PASSFILE="$(mktemp)"; chmod 600 "$PASSFILE"
trap 'rm -f "$PASSFILE"; unset KSPASS' EXIT
printf '%s' "$KSPASS" > "$PASSFILE"
"$JDK/bin/keytool" -list -keystore "$KS" -storepass:file "$PASSFILE" -alias "$ALIAS" > /dev/null \
  || { echo "Password ya alias galat hai."; exit 1; }

rm -rf build/test/phone.apks build/test/phone_apks build/test/device-spec.json
mkdir -p build/test
echo "== Phone ki device spec"
$BT get-device-spec --adb "$ADB" --output build/test/device-spec.json --overwrite > /dev/null

echo "== Is phone ke liye APKs (upload key se sign)"
$BT build-apks --bundle "$AAB" --output build/test/phone.apks --device-spec build/test/device-spec.json \
  --ks "$KS" --ks-key-alias "$ALIAS" --ks-pass "file:$PASSFILE" > /dev/null
rm -f "$PASSFILE"

echo "== Install (bundletool install-apks)"
if $BT install-apks --apks build/test/phone.apks --adb "$ADB"; then
  echo "install-apks: OK"
else
  # Samsung Secure Folder jaise doosre user ki wajah se fail ho to: seedha main user (0) par
  echo "install-apks fail hua, ab user 0 par adb install-multiple se koshish..."
  mkdir -p build/test/phone_apks
  $BT extract-apks --apks build/test/phone.apks --output-dir build/test/phone_apks \
    --device-spec build/test/device-spec.json > /dev/null
  "$ADB" install-multiple -r --user 0 build/test/phone_apks/*.apk
fi
"$ADB" shell pm list packages --user 0 "$PKG" | grep -q "$PKG" && echo "Install OK" \
  || { echo "Package phone par nahi mila."; exit 1; }
