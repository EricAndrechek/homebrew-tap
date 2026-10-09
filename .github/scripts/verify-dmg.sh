#!/usr/bin/env bash
# verify-dmg.sh <dmg> <expected-team-id> <app-name>
#
# Refuse a download unless it is what a real release of ours looks like:
# the disk image and the app inside are signed with our Developer ID team,
# Apple notarized it (ticket stapled), and Gatekeeper would open both. The
# autobump pins the sha256 of exactly these bytes, so a release published by
# anyone without our signing identity never reaches the cask.
set -euo pipefail

dmg="$1" team="$2" app="$3"
fail() { echo "::error::$*"; exit 1; }

# An unsigned file makes codesign exit non-zero; that is an answer (no team),
# not a reason to stop before saying what was wrong.
team_of() { { codesign -dv "$1" 2>&1 || true; } | awk -F= '/^TeamIdentifier=/{print $2}'; }

dmg_team="$(team_of "$dmg")"
[ "$dmg_team" = "$team" ] || fail "disk image is signed by team '${dmg_team:-none}', expected '$team'"

xcrun stapler validate "$dmg" >/dev/null || fail "disk image has no valid notarization ticket"
spctl --assess --type open --context context:primary-signature -v "$dmg" 2>&1 \
  | tee /dev/stderr | grep -q "source=Notarized Developer ID" \
  || fail "Gatekeeper does not accept the disk image as notarized Developer ID"

mnt="$(mktemp -d)"
hdiutil attach -nobrowse -readonly -noverify -mountpoint "$mnt" "$dmg" >/dev/null
trap 'hdiutil detach "$mnt" -quiet || true' EXIT

[ -d "$mnt/$app" ] || fail "$app not found in the disk image"
codesign --verify --deep --strict "$mnt/$app" || fail "$app fails strict code signature verification"
app_team="$(team_of "$mnt/$app")"
[ "$app_team" = "$team" ] || fail "$app is signed by team '${app_team:-none}', expected '$team'"
spctl --assess --type execute -v "$mnt/$app" 2>&1 \
  | tee /dev/stderr | grep -q "source=Notarized Developer ID" \
  || fail "Gatekeeper does not accept $app as notarized Developer ID"

echo "verified: $(basename "$dmg") — team $team, notarized"
