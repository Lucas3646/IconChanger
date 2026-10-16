#!/usr/bin/env bash
set -uo pipefail
cd android
./gradlew connectedDebugAndroidTest
outcome=$?
cd ..
adb pull /sdcard/Android/data/app.iconstudio.icon_studio/files/launcher-proof build/launcher-proof || true
exit "$outcome"
