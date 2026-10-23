#!/usr/bin/env bash
# The listing files a pull request adds, one per line. Published versions are
# immutable: changing or deleting one fails (yank it, or add a new version).
#
#   scripts/changed-listings.sh <base-ref>
set -euo pipefail
base="${1:?usage: changed-listings.sh <base-ref>}"
status=0
while IFS=$'\t' read -r change path rest; do
  case "$path" in
    listings/*/*/versions/*/listing.json) ;;
    *) continue ;;
  esac
  case "$change" in
    A) echo "$path" ;;
    *)
      echo "::error file=$path::published versions are immutable ($change): add a new version, or yank this one with yanked.json" >&2
      status=1
      ;;
  esac
done < <(git diff --name-status --no-renames "$base"...HEAD -- listings)
exit "$status"
