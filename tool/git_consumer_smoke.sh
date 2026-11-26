#!/usr/bin/env bash
# Smoke check: a consumer that depends on Foundations through git resolves the
# design system from the same commit, out of the same checkout
# (quickstart.md V6c, research R3).
#
# Usage: tool/git_consumer_smoke.sh [ref]   (default: HEAD)
#
# Only committed work is checked, because pub resolves a git ref. Runs offline
# against the local repository and the packages already in the pub cache.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
ref="${1:-HEAD}"
commit="$(git -C "$repo" rev-parse "$ref")"
short="${commit:0:6}"

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
  echo "FAIL: flutter pub get failed" >&2
  exit 1
}
echo "$output" | grep -E '^\+ (foundations|design_system) ' || true

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "$output" | grep -Eq "^\+ foundations .* from git .* at $short" ||
  fail "foundations did not resolve from git at $short"
echo "$output" |
  grep -Eq "^\+ design_system .* from git .* at $short in packages/design_system" ||
  fail "design_system did not resolve from git at $short in packages/design_system"

# Both packages must point into the same pub-cache checkout.
config="$work/.dart_tool/package_config.json"
root_of() {
  grep -A2 "\"name\": \"$1\"" "$config" | sed -n 's/.*"rootUri": "\(.*\)".*/\1/p'
}
foundations_root="$(root_of foundations)"
foundations_root="${foundations_root%/}"
design_system_root="$(root_of design_system)"
[[ "$design_system_root" == "$foundations_root/packages/design_system" ]] ||
  fail "design_system ($design_system_root) is not inside the foundations checkout ($foundations_root)"

echo "PASS: design_system resolves from git at $short in packages/design_system,"
echo "      in the same checkout as foundations ($foundations_root)."
