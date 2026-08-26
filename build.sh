#!/bin/bash
set -e
cd "$(dirname "$0")"
APP=Shotty.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Shotty</string>
  <key>CFBundleIdentifier</key><string>local.shotty</string>
  <key>CFBundleName</key><string>Shotty</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
swiftc -O main.swift -o "$APP/Contents/MacOS/Shotty"
codesign --force -s - "$APP"   # stable signature so the Screen Recording grant survives rebuilds
echo "built → open $PWD/$APP"
