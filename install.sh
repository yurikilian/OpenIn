#!/bin/bash
# Build OpenIn, install it to /Applications and enable the Finder extension.
set -euo pipefail

cd "$(dirname "$0")"

EXTENSION_ID="app.openin.OpenIn.FinderExtension"

# Team used for signing: $DEVELOPMENT_TEAM, or the first "Apple Development"
# certificate in the keychain.
TEAM_ID="${DEVELOPMENT_TEAM:-$(
    security find-certificate -c "Apple Development" -p 2>/dev/null \
        | openssl x509 -noout -subject 2>/dev/null \
        | sed -n 's/.*OU=\([A-Z0-9]*\).*/\1/p'
)}"

if [ -z "$TEAM_ID" ]; then
    echo "No Apple Development certificate found." >&2
    echo "Sign in to Xcode (Settings → Accounts) or run: DEVELOPMENT_TEAM=<team id> ./install.sh" >&2
    exit 1
fi

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
BUILT_APP="build/Build/Products/Release/OpenIn.app"

xcodebuild \
    -project OpenIn.xcodeproj \
    -scheme OpenIn \
    -configuration Release \
    -destination "platform=macOS,arch=$(uname -m)" \
    -derivedDataPath build \
    -allowProvisioningUpdates \
    -quiet \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    build

# Unregister the build copy so pluginkit only sees the one in /Applications
"$LSREGISTER" -u "$BUILT_APP" 2>/dev/null || true
pluginkit -r "$BUILT_APP/Contents/PlugIns/OpenInFinderExtension.appex" 2>/dev/null || true

rm -rf /Applications/OpenIn.app
cp -R "$BUILT_APP" /Applications/
rm -rf build

"$LSREGISTER" -f /Applications/OpenIn.app
pluginkit -a /Applications/OpenIn.app/Contents/PlugIns/OpenInFinderExtension.appex
pluginkit -e use -i "$EXTENSION_ID"

killall OpenInFinderExtension 2>/dev/null || true
killall Finder

echo "OpenIn installed. Right-click a folder in Finder → Open in."
