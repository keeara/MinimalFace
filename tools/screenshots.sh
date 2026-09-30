#!/bin/bash
# Takes README/preview screenshots of the watch face on a running Wear OS emulator.
#
# usage: tools/screenshots.sh OUT_DIR THEME_ID [THEME_ID ...]
# env:   DEVICE (default emulator-5554), LEFT/RIGHT complication provider
#        (default WATCH_BATTERY:RANGED_VALUE and WORLD_CLOCK:SHORT_TEXT)
#
# For each theme it temporarily sets the default theme and complications in watchface.xml,
# reinstalls the debug build (uninstall resets the remembered theme), sets the clock to
# 10:08:30 and keeps the frame where the blinking colon is visible. The XML is always restored.
# Only use on an emulator: uninstall wipes the complications chosen by the user.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:?out dir}; shift
DEVICE=${DEVICE:-emulator-5554}
LEFT=${LEFT:-WATCH_BATTERY:RANGED_VALUE}
RIGHT=${RIGHT:-WORLD_CLOCK:SHORT_TEXT}
ADB="$HOME/Android/Sdk/platform-tools/adb -s $DEVICE"
X=watchface/src/main/res/raw/watchface.xml
BAK=$(mktemp); cp "$X" "$BAK"
restore() {
    cp "$BAK" "$X"; rm -f "$BAK"
    $ADB shell settings put global auto_time 1 >/dev/null 2>&1 || true
    $ADB emu power ac on >/dev/null 2>&1 || true
    $ADB emu power capacity 100 >/dev/null 2>&1 || true
}
trap restore EXIT
mkdir -p "$OUT"

# Emulator has no step/location data: show a partially filled battery bar instead.
$ADB emu power ac off >/dev/null; $ADB emu power capacity 72 >/dev/null
$ADB shell settings put global auto_time 0

set_provider() { # slotId provider:type
    python3 - "$X" "$1" "${2%%:*}" "${2##*:}" <<'PY'
import re, sys
path, slot, prov, typ = sys.argv[1:]
s = open(path).read()
start = s.index(f'slotId="{slot}"')
m = re.compile(r'<DefaultProviderPolicy [^>]*/>').search(s, start)
new = f'<DefaultProviderPolicy defaultSystemProvider="{prov}" defaultSystemProviderType="{typ}" />'
open(path, "w").write(s[:m.start()] + new + s[m.end():])
PY
}

for T in "$@"; do
    cp "$BAK" "$X"
    sed -i "0,/ColorConfiguration id=\"themeColor\"/s/\(ColorConfiguration id=\"themeColor\"[^>]*defaultValue=\"\)[0-9]*\"/\1$T\"/" "$X"
    set_provider 1 "$LEFT"; set_provider 2 "$RIGHT"
    ./gradlew -q :watchface:assembleDebug >/dev/null
    $ADB uninstall com.example.minimalface >/dev/null 2>&1 || true
    $ADB install watchface/build/outputs/apk/debug/watchface-debug.apk >/dev/null
    $ADB shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
        --es operation set-watchface --es watchFaceId com.example.minimalface >/dev/null
    $ADB shell cmd alarm set-time "$(date -d '2026-09-30 10:08:30' +%s)000"
    $ADB shell input keyevent KEYCODE_WAKEUP
    sleep 6
    for k in 1 2 3 4; do $ADB exec-out screencap -p > "$OUT/.t$T.$k.png"; sleep 0.4; done
    python3 - "$OUT" "$T" <<'PY'
import sys, shutil
from PIL import Image
out, t = sys.argv[1:]
def colon(k):  # dark pixels where the colon sits (384 px screen)
    im = Image.open(f"{out}/.t{t}.{k}.png").convert("RGB")
    w = im.width / 384
    return sum(1 for x in range(int(186*w), int(199*w)) for y in range(int(150*w), int(230*w))
               if sum(im.getpixel((x, y))) < 150)
best = max((1, 2, 3, 4), key=colon)
shutil.copy(f"{out}/.t{t}.{best}.png", f"{out}/theme{t}.png")
print(f"theme {t}: {out}/theme{t}.png (colon px {colon(best)})")
PY
    rm -f "$OUT"/.t"$T".*.png
done

# Reinstall the real build so the emulator is left as it was.
cp "$BAK" "$X"
./gradlew -q :watchface:assembleDebug >/dev/null
$ADB uninstall com.example.minimalface >/dev/null 2>&1 || true
$ADB install watchface/build/outputs/apk/debug/watchface-debug.apk >/dev/null
$ADB shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation set-watchface --es watchFaceId com.example.minimalface >/dev/null
