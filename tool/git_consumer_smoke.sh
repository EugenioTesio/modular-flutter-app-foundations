#!/usr/bin/env bash
# Smoke check: a consumer that depends on Foundations through git resolves
# exactly one design system, from its own repository at the tag Foundations
# pins (quickstart.md V6c, research R3; design system move, spec 002).
#
# Usage: tool/git_consumer_smoke.sh [ref]   (default: HEAD)
#
# Only committed work is checked, because pub resolves a git ref. Runs offline
# against the local repository and the packages already in the pub cache, so
# run `flutter pub get` in this repository first.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
ref="${1:-HEAD}"
commit="$(git -C "$repo" rev-parse "$ref")"
short="${commit:0:6}"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# The design_system source that Foundations pins at this commit.
pinned="$(git -C "$repo" show "$commit:pubspec.yaml" |
  awk '/^  design_system:/{found=1; next} found && /^  [^ ]/{exit} found')"
pinned_url="$(echo "$pinned" | sed -n 's/^ *url: *//p' | tr -d '"')"
pinned_ref="$(echo "$pinned" | sed -n 's/^ *ref: *//p' | tr -d '"')"
[[ -n "$pinned_url" && -n "$pinned_ref" ]] ||
  fail "pubspec.yaml at $short must depend on design_system through git (url and ref)"
[[ "$pinned_ref" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  fail "design_system must be pinned to a release tag vX.Y.Z, not '$pinned_ref'"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat > "$work/pubspec.yaml" <<YAML
name: git_consumer_smoke
publish_to: none

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter
  foundations:
    git:
      url: file://$repo
      ref: $commit
YAML

echo "Resolving foundations at $short from $repo"
output="$(cd "$work" && flutter pub get --offline 2>&1)" || {
  echo "$output"
  fail "flutter pub get failed (run 'flutter pub get' in $repo first to fill the pub cache)"
}
echo "$output" | grep -E '^\+ (foundations|design_system) ' || true

echo "$output" | grep -Eq "^\+ foundations .* from git .* at $short" ||
  fail "foundations did not resolve from git at $short"

# Exactly one design_system, from its own repository at the pinned tag.
lock="$(awk '/^  design_system:/{found=1; print; next} found && /^  [^ ]/{exit} found' \
  "$work/pubspec.lock")"
[[ -n "$lock" ]] || fail "design_system is missing from the consumer's pubspec.lock"
[[ "$(grep -c '^  design_system:' "$work/pubspec.lock")" == 1 ]] ||
  fail "more than one design_system entry resolved"
echo "$lock" | grep -Eq '^    source: git$' ||
  fail "design_system did not resolve from git"
echo "$lock" | grep -Fq "url: \"$pinned_url\"" ||
  fail "design_system did not resolve from $pinned_url"
echo "$lock" | grep -Fq "ref: \"$pinned_ref\"" ||
  fail "design_system did not resolve at tag $pinned_ref"
version="$(echo "$lock" | sed -n 's/^    version: "\(.*\)"/\1/p')"
[[ "v$version" == "$pinned_ref" ]] ||
  fail "design_system version $version does not match tag $pinned_ref"

# The design system must come from its own checkout, not from inside Foundations.
config="$work/.dart_tool/package_config.json"
root_of() {
  grep -A2 "\"name\": \"$1\"" "$config" | sed -n 's/.*"rootUri": "\(.*\)".*/\1/p'
}
foundations_root="$(root_of foundations)"
foundations_root="${foundations_root%/}"
design_system_root="$(root_of design_system)"
[[ "$design_system_root" != "$foundations_root"/* ]] ||
  fail "design_system ($design_system_root) still resolves inside the foundations checkout"

echo "PASS: design_system $version resolves from git $pinned_url at $pinned_ref,"
echo "      in its own checkout ($design_system_root)."
