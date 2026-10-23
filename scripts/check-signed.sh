#!/usr/bin/env bash
# Refuses to publish an index that is not signed by this repository's publish
# workflow on main (design 73 section 5, D1460; agentd pins the same identity).
#
#   scripts/check-signed.sh <dir>
set -euo pipefail
dir="${1:?usage: check-signed.sh <dir>}"
identity="${LOAMS_INDEX_IDENTITY:-https://github.com/ostrium-labs/loams-marketplace/.github/workflows/publish.yml@refs/heads/main}"
issuer="https://token.actions.githubusercontent.com"
for file in index.json revocations.json; do
  if [ ! -s "$dir/$file" ]; then
    echo "::error::$dir/$file is missing" >&2
    exit 1
  fi
  if [ ! -s "$dir/$file.sigstore.json" ]; then
    echo "::error::$dir/$file is not signed (no $file.sigstore.json): refusing to publish" >&2
    exit 1
  fi
  if ! command -v cosign >/dev/null 2>&1; then
    echo "::error::cosign is not installed, so the signature cannot be checked: refusing to publish" >&2
    exit 1
  fi
  cosign verify-blob --bundle "$dir/$file.sigstore.json" \
    --certificate-identity "$identity" --certificate-oidc-issuer "$issuer" "$dir/$file"
done
echo "index.json and revocations.json are signed by $identity"
