#!/bin/bash
# Notarize a built VaultToEnvApp for distribution.
# Prerequisites: Xcode, Apple Developer account, app signed with Developer ID.
# 1. In Xcode: Product → Archive, then Distribute App → Copy App (or export to a folder).
# 2. Create a zip: ditto -c -k --sequesterRsrc --keepParent VaultToEnvApp.app VaultToEnvApp.zip
# 3. Run: xcrun notarytool submit VaultToEnvApp.zip --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID --password YOUR_APP_SPECIFIC_PASSWORD --wait
# 4. Staple: xcrun stapler staple VaultToEnvApp.app
# This script is a helper; set APP_PATH and run submit + staple.

set -e
APP_PATH="${1:-build/VaultToEnvApp.app}"
ZIP_PATH="${APP_PATH%.app}.zip"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Usage: $0 /path/to/VaultToEnvApp.app"
  echo "Or set APP_PATH and run from repo root."
  exit 1
fi

echo "Creating zip for notarization..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Submitting to Apple (requires APPLE_ID, TEAM_ID, NOTARY_PASSWORD in env or keychain)..."
xcrun notarytool submit "$ZIP_PATH" --wait

echo "Stapling notarization ticket to app..."
xcrun stapler staple "$APP_PATH"
echo "Done. You can distribute $APP_PATH"
