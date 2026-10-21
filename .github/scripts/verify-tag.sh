#!/usr/bin/env bash
# verify-tag.sh <github-repo> <tag> <fingerprint> <keyfile> <tarball>
#
# Refuse a source tarball unless it is what a real release of ours looks like:
# the tag is an annotated tag object signed by our key (the PRIMARY key
# fingerprint must equal <fingerprint>; a signing subkey is fine), and the
# tarball is byte-for-byte the tree that tag points at. The autobump pins the
# sha256 of exactly this tarball, so a tag or archive published by anyone
# without our key never reaches the formula.
#
# The keyring holds only <keyfile>, which lives in this tap: the key is never
# fetched from the project or the network.
#
# VERIFY_TAG_SOURCE overrides https://github.com/<repo>.git (a local path or
# URL). It exists for testing this script only.
set -euo pipefail

[ "$#" -eq 5 ] || { echo "usage: $0 <github-repo> <tag> <fingerprint> <keyfile> <tarball>" >&2; exit 2; }
repo="$1" tag="$2" fpr="$3" keyfile="$4" tarball="$5"
source_url="${VERIFY_TAG_SOURCE:-https://github.com/$repo.git}"
fail() { echo "::error::$*"; exit 1; }

case "$fpr" in
  *[!0-9A-Fa-f]* | "") fail "fingerprint '$fpr' is not hexadecimal" ;;
esac
[ "${#fpr}" -eq 40 ] || fail "fingerprint must be the full 40 hex digits"
fpr="$(printf '%s' "$fpr" | tr '[:lower:]' '[:upper:]')"
[ -f "$keyfile" ] || fail "key file $keyfile not found"
[ -f "$tarball" ] || fail "tarball $tarball not found"
tarball="$(cd "$(dirname "$tarball")" && pwd)/$(basename "$tarball")"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export GNUPGHOME="$work/gnupg"
mkdir -m 700 "$GNUPGHOME" "$work/repo" "$work/pinned" "$work/tagged"

# The keyring: only our key, and it must be the one we think it is.
gpg --batch --quiet --import "$keyfile" 2>/dev/null || fail "cannot import $keyfile"
imported="$(gpg --batch --with-colons --list-keys | awk -F: '$1=="fpr"{print $10; exit}')"
[ "$imported" = "$fpr" ] || fail "$keyfile holds key '${imported:-none}', expected $fpr"
[ "$(gpg --batch --with-colons --list-keys | grep -c '^pub:')" -eq 1 ] || fail "$keyfile holds more than one key"

cd "$work/repo"
git init -q .
git fetch -q --no-tags --depth=1 "$source_url" "refs/tags/$tag:refs/tags/$tag" \
  || fail "cannot fetch tag $tag from $source_url"

# A lightweight tag is just a ref to a commit anyone with push access could
# move; only an annotated tag object carries a signature.
[ "$(git cat-file -t "refs/tags/$tag")" = "tag" ] || fail "$tag is not an annotated tag"

status="$(git verify-tag --raw "refs/tags/$tag" 2>&1 >/dev/null || true)"
echo "$status" | grep -E '^\[GNUPG:\] (GOODSIG|BADSIG|EXPSIG|EXPKEYSIG|REVKEYSIG|ERRSIG|NO_PUBKEY|VALIDSIG)' || true
if echo "$status" | grep -qE '^\[GNUPG:\] (BADSIG|EXPSIG|EXPKEYSIG|REVKEYSIG|ERRSIG|NO_PUBKEY) '; then
  fail "$tag has a bad, expired, revoked or unverifiable signature"
fi
echo "$status" | grep -q '^\[GNUPG:\] GOODSIG ' || fail "$tag is not signed (no good signature)"
# VALIDSIG <signing-fpr> <date> <ts> <expire> <ver> <rsv> <pk-algo> <hash-algo> <class> <primary-fpr>
primary="$(echo "$status" | awk '$1=="[GNUPG:]" && $2=="VALIDSIG" {print $NF; exit}')"
[ "$primary" = "$fpr" ] || fail "$tag is signed by key '${primary:-none}', expected $fpr"

# The pinned bytes must be that tag's tree. GitHub's archive has a single
# top-level directory, <repo-name>-<version>; strip it and compare the trees.
tar -xzf "$tarball" -C "$work/pinned"
set -- "$work"/pinned/*
[ "$#" -eq 1 ] && [ -d "$1" ] || fail "tarball does not have exactly one top-level directory"
git archive --format=tar "refs/tags/$tag" | tar -xf - -C "$work/tagged"
if ! diff -r "$1" "$work/tagged" >"$work/diff.txt" 2>&1; then
  head -20 "$work/diff.txt" >&2
  fail "tarball differs from the tree of tag $tag"
fi

echo "verified: $tag of $repo — signed by $fpr; $(basename "$tarball") matches the tag's tree"
