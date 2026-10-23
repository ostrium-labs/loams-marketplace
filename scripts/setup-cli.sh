#!/usr/bin/env bash
# Fetches ostrium-labs/loams at the commit pinned in .github/loams-ref, only
# the paths loams-listing needs, and builds the CLI. It prints the CLI's path
# and, in GitHub Actions, exports it as LOAMS_LISTING.
#
#   scripts/setup-cli.sh [<dir>]
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ref="$(tr -d '[:space:]' < "$here/.github/loams-ref")"
if ! [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
  echo "::error::.github/loams-ref must hold a full 40-character commit id, not '$ref'" >&2
  exit 1
fi
dir="${1:-${RUNNER_TEMP:-$here/.cache}/loams}"
rm -rf "$dir"
git init -q "$dir"
git -C "$dir" remote add origin https://github.com/ostrium-labs/loams.git
git -C "$dir" fetch -q --depth 1 --filter=blob:none origin "$ref"
git -C "$dir" sparse-checkout set --no-cone \
  /package.json /pnpm-lock.yaml /pnpm-workspace.yaml /web/tsconfig.base.json \
  /agents/loams-listing/ /schemas/marketplace/
git -C "$dir" checkout -q FETCH_HEAD
(cd "$dir" && pnpm install --frozen-lockfile --filter @loams/listing --ignore-scripts >/dev/null)
(cd "$dir/agents/loams-listing" && pnpm build >/dev/null)
cli="$dir/agents/loams-listing/bin/loams-listing.mjs"
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "LOAMS_LISTING=$cli" >> "$GITHUB_ENV"
fi
echo "$cli"
